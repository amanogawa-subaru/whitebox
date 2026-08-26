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
    grim # screenshots
    yt-dlp
    libnotify    
    
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
