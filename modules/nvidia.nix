# Generic NVIDIA configuration
# Used by any system with an NVIDIA GPU.

{ config, ... }:

{
  services.xserver.videoDrivers = [
    "modesetting"
    "nvidia"
  ];

  hardware.nvidia = {
    # Required for Wayland compositors such as Hyprland.
    modesetting.enable = true;

    # Use NVIDIA's open kernel modules.
    open = true;

    # Install nvidia-settings.
    nvidiaSettings = true;

    # Use the stable NVIDIA driver.
    package =
      config.boot.kernelPackages.nvidiaPackages.stable;
  };
}
