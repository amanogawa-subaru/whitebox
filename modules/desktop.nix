# This module is intended for desktop settings

{ pkgs, username, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.dconf.enable = true;

  # Desktop-related Home Manager settings
  home-manager.users.${username} = {
    # Hyprland / Hyprlock / Hypridle config
    xdg.configFile = {
      "hypr/colors.lua".source = ../home/dots/hypr/colors.lua;
      "hypr/hyprland.lua".source = ../home/dots/hypr/hyprland.lua;
      "hypr/hyprlock.conf".source = ../home/dots/hypr/hyprlock.conf;
      "hypr/hypridle.conf".source = ../home/dots/hypr/hypridle.conf;

      "hypr/config".source = ../home/dots/hypr/config;
      "hypr/wallpapers".source = ../home/dots/hypr/wallpapers;
    };

    # Clipboard history backend for Quickshell
    systemd.user.services.cliphist = {
      Unit = {
        Description = "Clipboard history";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart =
          "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";

        Restart = "on-failure";
        RestartSec = 2;
      };
      
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    # Hypridle user service
    services.hypridle = {
      enable = true;
    };
  };
}
