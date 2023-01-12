package internal

import (
	"fmt"
	"time"

	"github.com/gdamore/tcell/v2"
	"github.com/hashicorp/vault/api"
	"github.com/rivo/tview"
	"github.com/ryboe/q"
)

// App defines a tview application
type App struct {
	*tview.Application

	// Window is the flex container for the whole window, containing the header
	// and main areas
	Window *tview.Flex

	// Header is the flex container for the header
	Header *tview.Flex

	// Main is the pages view for the rest of the window
	Main *tview.Pages

	// StatusBar is the last line of the window
	StatusBar *tview.TextView

	// Splash is the splash screen
	Splash *tview.Flex

	// VaultWidget is the top right vault status display
	VaultWidget *VaultInfo

	// Client for vault
	Client *api.Client
}

// NewApp returns a new app
func NewApp() *App {
	a := App{
		Application: tview.NewApplication(),
		Window:      tview.NewFlex(),
		Header:      tview.NewFlex(),
		Main:        tview.NewPages(),
		StatusBar:   tview.NewTextView(),
	}
	return &a
}

// StartRunning displays the splash screen then redraws the window with the app
// components
func (a *App) StartRunning() error {

	splash := newSplash()
	a.Window.AddItem(splash, 0, 1, true)

	go func() {
		<-time.After(5 * time.Second)
		a.QueueUpdateDraw(func() {
			a.Window.Clear()
			a.Window.AddItem(a.Header, 0, 1, false)
			a.Window.AddItem(a.Main, 0, 6, true)
			a.Window.AddItem(a.StatusBar, 1, 0, false)
		})
	}()

	return a.Run()
}

// Init initializes the application
func (a *App) Init() error {
	if a.Window == nil {
		return fmt.Errorf("a.Window cannot be nil")
	}
	a.SetRoot(a.Window, true).EnableMouse(true)

	// setup Vault client
	client, err := api.NewClient(api.DefaultConfig())
	if err != nil {
		return fmt.Errorf("failed to setup vault client: %w", err)
	}
	a.Client = client

	if err := a.buildHeader(); err != nil {
		return err
	}

	a.buildMain()

	a.Window.SetDirection(tview.FlexRow)

	return nil
}

// buildMain sets up the pages for the main part of the window
func (a *App) buildMain() {
	a.Main.SetBorder(true)

	statusPage := newVaultStatus(a)
	a.Main.AddPage("status", statusPage, true, false)

	authPage := newAuthMethods(a)
	a.Main.AddPage("auth", authPage, true, false)

	secretPage := newSecretEngines(a)
	a.Main.AddPage("secret engines", secretPage, true, false)

	a.Main.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		switch event.Rune() {
		case 'a':
			a.Main.SwitchToPage("auth")
			a.Main.SetTitle(" auth methods ")
			a.SetFocus(a.Main)
		case 's':
			q.Q("got s") // DEBUG
			a.Main.SwitchToPage("secret engines")
			a.Main.SetTitle(" secret engines ")
		case 'S':
			q.Q("got S") // DEBUG
			a.Main.SwitchToPage("status")
			a.Main.SetTitle(" vault status ")
		}
		return event
	})

	a.Main.SwitchToPage("status")
	a.Main.SetTitle(" vault status ")
	a.SetFocus(a.Main)
}

func (a *App) buildHeader() error {
	a.Header.SetDirection(tview.FlexColumn)

	a.VaultWidget = NewVaultInfo(a)
	if err := a.VaultWidget.Init(); err != nil {
		return fmt.Errorf("failed to init vault info widget: %w", err)
	}

	a.Header.AddItem(a.VaultWidget, 40, 1, false)
	a.Header.AddItem(menu(), 0, 1, false)
	a.Header.AddItem(logo(), 40, 1, false)

	return nil
}

func (a *App) displayText(title, body, returnPage string) {
	t := tview.NewTextView()
	t.SetTitle(title)
	t.SetBorder(true)
	t.SetText(body)

	t.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		if event.Key() == tcell.KeyEsc || event.Rune() == 'q' {
			q.Q("in display text: ", returnPage) // DEBUG
			a.Main.ShowPage(returnPage)
			a.Main.RemovePage("detail")
		}
		return event
	})

	a.Main.AddAndSwitchToPage("detail", t, true)
}

// menu draws the key binding menu in the middle of the header
func menu() *tview.Table {
	m := tview.NewTable()
	m.SetBorderPadding(0, 0, 5, 0)
	m.SetCellSimple(0, 0, "[purple]<ctrl-c>")
	m.SetCellSimple(0, 1, "[gray]Exit  ")
	m.SetCellSimple(1, 0, "[purple]<crtl-r>")
	m.SetCellSimple(1, 1, "[gray]Refresh")

	m.SetCellSimple(0, 2, "  [cadetblue::b]<S>")
	m.SetCellSimple(0, 3, "[gray]vault [gray]status")
	m.SetCellSimple(1, 2, "  [cadetblue::b]<a>")
	m.SetCellSimple(1, 3, "[gray]auth [gray]methods")
	m.SetCellSimple(2, 2, "  [cadetblue::b]<s>")
	m.SetCellSimple(2, 3, "[gray]secret [gray]engines")
	// database, etc.

	return m
}

// logo draws the vault logo on the right side of the header
func logo() *tview.TextView {
	c := "yellow"
	l := tview.NewTextView()
	l.SetDynamicColors(true)
	for i, s := range LogoShort {
		fmt.Fprintf(l, "[%s::b]%s", c, s)
		if i+1 < len(LogoShort) {
			fmt.Fprintf(l, "\n")
		}
	}
	return l
}
