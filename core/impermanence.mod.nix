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
    };
}
