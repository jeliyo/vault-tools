# vault-commander

The start of a terminal UI for Vault using the [bubbletea] framework which uses
the ELM model, view, update pattern. Done for the Vault 1.12 hackweek.

## Build

    go build

## Run

Set VAULT_ADDR and VAULT_TOKEN, then

    ./vault-commander

## Notes

List of terminal UI (TUI) apps and libraries: https://github.com/rothgar/awesome-tuis

Related go terminal UIs (TUIs):
- https://github.com/derailed/k9s
- https://github.com/hashicorp/damon
- https://github.com/robinovitch61/wander

This version of vault-commander works for viewing enabled auth methods and
secret engines, and the plugin catalog. Scrolling doesn't work, because the
display table is recreated in View(), so the cursor position is lost.

It uses the new vault-client-go for most of the Vault queries, though it uses the old client to build the vault status view because vault-client-go doesn't return those [quite right yet][vault-client-go#66].

Uses the table and flexbox layout from [stickers]. The flexbox layout seems
good, but the table may not be the best for live data.

The code is fairly rough, lots of experimentation going on here.

This is nice example of code layout for a bubbletea app: https://github.com/bashbunni/pjs

[bubbletea]: https://github.com/charmbracelet/bubbletea
[stickers]: https://github.com/76creates/stickers
[vault-client-go#66]: https://github.com/hashicorp/vault-client-go/issues/66
