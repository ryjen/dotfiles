# TODO

## Nix Migration

- [x] Bootstrap flake and host config
- [x] Port baseline Home Manager modules
- [x] Port default CLI tooling
- [x] Port optional tooling
- [x] Remove legacy imperative install path
- [x] Move static file payloads to `files/home` and `files/system`
- [x] Add minimal internet-updatable agent config
- [x] Split reusable baseline from host/profile overlays
- [x] Make the shared Git baseline declarative
- [ ] Validate `home-manager switch --flake .#USERNAME@nixos`
- [ ] Validate `sudo nixos-rebuild switch --flake .#nixos`
- [ ] Refactor Neovim to be more Nix-native
- [ ] Review static files for native Home Manager replacements
