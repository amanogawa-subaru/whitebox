#  This module is for managing Home Manager 
 
{ pkgs, username, ... }:

  let
    cbz-thumbnailer = pkgs.writeShellApplication {
      name = "whitebox-cbz-thumbnailer";

      runtimeInputs = with pkgs; [
        _7zz
	imagemagick
      ];

      text = builtins.readFile ./scripts/cbz-thumbnailer;
    };
  in

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
  
  # Comics thumbnailer
  xdg.dataFile."thumbnailers/whitebox-comics.thumbnailer".text = ''
    [Thumbnailer Entry]
    Exec=${cbz-thumbnailer}/bin/whitebox-cbz-thumbnailer %i %s %o
    MimeType=application/vnd.comicbook+zip;
  '';
  
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
