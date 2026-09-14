{
  description = "whitebox NixOS config";

  inputs = {
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    catppuccin.url = "github:catppuccin/nix";
  };
  
  outputs = { home-manager, catppuccin, ... }: {
    nixosModules.default = {
      imports = [
        home-manager.nixosModules.home-manager
        ./imports.nix
      ];
      
      home-manager.sharedModules = [
        catppuccin.homeModules.catppuccin
      ];
    };

    homeModules.default = import ./home;
  };
}
