{sops-nix, ...}: {
  universal.modules = [
    sops-nix.nixosModules.sops
    {
      sops.defaultSopsFile = ./secrets.yaml;
      sops.defaultSopsFormat = "yaml";

      sops.age.keyFile = "/home/sodiboo/.config/sops/age/keys.txt";

      sops.secrets.access-token-prelude.mode = "0444";
    }
  ];

  oxygen.modules = [
    ({config, ...}: {
      users.groups.sharkey-db-password = {};
      users.users.sharkey.extraGroups = [config.users.groups.sharkey-db-password.name];
      users.users.postgres.extraGroups = [config.users.groups.sharkey-db-password.name];

      sops.secrets.sharkey-db-password = {
        mode = "0440";
        group = config.users.groups.sharkey-db-password.name;
      };

      sops.secrets.sharkey-redis-password.owner = config.users.users.sharkey.name;
    })
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
