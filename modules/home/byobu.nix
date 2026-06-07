{
  pkgs,
  ...
}:
{
  home.packages = [
    pkgs.byobu
  ];

  home.file.".zprofile".text = ''
    _byobu_sourced=1 . ${pkgs.byobu}/bin/byobu-launch 2>/dev/null || true
  '';
}
