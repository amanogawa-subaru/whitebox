# This module is intended for packages and programs whitebox requires to function

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Desktop UI/UX
    quickshell
        
    # Utilities
    ddcutil
    brightnessctl
    cliphist
    swappy
    cava
    imagemagick
    yt-dlp
    playerctl
  ];
}
