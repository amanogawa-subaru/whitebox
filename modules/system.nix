# This module is intended for system settings
{ pkgs, username, ... }:

{
  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
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

  home-manager.extraSpecialArgs = {
    inherit username;
  };
  
  home-manager.users.${username} = 
    import ../home/home.nix;
  
  # I2C support for external monitor control
  hardware.i2c.enable = true;
  
  # PAM for lockscreen
  security.pam.services.hyprlock = {};
  
  # Japanese input
  i18n = {
    defaultLocale = "en_US.UTF-8";
    
    extraLocales = [
      "ja_JP.UTF-8/UTF-8"
    ];
    
    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5.addons = with pkgs; [
        fcitx5-mozc
        fcitx5-gtk
      ];
    };  
  };
}
