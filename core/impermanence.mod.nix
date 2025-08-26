{ impermanence, ... }:
{
  universal =
    { lib, config, ... }:
    {
      imports = [ impermanence.nixosModules.impermanence ];

      # ASSUMPTION: these directories are inherently persistent
      # - /boot
      # - /nix/store
      # - /nix/var
      # - /nix/persist
      environment.persistence."/nix/persist" = {

        # default off for now
        enable = lib.mkDefault false;

        directories = [
          "/var/log"
          "/var/lib/nixos"
          "/var/lib/systemd"
          {
            # this is where i keep a clone of this repo on each machine.
            directory = "/etc/nixos";
            user = "sodiboo";
            group = "users";
          }
        ];
        files = [ "/etc/machine-id" ];
      };

      # /var/lib/private needs peculiar permissions, or systemd refuses outright.
      systemd.tmpfiles.settings = lib.mkIf config.environment.persistence."/nix/persist".enable {
        "00-var-lib-private" = {
          # ephemeral parent of persistence mounts: create at boot
          "/var/lib/private".d = {
            user = "root";
            group = "root";
            mode = "0700";
          };

          # persistent backing directory: create or adjust
          "/nix/persist/var/lib/private".d = {
            user = "root";
            group = "root";
            mode = "0700";
          };
        };
      };
    };
}
