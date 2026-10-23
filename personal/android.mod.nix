{
  personal = { pkgs, ... }: {
    nixpkgs.overlays = [
      (final: prev: {
        adb-wireless = final.callPackage ./pkgs/android/adb-wireless.nix { };
      })
    ];

    environment.systemPackages = [
      pkgs.android-tools
      pkgs.adb-wireless
      pkgs.scrcpy
    ];

    programs.droidcam.enable = true;
  };
}
