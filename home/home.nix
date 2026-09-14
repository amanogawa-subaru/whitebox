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
  };			
  
  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./dots/kitty/kitty.conf;
  };
  
  # Prefer dark color scheme
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };
}
