package internal

import (
	"fmt"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
)

type vaultStatus struct {
	*tview.Table
}

func newVaultStatus(a *App) *vaultStatus {
	vaultStatus := &vaultStatus{
		Table: tview.NewTable(),
	}

	vaultStatus.SetTitle("vault status").SetTitleAlign(tview.AlignCenter)
	vaultStatus.populate(a)
	vaultStatus.setKeyBinding(a)

	return vaultStatus
}

func (vs *vaultStatus) setKeyBinding(a *App) {
	vs.SetInputCapture(func(event *tcell.EventKey) *tcell.EventKey {
		// a.setGlobalKeybinding(event)
		switch event.Key() {
		case tcell.KeyCtrlR:
			vs.populate(a)
		}

		return event
	})
}

func (vs *vaultStatus) populate(a *App) {

	status, err := a.Client.Sys().SealStatus()
	if err != nil {
		fmt.Println(fmt.Errorf("failed to get seal status: %w", err))
	}
	leader, err := a.Client.Sys().Leader()
	if err != nil {
		fmt.Println(fmt.Errorf("failed to get leader info: %w", err))
	}

	vs.Clear()

	order := []string{"Seal Type", "Initialized", "Sealed", "Total Shares", "Threshold", "Version", "Storage Type", "Cluster Name", "Cluster ID", "HA Enabled", "HA Cluster", "HA Mode"}
	output := map[string]string{
		order[0]:  status.Type,
		order[1]:  fmt.Sprintf("%v", status.Initialized),
		order[2]:  fmt.Sprintf("%v", status.Sealed),
		order[3]:  fmt.Sprintf("%d", status.N),
		order[4]:  fmt.Sprintf("%d", status.T),
		order[5]:  status.Version,
		order[6]:  status.StorageType,
		order[7]:  status.ClusterName,
		order[8]:  status.ClusterID,
		order[9]:  fmt.Sprintf("%v", leader.HAEnabled),
		order[10]: leader.LeaderClusterAddress,
	}
	mode := "standby"
	if leader.IsSelf {
		mode = "active"
	}
	output[order[11]] = mode

	for i, v := range order {
		vs.SetCell(i, 0, tview.NewTableCell(v))
		vs.SetCell(i, 1, tview.NewTableCell(output[v]))
	}
}
