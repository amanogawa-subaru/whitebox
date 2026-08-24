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
    
    # Editor
    geany

    # Desktop apps
    nemo
    qbittorrent
    baobab
    ];
}
