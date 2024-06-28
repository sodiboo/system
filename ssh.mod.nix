{
  oxygen.modules = [
    {
      services.openssh.enable = true;
      services.openssh.passwordAuthentication = false;
      users.users.sodiboo.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8eWTRBpEegdAdTkPeBJXmyi7o2WQFL3mdWf2FRoXdo sodiboo@lithium"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExB5YOySRzfOx8RUZAcV8yh8SBwq5lAsQD1df8UfrHw sodiboo@sodium"
      ];
    }
  ];

  lithium.home_modules = [
    {
      programs.ssh = {
        enable = true;
        extraConfig = ''
          Host oxygen
            HostName vps.sodi.boo
            User sodiboo
            IdentityFile ~/.ssh/contabo-vps-2024-05
        '';
      };
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
            IdentityFile ~/.ssh/contabo-vps-2024-06
        '';
      };
    }
  ];
}
