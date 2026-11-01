let
  rpc-port = 3901;
in
{
  oxygen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      services.garage = {
        enable = true;
        package = pkgs.garage_2;
        settings = {
          # (metadata_dir & data_dir intentionally left as defaults of the NixOS module)

          db_engine = "lmdb";
          metadata_auto_snapshot_interval = "6h";

          replication_factor = 3;

          compression_level = 2;

          rpc_secret_file = config.sops.secrets."garage/rpc-secret".path;
        };

        # My garage communicates exclusively over yggdrasil. But most of my computers don't have a static yggdrasil address.
        # So, we dynamically bind the RPC to whatever address we have *right now*.
        dynamic-rpc-addr = {
          enable = true;
          oneshot-credential = "garage-rpc-address";
        };
      };

      # In order to do so, this credential wraps the yggdrasil IPv6 address in the shape that garage expects and tacks on a port.
      oneshot-credentials."garage-rpc-address" =
        let
          address-credentials = config.oneshot-credentials."yggdrasil-address";
        in
        {
          service = {
            bindsTo = [ address-credentials.name ];
            after = [ address-credentials.name ];

            serviceConfig.LoadCredential = [
              "address:${address-credentials.path}"
            ];

            script = ''
              echo -n "[$(${lib.getExe' config.systemd.package "systemd-creds"} cat address)]:${toString rpc-port}"
            '';
          };
        };

      systemd.services.garage = {
        # Of course, because it's going over yggdrasil, it needs to strictly depend on yggdrasil.
        # Whenever yggdrasil restarts (and thereby gives me a new IP address; also destroys the interface that garage bound to)
        #                            garage will restart as well (and get the new public IP address it should bind to)

        requires = [ "yggdrasil.service" ];
        after = [ "yggdrasil.service" ];
      };

      networking.firewall.allowedTCPPorts = [ rpc-port ];

      sops.secrets."garage/rpc-secret".sopsFile = ./garage.secrets.yaml;
    };
}
