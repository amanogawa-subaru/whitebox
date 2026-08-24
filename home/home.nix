#  This module is for managing Home Manager 
 
{ ... }:

{
  home.username = "subaru";
  home.homeDirectory = "/home/subaru";

  home.stateVersion = "26.05";

  # Create user directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
