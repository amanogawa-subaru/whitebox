#  This module is intended for managing Home Manager 
 
{ pkgs, username, ... }:

{
  imports = [
    ./appearance.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";
  
  # Dotfiles
  xdg.configFile = {
    "fastfetch".source = ./dots/fastfetch;
    "quickshell".source = ./dots/quickshell;

    "foot/colors.ini".source = ./dots/foot/colors.ini;
    
    "hypr/colors.lua".source = ./dots/hypr/colors.lua;
    "hypr/hyprland.lua".source = ./dots/hypr/hyprland.lua;
    "hypr/hyprlock.conf".source = ./dots/hypr/hyprlock.conf;
    "hypr/hypridle.conf".source = ./dots/hypr/hypridle.conf;

    "hypr/config".source = ./dots/hypr/config;
    "hypr/wallpapers".source = ./dots/hypr/wallpapers;
  };			

  # Hyprland Polkit agent
  systemd.user.services.hyprpolkitagent = {
    Unit = {
      Description = "Hyprland Polkit Authentication Agent";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 2;
    };

    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Hyprpaper user service
  services.hyprpaper = {
    enable = true;

    settings = {
      ipc = true;
      splash = false;
    };
  };

  # Hypridle user service
  services.hypridle.enable = true;

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
}
