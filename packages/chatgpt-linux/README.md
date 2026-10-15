# ChatGPT Linux package backport

This directory is a temporary, locally pinned adaptation of
[NixOS/nixpkgs](https://github.com/NixOS/nixpkgs/tree/master/pkgs/by-name/ch/chatgpt)
(the Nixpkgs package recipe is MIT licensed). Captured 2026-10-15 while
the dotfiles channel `nixos-26.05` still packages ChatGPT only for macOS.

- `package.nix` is the upstream Nixpkgs recipe with the Nixpkgs-specific
  `passthru.updateScript` reference omitted.
- `launcher.nix` handles the writable bundled-plugin cache and Electron
  Wayland invocation.
- `source.json` pins an official, **versioned** OpenAI Linux binary and its
  SHA-256 rather than a mutable `latest/` URL.
- `tmpfiles.conf` mirrors the upstream plugin-cache housekeeping.

This code invokes Nix tooling to extract and adapt the official `.deb`; it
is **not** an official NixOS distribution supported by OpenAI. Do not modify
the package to run a remote installer, execute Debian maintainer scripts,
fetch an unverified AppImage, or bypass Electron sandboxing. Keep the
system-managed Codex CLI separate from the bundled runtime.

Upstream tracking:
https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/ch/chatgpt/package.nix

Remove this backport when the pinned Nixpkgs channel has a working Linux
`pkgs.chatgpt`, after a verified local migration.
