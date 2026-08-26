{ settings, ... }:

{
  hardware.nvidia.prime =
    {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };

      nvidiaBusId =
        settings.nvidiaBusId;
    }

    // (
      if settings.primeIGPU == "intel" then
        {
          intelBusId =
            settings.igpuBusId;
        }

      else if settings.primeIGPU == "amd" then
        {
          amdgpuBusId =
            settings.igpuBusId;
        }

      else
        { }
    );
}
