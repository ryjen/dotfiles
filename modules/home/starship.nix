{
  ...
}:
{
  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      format = "$character";
      right_format = "$all";
      command_timeout = 900;
    };
  };
}
