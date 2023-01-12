package internal

func newSecretEngines(a *App) *mountOutput {
	mo := newMountOutput(a, "secret engines")
	populateSecretEngines(mo, a)
	setSEKeyBinding(mo, a)

	return mo
}

func setSEKeyBinding(mo *mountOutput, a *App) {
	mo.setKeyBinding(a, populateSecretEngines, "secret engines")
}

func populateSecretEngines(mo *mountOutput, a *App) {
	se, err := a.Client.Sys().ListMounts()
	if err != nil {
		a.setStatus(err.Error())
		return
	}
	mo.outputMap = se
	mo.populate(a)
}
