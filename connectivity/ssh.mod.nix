{
  universal = {
    services.openssh.enable = true;
    services.openssh.settings.PasswordAuthentication = false;
    users.users.sodiboo.openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExB5YOySRzfOx8RUZAcV8yh8SBwq5lAsQD1df8UfrHw sodiboo@sodium"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOgQnnx7CVs59yA2CBeO34FAIeEjsBs7wG4S4XnPsOyG sodiboo@nitrogen"
    ];
  };

  personal.home-shortcut = {
    programs.ssh = {
      enable = true;
      matchBlocks =
        let
          to = hostname: {
            inherit hostname;
            user = "sodiboo";
            identityFile = "~/.ssh/id_ed25519";
          };
        in
        {
          iridium = to "iridium.wg";
          sodium = to "sodium.wg";
          nitrogen = to "nitrogen.wg";
          oxygen = to "oxygen.wg";
          # These are backup hosts for when wireguard fails.
          # Generally, i'll be connecting to SSH via wireguard.
          "+iridium" = to "iridium.lan";
          "+sodium" = to "sodium.lan";
          "+nitrogen" = to "nitrogen.lan";
          "+oxygen" = to "vps.sodi.boo";
        };
    };
  };
}
