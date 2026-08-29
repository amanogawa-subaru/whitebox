# This module is intended for packages and program options the user wishes to add-on

{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
  ];

  # User-selected NixOS program options can also go here.
  #
  # programs.steam.enable = true;
}
