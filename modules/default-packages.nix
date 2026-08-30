# This module is intended for packages and programs whitebox uses as defaults

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # File management
    nemo-with-extensions
    ffmpegthumbnailer
    bulky
    
    # Media
    imv
    lollypop
    mpv
    
    # Editing
    geany
    
    # CLI
    vim
    neovim
    fastfetch
    btop
  ];
  
}
