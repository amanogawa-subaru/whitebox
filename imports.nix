{ ... }:

let
  settings = import ./settings.nix;
  username = settings.username;
in

{
  _module.args = {
    inherit username;
  };  	  	


  imports = [
    ./modules/system.nix
    ./modules/desktop.nix
    ./modules/programs.nix
    ./modules/packages.nix
    ./modules/fonts.nix
   # ./modules/nvidia.nix
  ];
}
