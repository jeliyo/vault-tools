package internal

import (
	"context"
	"fmt"
	"log"
	"os"
	"sort"
	"strings"
	"time"

	"github.com/76creates/stickers"
	"github.com/charmbracelet/bubbles/progress"
	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	vault "github.com/hashicorp/vault-client-go"
	"github.com/hashicorp/vault/api"
	"github.com/ryboe/q"
	"golang.org/x/term"
)

// e.g. for making styles for each thing, one for vault status, header info, and main thingy
var logoStyle = lipgloss.NewStyle().
	Align(lipgloss.Top, lipgloss.Left).
	BorderStyle(lipgloss.HiddenBorder())

var headerStyle = lipgloss.NewStyle().BorderStyle(lipgloss.NormalBorder()).Height(10).Width(140)

var helpStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("#626262")).Render

// sessionState is used to track which main view is in focus
type sessionState uint

const (
	defaultTime                    = time.Minute
	secretEnginesView sessionState = iota
	databaseEnginesView
	authMethodsView
	pluginsView
)

type Model struct {
	// config Config
	client    *vault.Client
	apiClient *api.Client
	ctx       context.Context
	cancel    context.CancelFunc

	height int
	width  int

	vaultStatus    statusMsg
	mainTable      *stickers.TableSingleType[string]
	infoBox        *stickers.FlexBox
	splashProgress progress.Model

	authMethodList map[string]interface{}
	secretsList    map[string]interface{}
	pluginsList    map[string]interface{}

	currentView sessionState

	// whether to display the splash screen
	splash    bool
	splashSec int

	err error
}

type statusMsg struct {
	Version     string
	Sealed      bool
	ClusterName string
	HAEnabled   bool
}

type secretEnginesMsg struct {
	Data map[string]interface{}
}
type authMethodsMsg struct {
	Data map[string]interface{}
}
type databaseMsg struct {
	Data map[string]interface{}
}
type pluginsMsg struct {
	Data map[string]interface{}
}

type errMsg struct{ err error }

type splashTickMsg struct{}

func splashTick() tea.Cmd {
	return tea.Tick(time.Second, func(time.Time) tea.Msg {
		return splashTickMsg{}
	})
}

type mainTickMsg struct{}

// This is basically the update frequency for the main display
func mainTick() tea.Cmd {
	q.Q("mainTick") // DEBUG
	return tea.Tick(2*time.Second, func(time.Time) tea.Msg {
		return mainTickMsg{}
	})
}

// For messages that contain errors it's often handy to also implement the
// error interface on the message.
func (e errMsg) Error() string { return e.err.Error() }

func NewModel() Model {
	w, h, err := term.GetSize(int(os.Stdout.Fd()))
	if err != nil {
		w = 80
		h = 24
	}
	config := vault.DefaultConfiguration()
	if err := config.LoadEnvironment(); err != nil {
		log.Fatal(err)
	}
	client, err := vault.NewClient(config)
	if err != nil {
		log.Fatal(err)
	}
	apiClient, err := api.NewClient(api.DefaultConfig())
	if err != nil {
		log.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	return Model{
		client:         client,
		apiClient:      apiClient,
		splash:         true,
		splashSec:      4,
		ctx:            ctx,
		cancel:         cancel,
		width:          w,
		height:         h,
		mainTable:      stickers.NewTableSingleType[string](0, 0, []string{}),
		splashProgress: progress.NewModel(progress.WithDefaultGradient()),
	}
}

func (m Model) getVaultStatus(ctx context.Context) func() tea.Msg {
	return func() tea.Msg {
		// sysSealStatus, err := m.client.System.GetSysSealStatus(ctx)
		// q.Q(sysSealStatus, err) // DEBUG
		// if err != nil {
		// 	return errMsg{err}
		// }

		// sysRead, err := m.client.Read(ctx, "sys/seal-status")
		// q.Q(sysRead, err) // DEBUG
		// if err != nil {
		// 	return errMsg{err}
		// }

		// sysLeader, err := m.client.System.GetSysLeader(ctx)
		// q.Q(sysLeader, err) // DEBUG
		// if err != nil {
		// 	return errMsg{err}
		// }

		// sysHealth, err := m.client.System.GetSysHealth(ctx)
		// q.Q(sysHealth, err) // debug
		// if err != nil {
		// 	return errMsg{err}
		// }

		// sysHAStatus, err := m.client.System.GetSysHaStatus(ctx)
		// q.Q(sysHAStatus, err) // DEBUG
		// if err != nil {
		// 	return errMsg{err}
		// }

		// pluginsCatalog, err := m.client.System.GetSysPluginsCatalog(ctx)
		// q.Q(pluginsCatalog, err) // debug
		// if err != nil {
		// 	return errMsg{err}
		// }

		// msg := fmt.Sprintf("%v", sysHAStatus.Data)

		status, err := m.apiClient.Sys().SealStatus()
		if err != nil {
			return errMsg{fmt.Errorf("failed to get seal status: %w", err)}
		}
		leader, err := m.apiClient.Sys().Leader()
		if err != nil {
			return errMsg{fmt.Errorf("failed to get leader info: %w", err)}
		}

		return statusMsg{
			Version:     status.Version,
			Sealed:      status.Sealed,
			ClusterName: status.ClusterName,
			HAEnabled:   leader.HAEnabled,
		}
	}
}

func (m Model) getAuthMethodsList() tea.Msg {
	// m.client.WithNamespace("admin")
	auth, err := m.client.System.GetSysAuth(m.ctx)
	if err != nil {
		return errMsg{err}
	}
	return authMethodsMsg{auth.Data}
}

func (m Model) getSecretEngineList() tea.Msg {
	// m.client.WithNamespace("admin")
	secrets, err := m.client.System.GetSysMounts(m.ctx)
	if err != nil {
		return errMsg{err}
	}
	return secretEnginesMsg{secrets.Data}
}

// Could probably just have one list function that switches on the current view
// or whatever, since they all will return map[string]interface{} or something
// similar
func (m Model) getDatabaseList() tea.Msg {
	// m.client.WithNamespace("admin")
	return databaseMsg{nil}
}

func (m Model) getPluginCatalog() tea.Msg {
	plugins, err := m.client.System.GetSysPluginsCatalog(m.ctx)
	if err != nil {
		return errMsg{err}
	}
	return pluginsMsg{plugins.Data}
}

func (m Model) Init() tea.Cmd {
	return splashTick()
	// return m.getVaultStatus(context.Background())
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	var cmd tea.Cmd
	var cmds []tea.Cmd

	switch msg := msg.(type) {
	case tea.WindowSizeMsg:
		m.width, m.height = msg.Width, msg.Height
	case splashTickMsg:
		if m.splashSec == 0 {
			m.splash = false
			m.currentView = authMethodsView
			return m, mainTick()
		}
		m.splashSec--
		cmd := m.splashProgress.IncrPercent(0.25)
		return m, tea.Batch(cmd, splashTick())
	// FrameMsg is sent when the progress bar wants to animate itself
	case progress.FrameMsg:
		progressModel, cmd := m.splashProgress.Update(msg)
		m.splashProgress = progressModel.(progress.Model)
		return m, cmd
	case mainTickMsg:
		// kick off update for vault status
		cmd = m.getVaultStatus(context.Background())
		cmds = append(cmds, cmd)

		// main window updates
		// TODO(tvoran): add more views for individual info for each component
		var viewCmd tea.Cmd
		switch m.currentView {
		case secretEnginesView:
			viewCmd = m.getSecretEngineList
		case authMethodsView:
			viewCmd = m.getAuthMethodsList
		case databaseEnginesView:
			viewCmd = m.getDatabaseList
		case pluginsView:
			viewCmd = m.getPluginCatalog
		}
		cmds = append(cmds, viewCmd, mainTick())
	case statusMsg:
		m.vaultStatus = msg
	case secretEnginesMsg:
		m.secretsList = msg.Data
	case authMethodsMsg:
		m.authMethodList = msg.Data
	case pluginsMsg:
		m.pluginsList = msg.Data
	// case databaseMsg:
	// 	m.databaseList = msg.Data
	case errMsg:
		// There was an error. Note it in the model. And tell the runtime
		// we're done and want to quit.
		m.err = msg
		m.cancel()
		return m, tea.Quit

	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			m.cancel()
			return m, tea.Quit
		case "s":
			m.currentView = secretEnginesView
			cmds = append(cmds, mainTick())
		case "a":
			m.currentView = authMethodsView
			cmds = append(cmds, mainTick())
		case "p":
			m.currentView = pluginsView
			cmds = append(cmds, mainTick())
		case "j":
			m.mainTable.CursorDown()
			cmds = append(cmds, mainTick())
		case "k":
			m.mainTable.CursorUp()
			cmds = append(cmds, mainTick())
		case "left":
			m.mainTable.CursorLeft()
			cmds = append(cmds, mainTick())
		case "right":
			m.mainTable.CursorRight()
			cmds = append(cmds, mainTick())
			// case "ctrl+s":
			// 	x, _ := m.table.GetCursorLocation()
			// 	m.table.OrderByColumn(x)
			// case "enter", " ":
			// 	selectedValue = m.table.GetCursorValue()
			// 	m.infoBox.Row(0).Cell(1).SetContent("\nselected cell: " + selectedValue)
		}

	}

	// cmds = append(cmds, mainTick())
	return m, tea.Batch(cmds...)
}

func (m Model) View() string {
	// If there's an error, print it out and don't do anything else.
	if m.err != nil {
		return fmt.Sprintf("\nWe had some trouble: %v\n\n", m.err)
	}

	if m.splash {
		// show splash screen for a few seconds, or if the user presses a key
		m.splash = false
		return m.renderSplash()
	}

	// Tell the user we're doing something.
	// s := "Checking vault status...\n\n"

	// header := headerStyle.Render(m.renderHeader())
	header := m.renderHeader()
	// if m.vaultStatus != "" {
	// 	s += fmt.Sprintf("status: %s\n\n", m.vaultStatus)
	// }
	var mainPage string
	switch m.currentView {
	case authMethodsView:
		mainPage = "Auth Methods\n" + m.renderAuthList()
	case secretEnginesView:
		mainPage = "Secrets Engines\n" + m.renderSecretsList()
	case pluginsView:
		mainPage = "Plugin Catalog\n" + m.renderPluginList()
	}

	return lipgloss.JoinVertical(lipgloss.Left, header, mainPage)
	// Send off whatever we came up with above for rendering.
	// return "\n" + s + "\n\n"
}

func (m Model) renderSplash() string {
	var s string
	// splashStr := logoStyle.Render(fmt.Sprintf("%d", m.splashSec))
	s += lipgloss.JoinVertical(lipgloss.Center, logoStyle.Render(strings.Join(LogoBlock, "\n")), m.splashProgress.View())
	return s
}

func (m Model) renderHeader() string {
	// TODO(tvoran): make these markdown views and style that way?
	statusText := fmt.Sprintf(`Version:     %s
Sealed:      %v
ClusterName: %s
HA Enabled:  %v`,
		m.vaultStatus.Version,
		m.vaultStatus.Sealed,
		m.vaultStatus.ClusterName,
		m.vaultStatus.HAEnabled)
	helpText := helpStyle(`<ctrl+c> or <q> to exit
<a> auth methods
<s> secret engines
<p> plugin catalog
`)
	logo := strings.Join(LogoShort, "\n")

	m.infoBox = stickers.NewFlexBox(0, 0).SetHeight(7)
	m.infoBox.SetWidth(m.width)
	r1 := m.infoBox.NewRow()
	r1.AddCells([]*stickers.FlexBoxCell{
		stickers.NewFlexBoxCell(1, 1).
			SetID("status").
			SetContent(statusText).
			SetStyle(lipgloss.NewStyle().Bold(true)),
		stickers.NewFlexBoxCell(1, 1).
			SetID("help").
			SetContent(helpText),
		stickers.NewFlexBoxCell(1, 1).
			SetID("logo").
			SetContent(logo).
			SetStyle(lipgloss.NewStyle().Blink(true)),
	})
	m.infoBox.AddRows([]*stickers.FlexBoxRow{r1})

	// header := lipgloss.JoinHorizontal(lipgloss.Top, left, middle, right)

	return m.infoBox.Render()
}

func (m Model) renderAuthList() string {
	m.mainTable = stickers.NewTableSingleType[string](0, 0, []string{"Path", "Type", "Version", "Description"})
	ratio := []int{10, 10, 20, 20}
	minSize := []int{10, 10, 20, 20}
	m.mainTable.SetRatio(ratio).SetMinWidth(minSize)
	// columns := []table.Column{
	// 	{Title: "Path", Width: 20},
	// 	{Title: "Type", Width: 20},
	// 	{Title: "Version", Width: 20},
	// 	{Title: "Description", Width: 20},
	// }

	rawRows := [][]string{}
	for k, v := range m.authMethodList {
		details := v.(map[string]interface{})
		rawRows = append(rawRows, []string{k, details["type"].(string), details["running_plugin_version"].(string), details["description"].(string)})
	}
	sort.Slice(rawRows, func(i, j int) bool {
		return rawRows[i][0] < rawRows[j][0]
	})
	m.mainTable.AddRows(rawRows)
	m.mainTable.SetWidth(m.width)
	m.mainTable.SetHeight(m.height - 8)
	m.mainTable.CursorUp()
	// rows := []table.Row{}
	// for _, row := range rawRows {
	// 	rows = append(rows, table.SimpleRow{row[0], row[1], row[2], row[3]})
	// }
	// m.mainTable.SetRows(rows)

	// m.mainTable = table.New(table.WithColumns(columns),
	// 	table.WithRows(rows),
	// 	table.WithFocused(true),
	// )
	return m.mainTable.Render()
}

func (m Model) renderSecretsList() string {
	m.mainTable = stickers.NewTableSingleType[string](0, 0, []string{"Path", "Type", "Version", "Description"})
	ratio := []int{10, 10, 20, 20}
	minSize := []int{10, 10, 20, 20}
	m.mainTable.SetRatio(ratio).SetMinWidth(minSize)

	rawRows := [][]string{}
	for k, v := range m.secretsList {
		details := v.(map[string]interface{})
		rawRows = append(rawRows, []string{k, details["type"].(string), details["running_plugin_version"].(string), details["description"].(string)})
	}
	sort.Slice(rawRows, func(i, j int) bool {
		return rawRows[i][0] < rawRows[j][0]
	})
	m.mainTable.AddRows(rawRows)
	m.mainTable.SetWidth(m.width)
	m.mainTable.SetHeight(m.height - 8)

	return m.mainTable.Render()
}

func (m Model) renderPluginList() string {
	m.mainTable = stickers.NewTableSingleType[string](0, 0, []string{"Name", "Type", "Version", "Status"})
	ratio := []int{20, 10, 20, 15}
	minSize := []int{20, 10, 20, 15}
	m.mainTable.SetRatio(ratio).SetMinWidth(minSize)

	rows := [][]string{}
	if m.pluginsList == nil {
		return ""
	}
	detailed := m.pluginsList["detailed"].([]interface{})
	for _, pluginRaw := range detailed {
		plugin := pluginRaw.(map[string]interface{})
		rows = append(rows, []string{plugin["name"].(string), plugin["type"].(string), plugin["version"].(string), plugin["deprecation_status"].(string)})
	}
	m.mainTable.AddRows(rows)
	m.mainTable.SetWidth(m.width)
	m.mainTable.SetHeight(m.height - 8)

	return m.mainTable.Render()
}
