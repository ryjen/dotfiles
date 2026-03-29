{
  lib,
  pkgs,
  ...
}:
{
  home.activation.ensureGnuPGHome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -m 700 -p "$HOME/.gnupg"
  '';

  home.file.".gnupg/gpg.conf".text = ''
    use-agent
  '';

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-curses;
    enableZshIntegration = true;
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
  };
}
