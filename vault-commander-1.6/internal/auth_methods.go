package internal

import (
	"encoding/json"
	"fmt"

	"github.com/gdamore/tcell/v2"
	"github.com/hashicorp/vault/api"
	"github.com/rivo/tview"
	"github.com/ryboe/q"
)

type authMethods struct {
	*tview.Table

	authMap map[string]*api.MountOutput
}

func newAuthMethods(a *App) *mountOutput {
	am := newMountOutput(a, "auth methods")
	populateAuth(am, a)
	setAuthKeyBinding(am, a)

	return am
}

func setAuthKeyBinding(mo *mountOutput, a *App) {
	mo.setKeyBinding(a, populateAuth, "auth")
}

func populateAuth(mo *mountOutput, a *App) {
	authMethods, err := a.Client.Sys().ListAuth()
	if err != nil {
		a.setStatus(err.Error())
		return
	}
	mo.outputMap = authMethods
	mo.populate(a)
}

func (am *authMethods) setKeyBinding(a *App) {
	am.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		// a.setGlobalKeybinding(event)
		switch event.Key() {
		case tcell.KeyEnter:
			am.showConfig(a)
		case tcell.KeyCtrlR:
			am.populate(a)
		}

		switch event.Rune() {
		case 'c':
			am.showConfig(a)
		}

		return event
	})
}

func (am *authMethods) showConfig(a *App) {
	row, _ := am.GetSelection()
	a.setStatus(fmt.Sprintf("row is %d", row))
	path := am.GetCell(row, 0)
	q.Q(path, am.authMap[path.Text]) // DEBUG
	authJSON, err := json.MarshalIndent(am.authMap[path.Text], "", "  ")
	if err != nil {
		a.setStatus(fmt.Sprintf("failed to parse %s config: %s", path.Text, err))
		return
	}
	a.displayText(
		path.Text+" config",
		fmt.Sprintf("%+v", string(authJSON)),
		"auth",
	)
}

func (am *authMethods) populate(a *App) {
	authMethods, err := a.Client.Sys().ListAuth()
	if err != nil {
		a.setStatus(err.Error())
		return
	}
	a.Client.Sys().ListMounts()
	am.authMap = authMethods
	am.Clear()

	headers := []string{
		"Path",
		"Type",
		"Accessor",
		"Description",
	}

	for i, header := range headers {
		am.SetCell(0, i, &tview.TableCell{
			Text:            header,
			NotSelectable:   true,
			Align:           tview.AlignLeft,
			Color:           tcell.ColorWhite,
			BackgroundColor: tcell.ColorDefault,
			Attributes:      tcell.AttrBold,
		})
	}

	i := 1
	for path, auth := range authMethods {
		q.Q(path, auth) // DEBUG
		am.SetCell(i, 0, tview.NewTableCell(path).
			SetTextColor(tcell.ColorLightGreen).
			SetMaxWidth(1).
			SetExpansion(1))

		am.SetCell(i, 1, tview.NewTableCell(auth.Type).
			SetTextColor(tcell.ColorLightGreen).
			SetMaxWidth(1).
			SetExpansion(1))

		am.SetCell(i, 2, tview.NewTableCell(auth.Accessor).
			SetTextColor(tcell.ColorLightGreen).
			SetMaxWidth(1).
			SetExpansion(1))

		am.SetCell(i, 3, tview.NewTableCell(auth.Description).
			SetTextColor(tcell.ColorLightGreen).
			SetMaxWidth(1).
			SetExpansion(1))

		i = i + 1
	}
}
