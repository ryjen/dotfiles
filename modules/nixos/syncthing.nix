{
  username,
  ...
}:
{
  services.syncthing = {
    enable = true;
    openDefaultPorts = true;
    user = username;
    dataDir = "/home/${username}/.local/state/syncthing";
    configDir = "/home/${username}/.config/syncthing";
  };
}
