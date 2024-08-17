{nixpkgs-with-linux-firmware-at-20240220, ...}: {
  nitrogen.modules = [
    {
      boot.kernelParams = ["iomem=relaxed"];
      nixpkgs.overlays = [
        (final: prev: {
          linux-firmware-20240220 = final.callPackage "${nixpkgs-with-linux-firmware-at-20240220}/pkgs/os-specific/linux/firmware/linux-firmware" {};

          # oh my fucking god i spent way too long on this with permissions
          # so if you get "Permission denied", heed my warning
          # if you copy from the nix store obviously it won't be writable!
          # it took me 50 (!!!) fucking minutes to figure out that i need chmod +w
          # kill me now
          # linux-firmware = final.runCommand "linux-firmware-patched" {} ''
          #   cp -R ${prev.linux-firmware} $out
          #   chmod -R +w $out
          #   install ${final.linux-firmware-20240220}/lib/firmware/intel/ibt-0040-2120.{sfi,ddc} $out/lib/firmware/intel
          # '';

          linux-firmware = final.linux-firmware-20240220;
        })
      ];
    }
  ];
}
