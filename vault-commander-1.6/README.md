# vault-commander

A terminal UI for Vault. Inspired by [k9s][k9s] and [docui][docui]. Built on [tview][tview].

[k9s]: https://github.com/derailed/k9s
[docui]: https://github.com/skanehira/docui
[tview]: https://github.com/rivo/tview

# Build

```shell
go build
```

# Run

Set environment variables for connection and authentication to Vault (such as
VAULT_TOKEN, VAULT_ADDR) then run `./vault-commander`.