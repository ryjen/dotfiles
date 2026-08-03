{ ... }:
{
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
    persistent = true;
    randomizedDelaySec = "1h";
  };
}
