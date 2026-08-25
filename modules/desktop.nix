# This module is intended for desktop settings

{ pkgs, ... }:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  
  programs.dconf.enable = true;

}


