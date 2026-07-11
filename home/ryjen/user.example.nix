# Copy to user.local.nix and customize local, non-secret selections.
# Use a path flake so ignored files are included:
#   home-manager switch --flake "path:$PWD#ryjen@dubnium"
{ ... }:
{
  dotfiles.git = {
    userName = "Your Name";
    userEmail = "you@example.com";
  };

  # Program and capability selections belong here as explicit flags are added.
  # Host-specific constraints and paths remain in profiles/.
}
