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

          rpc_bind_addr = "[::]:${toString rpc-port}";
        };
      };

      networking.firewall.allowedTCPPorts = [ rpc-port ];

      sops.secrets."garage/rpc-secret" = {
        sopsFile = ./garage.secrets.yaml;
      };
      systemd.services.garage = {
        serviceConfig.LoadCredential = [ "rpc-secret:${config.sops.secrets."garage/rpc-secret".path}" ];
        environment.GARAGE_RPC_SECRET_FILE = "%d/rpc-secret";
      };
    };
}
