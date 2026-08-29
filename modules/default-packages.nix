# This module is intended for packages and programs whitebox uses as defaults

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # File management
    nemo-with-extensions
    bulky
    
    # Browser
    #librewolf
    
    # Media
    imv
    lollypop
    mpv
    
    # Editing
    geany
    
    # CLI
    fastfetch
  ];
  
  # Fallback browser
  #programs.firefox.enable = true;
}
