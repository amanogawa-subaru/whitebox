# This module is intended for desktop settings

{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  programs.dconf.enable = true;
  
  # PAM for lockscreen
  security.pam.services.hyprlock = {};

  # System-wide GTK3 theme fallback
  environment.systemPackages = [
    (pkgs.catppuccin-gtk.override {
      accents = [ "pink" ];
      size = "standard";
      tweaks = [ ];
      variant = "frappe";
    })
  ];

  environment.etc."xdg/gtk-3.0/settings.ini".text = ''
    [Settings]
    gtk-theme-name=catppuccin-frappe-pink-standard
    gtk-application-prefer-dark-theme=true
  '';
}
