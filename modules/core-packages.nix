# This module is intended for packages and programs whitebox requires to function

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Desktop UI/UX
    quickshell
    hyprpaper
    
    # Utilities
    ddcutil
    brightnessctl
    wl-clipboard
    cliphist
    grim
    slurp
    swappy
    libnotify
    ffmpegthumbnailer
    cava
    imagemagick
    yt-dlp
    playerctl
  ];
  
  # Lock screen
  programs.hyprlock.enable = true;
}
