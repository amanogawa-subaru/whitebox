{ lib, ... }:

let
  settings = import ./settings.nix;
  username = settings.username;
in

{
  _module.args = {
    inherit username settings;
  };

  imports = [
    ./modules/system.nix
    ./modules/desktop.nix
    
    ./modules/core-packages.nix
    ./modules/default-packages.nix
    ./modules/user-packages.nix
    
    ./modules/fonts.nix
  ]
  ++ lib.optional
    settings.nvidia
    ./modules/nvidia.nix
  ++ lib.optional
    settings.nvidiaPrime
    ./modules/nvidia-prime.nix;
}
