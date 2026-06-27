# Hermes custom provider layers

Place local override fragments here when a provider default should be shared by this dotfiles profile but remain outside the managed adopted layer.

The final runtime provider config is rendered by:

```bash
configctl init apply hermes-config --allow mutable-user-state --yes
```
