package internal

import (
	"fmt"
	"strings"

	"github.com/gdamore/tcell/v2"
	"github.com/rivo/tview"
)

// copied liberally from k9s internal/ui/splash.go

// Splash represents a splash screen.
type Splash struct {
	*tview.Flex
}

// newSplash instantiates a new splash screen with product and company info.
func newSplash() *Splash {
	s := Splash{Flex: tview.NewFlex()}
	s.SetBackgroundColor(tcell.ColorDarkGray)

	logo := tview.NewTextView()
	logo.SetDynamicColors(true)
	logo.SetTextAlign(tview.AlignCenter)
	s.layoutLogo(logo)

	vers := tview.NewTextView()
	vers.SetDynamicColors(true)
	vers.SetTextAlign(tview.AlignCenter)
	s.layoutRev(vers, "0.0.0-dev")

	s.SetDirection(tview.FlexRow)
	s.AddItem(nil, 0, 1, false)
	s.AddItem(logo, 10, 1, false)
	s.AddItem(vers, 1, 1, false)
	s.AddItem(nil, 0, 1, false)

	return &s
}

func (s *Splash) layoutLogo(t *tview.TextView) {
	logo := strings.Join(LogoBlock, fmt.Sprintf("\n[%s::b]", "white"))
	fmt.Fprintf(t, "%s[%s::b]%s\n",
		strings.Repeat("\n", 2),
		"blue",
		logo)
}

func (s *Splash) layoutRev(t *tview.TextView, rev string) {
	fmt.Fprintf(t, "[%s::b]Revision [red::b]%s", "yellow", rev)
}
