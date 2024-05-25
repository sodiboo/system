{sops-nix, ...}: {
  universal.modules = [
    sops-nix.nixosModules.sops
    {
      sops.defaultSopsFile = ./secrets.yaml;
      sops.defaultSopsFormat = "yaml";

      sops.age.keyFile = "/home/sodiboo/.config/sops/age/keys.txt";

      sops.secrets.access-token-prelude = {};
    }
  ];

  personal.modules = [
    ({config, ...}: {
      sops.secrets."spotify/username".owner = config.users.users.sodiboo.name;
      sops.secrets."spotify/password".owner = config.users.users.sodiboo.name;
    })
  ];

  universal.home_modules = [
    ({pkgs, ...}: {
      home.packages = with pkgs; [
        sops
      ];
    })
  ];
}
