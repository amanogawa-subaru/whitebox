#  This module is for managing Home Manager 
 
{ config, pkgs, username, ... }:

{
  home.username = username;
  home.homeDirectory = "/home/${username}";

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
  
  ## Default apps
  
  # Set nemo as default file browser
  xdg.desktopEntries.nemo = {
    name = "Nemo";
	  exec = "${pkgs.nemo-with-extensions}/bin/nemo";

  };
  xdg.mimeApps = {
    enable = true;
	defaultApplications = {
      "inode/directory" = [ "nemo.desktop" ];
      "application/x-gnome-saved-search" = [ "nemo.desktop" ];
      "text/plain" = [ "geany.desktop" ];
  	  "text/x-lua" = [ "geany.desktop" ];
	  "text/x-qml" = [ "geany.desktop" ];
      "image/png" = [ "imv.desktop" ];
		
	};
  };
  
  
  # Set default terminal for nemo
  dconf = {
    settings = {
      "org/cinnamon/desktop/applications/terminal" = {
        exec = "kitty";
      };
    };
  };

}
