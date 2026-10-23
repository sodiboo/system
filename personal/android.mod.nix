{
  personal = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.android-tools
      pkgs.scrcpy
    ];

    programs.droidcam.enable = true;
  };
}
