# This module is intended for programs that have dedicated Nix Modules

{ pkgs, ... }:

{
  programs.firefox.enable = true;
  
  programs.hyprlock.enable = true;
  
  services.mullvad-vpn = {
    enable = true;
    package = pkgs.mullvad-vpn;
  };
}
