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
    cava

    # Utilities
    hyprpaper
    imv # image viewer
    ddcutil # for brightness
    brightnessctl # also for brightness
    playerctl
    yt-dlp
    libnotify
    grim
    slurp
    wl-clipboard
    cliphist
    imagemagick
    swappy
        
    # Desktop apps
    nemo-with-extensions
    qbittorrent
    baobab
    quickshell
    librewolf
    lollypop
    anki
    calibre

    # Editing
    geany
	gimp
    audacity
        
    ];
}
