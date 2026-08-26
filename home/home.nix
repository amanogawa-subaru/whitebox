#  This module is for managing Home Manager 
 
{ pkgs, ... }:

{
  home.username = "subaru";
  home.homeDirectory = "/home/subaru";

  home.stateVersion = "26.05";


  # Create user directories
  xdg = {
    enable = true;
    	
    userDirs = {
      enable = true;
      createDirectories = true;
    };
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
      
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "frappe";
        accent = "pink";
      };    
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
    "hypr".source = ./dots/hypr;
    "kitty".source = ./dots/kitty;
    "fastfetch".source = ./dots/fastfetch;
    "quickshell".source = ./dots/quickshell;
  };

}
