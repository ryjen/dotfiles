{ config, ... }:
{
  # Diversion's Linux CLI is installed explicitly through configctl. Home
  # Manager only exposes the vendor-owned install location; it never performs
  # a network-backed install during activation.
  home.sessionPath = [ "${config.home.homeDirectory}/.diversion/bin" ];
}
