package internal

import (
	"fmt"

	"github.com/rivo/tview"
)

// VaultInfo represents a vault info view
type VaultInfo struct {
	*tview.Table

	app *App
}

// NewVaultInfo returns a new vault info widget
func NewVaultInfo(app *App) *VaultInfo {
	return &VaultInfo{
		Table: tview.NewTable(),
		app:   app,
	}
}

func (v *VaultInfo) Init() error {
	v.SetBorders(false)
	v.SetBorderPadding(0, 0, 1, 0)

	if err := v.populate(); err != nil {
		return err
	}

	return nil
}

func (v *VaultInfo) populate() error {
	status, err := v.app.Client.Sys().SealStatus()
	if err != nil {
		return fmt.Errorf("failed to get seal status: %w", err)
	}
	leader, err := v.app.Client.Sys().Leader()
	if err != nil {
		return fmt.Errorf("failed to get leader info: %w", err)
	}

	v.SetCell(0, 0, tview.NewTableCell("[orange]Version:"))
	v.SetCellSimple(0, 1, fmt.Sprintf("[white::b]%s", status.Version))

	v.SetCell(1, 0, tview.NewTableCell("[orange]Sealed:"))
	v.SetCellSimple(1, 1, fmt.Sprintf("[white::b]%v", status.Sealed))

	v.SetCellSimple(2, 0, "[orange]Cluster [orange]Name:")
	v.SetCellSimple(2, 1, fmt.Sprintf("[white::b]%s", status.ClusterName))

	v.SetCellSimple(3, 0, "[orange]HA [orange]Enabled:")
	v.SetCellSimple(3, 1, fmt.Sprintf("[white::b]%v", leader.HAEnabled))

	return nil
}
