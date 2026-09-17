#  This module is for managing Home Manager 
 
{ pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";
  
  # Catppuccin theme
  catppuccin = {
    enable = true;
    autoEnable = true;
    
    flavor = "frappe";
    accent = "pink";
  }; 


  # GTK theme
  gtk = {
    enable = true;

    theme = {
      name = "catppuccin-frappe-pink-standard";
      
      package = pkgs.catppuccin-gtk.override {
        accents = [ "pink" ];
        size = "standard";
        tweaks = [ ];
        variant = "frappe";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
    };   
    
    gtk3.extraConfig = {
	  gtk-application-prefer-dark-theme = true;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = true;
    };   
  };
 
  # Cursor
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;

    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 20;
  };
  
  # Dotfiles
  xdg.configFile = {
    "fastfetch".source = ./dots/fastfetch;
    "quickshell".source = ./dots/quickshell;
    
    "hypr/colors.lua".source = ./dots/hypr/colors.lua;
    "hypr/hyprland.lua".source = ./dots/hypr/hyprland.lua;
    "hypr/hyprlock.conf".source = ./dots/hypr/hyprlock.conf;
    "hypr/hypridle.conf".source = ./dots/hypr/hypridle.conf;

    "hypr/config".source = ./dots/hypr/config;
    "hypr/wallpapers".source = ./dots/hypr/wallpapers;
  };			

  # Enable kitty terminal
  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./dots/kitty/kitty.conf;
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

  # Prefer dark color scheme
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };
}
