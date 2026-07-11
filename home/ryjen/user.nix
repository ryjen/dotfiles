# Declarative, non-secret user-wide selections.
# Keep secrets in sops-nix, pass, or another runtime secret store.
{ ... }:
{
  dotfiles.git = {
    userName = "Robert Ryan Jennings";
    userEmail = "1249111+ryjen@users.noreply.github.com";
  };

  # Program and capability selections will move here as modules gain explicit
  # enable flags. Host-specific constraints and paths remain in profiles/.
}
