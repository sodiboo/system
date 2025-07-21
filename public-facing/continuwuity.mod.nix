{
  oxygen =
    {
      lib,
      config,
      ...
    }:
    {
      reverse-proxy."gaysex.cloud".locations."/_matrix".socket = "/run/nginx-socket-proxy/continuwuity";
      reverse-proxy."gaysex.cloud".extra-public-ports = [ 8448 ];
      networking.firewall.allowedTCPPorts = [ 8448 ];

      systemd-socket-proxyd.continuwuity = {
        socket = {
          requiredBy = [ "nginx.service" ];
          listenStreams = [
            "/run/nginx-socket-proxy/continuwuity"
          ];
          socketConfig = {
            SocketUser = config.systemd.services.nginx.serviceConfig.User;
            SocketGroup = config.systemd.services.nginx.serviceConfig.Group;
            SocketMode = "0600";
          };
        };

        service = {
          bindsTo = [ "continuwuity.service" ];
          after = [ "continuwuity.service" ];
        };
        upstream = config.services.continuwuity.settings.global.unix_socket_path;
      };

      services.continuwuity = {
        enable = true;
        settings.global = {
          server_name = "gaysex.cloud";
          max_request_size = 1024 * 1024 * 1024;
          unix_socket_path = "/run/continuwuity/socket";
          chmod_socket = 600;
        };
      };
    };
}
