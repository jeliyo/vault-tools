package internal

import (
	"encoding/json"
	"fmt"

	"github.com/gdamore/tcell/v2"
	"github.com/hashicorp/vault/api"
	"github.com/rivo/tview"
	"github.com/ryboe/q"
)

// mountOutput is used for auth and secrets mounts
type mountOutput struct {
	*tview.Table

	outputMap map[string]*api.MountOutput
}

type popFunc func(*mountOutput, *App)

func newMountOutput(a *App, title string) *mountOutput {
	mo := &mountOutput{
		Table: tview.NewTable().SetSelectable(true, false).Select(0, 0).SetFixed(1, 1),
	}
	mo.SetTitle(title).SetTitleAlign(tview.AlignCenter)

	return mo
}

func (mo *mountOutput) setKeyBinding(a *App, populate popFunc, returnPage string) {
	mo.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		// a.setGlobalKeybinding(event)
		switch event.Key() {
		case tcell.KeyEnter:
			q.Q(returnPage) // DEBUG
			mo.showConfig(a, returnPage)
		case tcell.KeyCtrlR:
			populate(mo, a)
		}

		switch event.Rune() {
		case 'c':
			mo.showConfig(a, returnPage)
		}

		return event
	})
}

func (mo *mountOutput) showConfig(a *App, returnPage string) {
	row, _ := mo.GetSelection()
	a.setStatus(fmt.Sprintf("row is %d", row))
	path := mo.GetCell(row, 0)
	q.Q(path, mo.outputMap[path.Text]) // DEBUG
	authJSON, err := json.MarshalIndent(mo.outputMap[path.Text], "", "  ")
	if err != nil {
		a.setStatus(fmt.Sprintf("failed to parse %s config: %s", path.Text, err))
		return
	}
	// returnPage, _ := a.Main.GetFrontPage()
	a.displayText(
		path.Text+" config",
		fmt.Sprintf("%+v", string(authJSON)),
		returnPage,
	)
}

func (mo *mountOutput) populate(a *App) {
	mo.Clear()

	headers := []string{
		"Path",
		"Type",
		"Accessor",
		"Description",
	}

	for i, header := range headers {
		mo.SetCell(0, i, &tview.TableCell{
			Text:            header,
			NotSelectable:   true,
			Align:           tview.AlignLeft,
			Color:           tcell.ColorWhite,
			BackgroundColor: tcell.ColorDefault,
			Attributes:      tcell.AttrBold,
		})
	}

	i := 1
	for path, auth := range mo.outputMap {
		q.Q(path, auth) // DEBUG
		mo.SetCell(i, 0, tview.NewTableCell(path).
			SetTextColor(tcell.ColorLightGreen).
			SetMaxWidth(1).
			SetExpansion(1))

		mo.SetCell(i, 1, tview.NewTableCell(auth.Type).
			SetTextColor(tcell.ColorLightGreen).
			SetMaxWidth(1).
			SetExpansion(1))

		mo.SetCell(i, 2, tview.NewTableCell(auth.Accessor).
			SetTextColor(tcell.ColorLightGreen).
			SetMaxWidth(1).
			SetExpansion(1))

		mo.SetCell(i, 3, tview.NewTableCell(auth.Description).
			SetTextColor(tcell.ColorLightGreen).
			SetMaxWidth(1).
			SetExpansion(1))

		i = i + 1
	}
}
