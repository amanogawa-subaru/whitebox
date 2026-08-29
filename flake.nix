{
  description = "whitebox NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { home-manager, catppuccin, firefox-addons, ... }: {
    nixosModules.default = {
      imports = [
        home-manager.nixosModules.home-manager
        ./imports.nix
      ];
      
      home-manager.sharedModules = [
        catppuccin.homeModules.catppuccin
      ];
      
      home-manager.extraSpecialArgs = {
        inherit firefox-addons;
      };
    };
  };
}
