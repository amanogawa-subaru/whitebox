{ ... }:

{
  imports = [
    ./modules/system.nix
    ./modules/desktop.nix
    ./modules/programs.nix
    ./modules/packages.nix
    ./modules/nvidia.nix
  ];
}
