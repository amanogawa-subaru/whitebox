# This module is intended for packages whitebox requires to function

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Desktop UI/UX
    quickshell
    hyprpaper
    kitty
    
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
}
