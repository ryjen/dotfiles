# TODO

## Nix Migration

- [x] Bootstrap flake and host config
- [x] Port baseline Home Manager modules
- [x] Port default CLI tooling
- [x] Port optional tooling
- [x] Remove legacy imperative install path
- [x] Move static file payloads to `files/home` and `files/system`
- [x] Add minimal internet-updatable agent config
- [ ] Validate `home-manager switch --flake .#ryjen@nixos`
- [ ] Validate `sudo nixos-rebuild switch --flake .#nixos`
- [ ] Refactor Neovim to be more Nix-native
- [ ] Review static files for native Home Manager replacements
