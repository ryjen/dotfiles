{ pkgs, ... }:
{
  home.packages = [
    pkgs.cmake
    pkgs.ffmpeg
    pkgs.gcc
    pkgs.gh
    pkgs.git
    pkgs.gnumake
    pkgs.openssh
    pkgs.pkg-config
    pkgs.python3
    pkgs.ripgrep
    pkgs.uv
  ];
}
