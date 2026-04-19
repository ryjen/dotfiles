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
    trusted-key "0CDC76D5C109D17AAA6A71FAD5A34F776D49C905"
  '';

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry-gtk2;
    enableZshIntegration = true;
    defaultCacheTtl = 1800;
    maxCacheTtl = 7200;
  };
}
