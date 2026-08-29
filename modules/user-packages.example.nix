{ pkgs, ... }:

{
  # Packages selected by the user.
  #
  # Packages required for whitebox itself belong in
  # core-packages.nix instead.

  environment.systemPackages = with pkgs; [
    # cmatrix
  ];

  # User-selected NixOS program options can also go here.
  #
  # programs.steam.enable = true;
}
