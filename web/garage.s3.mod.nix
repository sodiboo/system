{
  oxygen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    {
      services.garage.settings.s3_api = {
        s3_region = "garage";

        api_bind_addr = "/run/garage/socket";
        public_endpoint = "https://s3.sodi.boo";
        public_endpoint_path_style = true;
      };

      systemd.services.garage = {
        serviceConfig = {
          RuntimeDirectory = "garage";
          RuntimeDirectoryMode = "700";
        };
      };

      systemd-socket-proxyd.garage-s3-api = {
        connections-max = 4096;

        socket = {
          wantedBy = [ "sockets.target" ];
          before = [ "sockets.target" ];
          listenStreams = [ "@s3" ];
        };

        service = {
          # do not allow socket proxy to run without garage being active
          # but, don't bindsTo=[] such that connecting to s3 api does not imply starting garage.
          # this is because garage layout is managed imperatively and i expect to "manually take it down" whenever that needs maintenance.
          requisite = [ "garage.service" ];
          partOf = [ "garage.service" ];
          after = [ "garage.service" ];
        };
        upstream = config.services.garage.settings.s3_api.api_bind_addr;
      };

      caddy.sites."s3.sodi.boo".routes = [
        {
          terminal = true;
          handle = [
            {
              handler = "reverse_proxy";
              upstreams = [ { dial = "unix/@s3"; } ];
            }
          ];
        }
      ];
    };
}
