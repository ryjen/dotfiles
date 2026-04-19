# Repository Guidelines

## Project Structure & Module Organization

- `flake.nix` defines NixOS and Home Manager outputs.
- `hosts/nixos/` contains the current NixOS host configuration.
- `home/ryjen/home.nix` is the user Home Manager entrypoint.
- `modules/nixos/` contains system-level modules.
- `modules/home/` contains user-level modules.
- `files/home/` contains static files linked into `$HOME`.
- `files/system/` contains static files used by NixOS modules.

## Build, Test, and Development Commands

- `nix flake show` - view flake outputs.
- `nix flake check --no-build` - evaluate all flake outputs.
- `home-manager switch --flake .#ryjen@nixos` - apply Home Manager config.
- `sudo nixos-rebuild switch --flake .#nixos` - apply NixOS system config.
- `nix build .#homeConfigurations.ryjen@nixos.activationPackage` - build Home Manager activation.
- `nix build .#nixosConfigurations.nixos.config.system.build.toplevel` - build NixOS system derivation.

## Coding Style & Naming Conventions

- Nix files use 2-space indentation.
- Keep modules small and scoped to one concern.
- Static files should live under `files/home/` or `files/system/`, not inside modules.
- Prefer Home Manager and NixOS module options over activation scripts.
- Use activation scripts only when config cannot be expressed declaratively.

## Testing Guidelines

- Run `nix flake check --no-build` after module edits.
- Run the relevant `nix build` command when touching package sets or module imports.
- Run `home-manager switch --flake .#ryjen@nixos` before claiming user config works.

## Commit & Pull Request Guidelines

- Commits follow Conventional Commits (`feat: ...`, `fix: ...`, optional scope like `feat(nix): ...`).
- PRs should include: what changed, how to test, and any host or secret migration notes.

## Security & Configuration Tips

- Secrets use `sops-nix`; keep real `secrets.yaml` encrypted.
- Do not commit Codex auth, caches, histories, SQLite state, or runtime logs.
- Keep agent skills updatable with `agents-update`; do not vendor full external skill repos unless needed.
