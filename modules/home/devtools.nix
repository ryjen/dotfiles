{ pkgs, ... }:
{
  home.packages = [
    pkgs.ffmpeg
    pkgs.gh
    pkgs.git
    pkgs.openssh
    pkgs.python311
    pkgs.ripgrep
    pkgs.uv
  ];
}
