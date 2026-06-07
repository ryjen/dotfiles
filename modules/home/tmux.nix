{
  ...
}:
{
  programs.tmux = {
    enable = true;
    aggressiveResize = true;
    baseIndex = 1;
    clock24 = true;
    escapeTime = 50;
    historyLimit = 30000;
    keyMode = "vi";
    mouse = true;
    terminal = "xterm-256color";
    extraConfig = ''
      bind | split-window -h
      bind - split-window -v

      bind r source-file ~/.tmux.conf

      bind -n M-Left select-pane -L
      bind -n M-Right select-pane -R
      bind -n M-Up select-pane -U
      bind -n M-Down select-pane -D

      bind-key -T copy-mode-vi WheelUpPane send -X scroll-up
      bind-key -T copy-mode-vi WheelDownPane send -X scroll-down
      set -g @scroll-speed-num-lines-per-scroll 5

      set -g update-environment "SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION"
      set-option -sa terminal-overrides ',xterm*:RGB:sitm=\E[3m'
      set-option -g focus-events on
      set-option -g status-right ""
    '';
  };
}
