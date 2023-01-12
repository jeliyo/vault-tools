package internal

import "fmt"

func (a *App) setStatus(text string) {
	a.StatusBar.Clear()
	fmt.Fprint(a.StatusBar, text)
}

// TODO(tvoran): have set status error, warn, debug, etc.
