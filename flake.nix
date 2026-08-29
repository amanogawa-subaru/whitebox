{
  description = "whitebox NixOS config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { home-manager, ... }:
  {
    nixosModules.default = {
      imports = [
        home-manager.nixosModules.home-manager
        ./imports.nix
      ];
    };
  };
}
