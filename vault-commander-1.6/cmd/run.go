package cmd

import (
	"fmt"

	"github.com/tvoran/vault-commander/internal"
)

// Run starts the app
func Run() {

	app := internal.NewApp()
	if err := app.Init(); err != nil {
		panic(fmt.Sprintf("app init failed: %v", err))
	}
	if err := app.StartRunning(); err != nil {
		panic(fmt.Sprintf("app run failed %v", err))
	}
}
