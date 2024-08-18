{
  universal.modules = [
    {
      services.openssh.enable = true;
      services.openssh.settings.PasswordAuthentication = false;
      users.users.sodiboo.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8eWTRBpEegdAdTkPeBJXmyi7o2WQFL3mdWf2FRoXdo sodiboo@lithium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExB5YOySRzfOx8RUZAcV8yh8SBwq5lAsQD1df8UfrHw sodiboo@sodium"
      ];
    }
  ];

  sodium.home_modules = [
    {
      programs.ssh = {
        enable = true;
        extraConfig = ''
          Host oxygen
            HostName vps.sodi.boo
            User sodiboo
            IdentityFile ~/.ssh/id_ed25519-2024-06
          Host iridium
            HostName iridium.lan
            User sodiboo
            IdentityFile ~/.ssh/id_ed25519-2024-06
          Host nitrogen
            HostName nitrogen.wg
            User sodiboo
            IdentityFile ~/.ssh/id_ed25519-2024-06
        '';
      };
    }
  ];

  nitrogen.home_modules = [
    {
      programs.ssh = {
        enable = true;
        extraConfig = ''
          Host oxygen
            HostName oxygen.wg
            User sodiboo
            IdentityFile ~/.ssh/id_ed25519-2024-08
          Host iridium
            HostName iridium.wg
            User sodiboo
            IdentityFile ~/.ssh/id_ed25519-2024-08
          Host sodium
            HostName sodium.wg
            User sodiboo
            IdentityFile ~/.ssh/id_ed25519-2024-08
        '';
      };
    }
  ];
}
