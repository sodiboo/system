{
  shared.modules = [
    {
      boot.loader.systemd-boot = {
        enable = true;
        # netbootxyz.enable = true;
        consoleMode = "auto";
      };
      boot.loader.efi.canTouchEfiVariables = true;
    }
    ({pkgs, ...}: {
      environment.systemPackages = [
        pkgs.greetd.tuigreet
      ];
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = builtins.concatStringsSep " " [
              "tuigreet"
              ''--time --time-format="%F %T"''
              "--remember"
              "--cmd niri-session"
            ];
            user = "greeter";
          };
        };
      };
      security.pam.services.greetd.enableGnomeKeyring = true;
    })
  ];
}
