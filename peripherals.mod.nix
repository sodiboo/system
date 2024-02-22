{
  shared.modules = [
    {
      programs.adb.enable = true;
      users.users.sodiboo.extraGroups = ["adbusers"];
    }
  ];
  sodium.modules = [
    ({pkgs, ...}: {
      hardware.wooting.enable = true;
      users.users.sodiboo.extraGroups = ["input"];

      environment.systemPackages = with pkgs; [
        openrgb-with-all-plugins
        openrazer-daemon
        polychromatic
      ];
    })
  ];
  lithium.modules = [
    {
      # I have a fingerprint reader. I want to use it for sudo, polkit and the likes.
      services.fprintd.enable = true;

      # I'd like greetd to unlock my keyring, which fprint can't do.
      security.pam.services.greetd.fprintAuth = false;

      # And swaylock doesn't work well with fprint.
      security.pam.services.swaylock.fprintAuth = false;

      services.upower.enable = true;
    }
  ];
}
