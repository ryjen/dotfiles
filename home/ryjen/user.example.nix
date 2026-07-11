# Copy this file to user.nix and customize it.
# user.nix is intentionally ignored because it contains user-specific choices
# and may contain identity or machine-local values.
{ ... }:
{
  dotfiles.git = {
    userName = "Jane Developer";
    userEmail = "jane@example.com";
  };

  # Program selections will live here as modules gain explicit flags.
  # Keep every supported flag present and explicit in this example.
  #
  # dotfiles.programs.neovim.enable = true;
  # dotfiles.programs.firefox.enable = true;
  # dotfiles.programs.androidStudio.enable = false;
}
