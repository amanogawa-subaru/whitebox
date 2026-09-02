#  This module is for managing Home Manager 
 
{ pkgs, username, firefox-addons, ... }:

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


  # Create user directories
  xdg = {
    enable = true;
    	
    userDirs = {
      enable = true;
      createDirectories = true;
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
  
  # Wallpaper daemon
  services.hyprpaper = {
    enable = true;

    settings = {
      ipc = true;
      splash = false;
    };
  };
  
  # Dotfiles
  xdg.configFile = {
    "fastfetch".source = ./dots/fastfetch;
    "quickshell".source = ./dots/quickshell;
  };			
  
  ## Default home apps
  
  # Set nemo as default file browser
  xdg.desktopEntries.nemo = {
    name = "Nemo";
	  exec = "${pkgs.nemo-with-extensions}/bin/nemo";
  };
  
  programs.kitty = {
    enable = true;
    extraConfig = builtins.readFile ./dots/kitty/kitty.conf;
  };
  
  # Firefox is enabled as a fallback browser
  programs.firefox = {
    enable = true;

    

    profiles.default = {
      id = 0;
      isDefault = true;
      
      settings = {
        "extensions.autoDisableScopes" = 0;
      };
           
      extensions = {
	    force = true;
	    packages = with firefox-addons.packages.${pkgs.system}; [
	      firefox-color
	    ];
      };
    };
  };

  programs.librewolf = {
    enable = true;

    profiles.default = {
      id = 0;
      isDefault = true;
      
      settings = {
        "extensions.autoDisableScopes" = 0;
      };
	  
	  extensions = {
	    force = true;
	    packages = with firefox-addons.packages.${pkgs.system}; [
	      firefox-color
	    ];
      };
    };
  };  
  
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "inode/directory" = [ "nemo.desktop" ];
      "application/x-gnome-saved-search" = [ "nemo.desktop" ];
      "text/plain" = [ "geany.desktop" ];
      "text/x-lua" = [ "geany.desktop" ];
      "text/x-qml" = [ "geany.desktop" ];
      "image/jpeg" = [ "imv.desktop" ];
      "image/png" = [ "imv.desktop" ];
      "image/webp" = [ "imv.desktop" ];
      "image/gif" = [ "imv.desktop" ];
      "image/bmp" = [ "imv.desktop" ];
      "image/tiff" = [ "imv.desktop" ];
      "audio/flac" = [ "org.gnome.Lollypop.desktop"];
      "audio/mpeg" = [ "org.gnome.Lollypop.desktop"];
      "video/mp4" = [ "mpv.desktop" ];
      "video/x-matroska" = [ "mpv.desktop" ];
      "video/webm" = [ "mpv.desktop" ];
      "video/x-msvideo" = [ "mpv.desktop" ];
      "video/quicktime" = [ "mpv.desktop" ];
      "application/pdf" = [ "onlyoffice-desktopeditors.desktop" ];
      "x-scheme-handler/http" = [ "librewolf.desktop" ];
      "x-scheme-handler/https" = [ "librewolf.desktop" ];
      "text/html" = [ "librewolf.desktop" ];
      "application/xhtml+xml" = [ "librewolf.desktop" ];
    };
  };
  
  
  # Set default terminal for nemo
  dconf = {
    settings = {
      "org/cinnamon/desktop/applications/terminal" = {
        exec = "kitty";
      };
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
      };    
    };
  };
  

}
