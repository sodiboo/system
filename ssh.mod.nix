{
  oxygen.modules = [
    {
      services.openssh.enable = true;
      users.users.root.openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN8eWTRBpEegdAdTkPeBJXmyi7o2WQFL3mdWf2FRoXdo sodiboo@contabo-vps"
      ];
    }
  ];

  lithium.home_modules = [
    {
      programs.ssh = {
        enable = true;
        extraConfig = ''
          Host oxygen
            HostName 85.190.241.69
            User root
            IdentityFile ~/.ssh/contabo-vps-2024-05
        '';
      };
    }
  ];
}
