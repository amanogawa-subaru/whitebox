# This module is intended for regular packages 

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Terminal stuff
    kitty
    git 
    wget
    curl
    btop
    fastfetch
    pciutils
    grim
    
    # Editing
    geany
	gimp
    audacity
    
    # Desktop apps
    nemo
    qbittorrent
    baobab
    quickshell
    librewolf
    lollypop
    anki
    calibre
    
    
    # Utilities
    hyprpaper
    imv # image viewer
    ddcutil # for brightness
    brightnessctl # also for brightness
    playerctl
    ];
}
