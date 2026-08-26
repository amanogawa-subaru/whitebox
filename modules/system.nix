# This module is intended for system settings
{ ... }:

let
  home-manager = builtins.fetchTarball
    "https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz";  
in

{
  imports = [
    (import "${home-manager}/nixos")
  ];
  
  # Enable trash
  services.gvfs.enable = true;
  
  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Audio
  security.rtkit.enable = true;
  
  services.pipewire = {
    enable = true;
    
    alsa = {
      enable = true;
      support32Bit = true;
    };
    # PulseAudio compatibility
    pulse.enable = true;
  };
  
  # Gaming
  programs.gamemode.enable = true;
  hardware.steam-hardware.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Home Manager
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.subaru = import ../home/home.nix;
  
  # I2C support for external monitor control
  hardware.i2c.enable = true;
  
  # PAM for lockscreen
  security.pam.services.hyprlock = {};
}
