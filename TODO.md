# TODO

## Issues found in repo scan (security/bugfix/improvements)

- [x] P0 Fix MCP uninstall task that sets an empty path (removal currently no-op/fails).
  - File: collections/ansible_collections/ryjen/dotfiles/roles/mcp/tasks/main.yml:7
- [x] P0 Add or adjust MCP service start/stop to avoid missing Makefile (systemd currently calls `/usr/bin/make up/down`).
  - File: collections/ansible_collections/ryjen/dotfiles/roles/mcp/templates/mcp.service.j2:10
- [x] P0 Fix GPG private key import: use `shell` (pipe) and add `no_log: true` to avoid leaking secrets.
  - File: collections/ansible_collections/ryjen/dotfiles/roles/gpg/tasks/main.yml:34
- [x] P0 Default MCP gateway to loopback (e.g., 127.0.0.1) and explicitly opt into profiles to reduce exposure.
  - File: collections/ansible_collections/ryjen/dotfiles/roles/mcp/templates/gateway.yml.j2:4
- [x] P1 Ensure MCP docker-compose volume path is defined (export `MCP_VOLUMES_DIR` or template a concrete path).
  - File: collections/ansible_collections/ryjen/dotfiles/roles/mcp/templates/docker-compose.yml.j2:45
- [x] P1 Reduce supply-chain risk: replace `curl | sh`, `npx -y`, and ad-hoc `git clone` with pinned versions and checksums or package managers.
  - Files:
    - collections/ansible_collections/ryjen/dotfiles/roles/oh-my-zsh/tasks/manual.yml:7
    - collections/ansible_collections/ryjen/dotfiles/roles/starship/tasks/main.yml:4
    - collections/ansible_collections/ryjen/dotfiles/roles/continue/tasks/main.yml:12
    - collections/ansible_collections/ryjen/dotfiles/roles/nerdfonts/tasks/main.yml:13
    - collections/ansible_collections/ryjen/dotfiles/roles/neovim/tasks/main.yml:25
- [ ] P2 Fix starship uninstall command quoting (current single-quote nesting likely breaks).
  - File: collections/ansible_collections/ryjen/dotfiles/roles/starship/tasks/main.yml:8
- [ ] P2 Remove or wire up unused `mcp_manage_docker` variable to avoid drift.
  - File: collections/ansible_collections/ryjen/dotfiles/roles/mcp/defaults/main.yml:6
- [x] Fix MCP tests broken conditionals (`assert` conditions must be strings under jinja2_native).
  - File: collections/ansible_collections/ryjen/dotfiles/roles/mcp/tests/test.yml

## Nix Migration Progress

- [x] Phase 1: Bootstrap Flake and Host config
- [x] Phase 2: Port `basic` profile (git, gpg, zsh, starship)
- [x] Phase 3: Port `default` profile (bat, fzf, lsd, tmux, neovim symlink)
- [x] Phase 4: Port `extra` profile (docker, android, agents)
- [x] Port common CLI tools (bottom, lazygit, etc.)
- [x] Port oh-my-zsh plugins and modular zsh config
- [ ] Phase 5: Complete secrets migration (move from Ansible Vault to sops-nix)
- [ ] Refactor Neovim to be Nix-native (optional)

## Packages

- astronvim
- ngrok
- prezto for zsh

## Vim

- stylua
- markdownlint
- terrafmt
- vint
