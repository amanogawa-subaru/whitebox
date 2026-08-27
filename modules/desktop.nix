# This module is intended for desktop settings

{ pkgs, username, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  programs.dconf.enable = true;

  # Desktop-related Home Manager settings
  home-manager.users.${username} = {
    # Hyprland / Hyprlock / Hypridle config
    xdg.configFile."hypr".source = ../home/dots/hypr;

    # Clipboard history backend for Quickshell
    systemd.user.services.cliphist = {
      Unit = {
        Description = "Clipboard history";
      };

      Service = {
        ExecStart =
          "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";

        Restart = "on-failure";
        RestartSec = 2;
      };
    };

    # Hypridle runs as a Home Manager user service.
    # Its config is kept with the rest of the Hypr dotfiles at
    # dots/hypr/hypridle.conf, avoiding a conflict with the
    # whole ~/.config/hypr directory symlink.
    services.hypridle = {
      enable = true;
    };
  };
}
