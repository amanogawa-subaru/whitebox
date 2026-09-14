# This module is intended for Whitebox-specific system configuration
{ username, ... }:

{
  # Home Manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.extraSpecialArgs = {
    inherit username;
  };

  home-manager.users.${username}.imports = [
    ../home
  ];

  # PAM for lockscreen
  security.pam.services.hyprlock = {};
}
