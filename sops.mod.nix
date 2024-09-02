{sops-nix, ...}: {
  universal.modules = [
    sops-nix.nixosModules.sops
    {
      sops.defaultSopsFile = ./secrets.yaml;
      sops.defaultSopsFormat = "yaml";

      # sync ̃~/.ssh/sops out-of-band
      # ssh-to-age -private-key -i ~/.ssh/sops > ~/.config/sops/age/keys.txt
      sops.age.keyFile = "/home/sodiboo/.config/sops/age/keys.txt";

      sops.secrets.access-token-prelude.mode = "0444";
    }
    ({config, ...}: {
      sops.secrets.wireguard-private-key = {
        key = "wireguard-private-keys/${config.networking.hostName}";
      };
    })
  ];

  oxygen.modules = [
    ({
      lib,
      config,
      ...
    }:
      lib.mkIf config.services.sharkey.enable {
        users.groups.sharkey-db-password = {};
        users.users.sharkey.extraGroups = [config.users.groups.sharkey-db-password.name];
        users.users.postgres.extraGroups = [config.users.groups.sharkey-db-password.name];

        sops.secrets.sharkey-db-password = {
          mode = "0440";
          group = config.users.groups.sharkey-db-password.name;
        };

        sops.secrets.sharkey-redis-password.owner = config.users.users.sharkey.name;

        sops.secrets.meili-master-key-env = {};
      })
    ({
      lib,
      config,
      ...
    }:
      lib.mkIf config.services.writefreely.enable {
        sops.secrets.writefreely-db-password.owner = config.users.users.writefreely.name;
      })
  ];

  iridium.modules = [
    ({config, ...}: {
      sops.secrets.binary-cache-secret = {};
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
