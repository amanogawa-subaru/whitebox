# This module is intended for whitebox's appearance and theming

{ config, pkgs, ... }:

{
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

  # Apply GTK theme to GTK4 applications
  xdg.configFile = {
    "gtk-4.0/assets".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";

    "gtk-4.0/gtk.css".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";

    "gtk-4.0/gtk-dark.css".source =
      "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };

  # Cursor
  home.pointerCursor = {
    enable = true;
    gtk.enable = true;

    package = pkgs.bibata-cursors;
    name = "Bibata-Modern-Ice";
    size = 20;
  };

  # Prefer dark color scheme
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
  };
}
