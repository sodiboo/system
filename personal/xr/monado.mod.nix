inputs: {
  sodium =
    { lib, pkgs, ... }:
    {
      services.monado.enable = true;
      services.monado.package =
        inputs.nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.monado.overrideAttrs
          (
            finalAttrs: prevAttrs: {
              patches = prevAttrs.patches or [ ] ++ [
                ./monado-sigterm.patch
                ./right-wand-first.patch
              ];
            }
          );
      services.monado.forceDefaultRuntime = true;
      services.monado.defaultRuntime = true;
      systemd.user.services.monado.environment = {
        STEAMVR_LH_ENABLE = "1";
        XRT_COMPOSITOR_COMPUTE = "1";
      };

      home-shortcut = {
        xdg.configFile."openvr/openvrpaths.vrpath".text = builtins.toJSON {
          config = [ "/home/sodiboo/.local/share/Steam/config" ];
          external_drivers = null;
          jsonid = "vrpathreg";
          log = [ "/home/sodiboo/.local/share/Steam/logs" ];
          runtime = [ "${inputs.nixpkgs-xr.packages.${pkgs.stdenv.hostPlatform.system}.xrizer}/lib/xrizer" ];
          version = 1;
        };
      };
    };
}
