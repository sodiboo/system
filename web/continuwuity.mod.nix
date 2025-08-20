{
  oxygen =
    {
      lib,
      config,
      ...
    }:
    {
      reverse-proxy."gaysex.cloud".locations."/.well-known/matrix".socket =
        "/run/nginx-socket-proxy/continuwuity";
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
            # SocketUser = config.systemd.services.nginx.serviceConfig.User;
            # SocketGroup = config.systemd.services.nginx.serviceConfig.Group;
            SocketMode = "0600";
          };
        };

        service = {
          bindsTo = [ "continuwuity.service" ];
          after = [ "continuwuity.service" ];
        };
        upstream = config.services.continuwuity.settings.global.unix_socket_path;
      };

      # `lib.mkBefore` to ensure this route is ordered before sharkey
      caddy.sites."gaysex.cloud".routes = lib.mkBefore [
        {
          match = [
            {
              path = [
                "/.well-known/matrix"
                "/.well-known/matrix/*"
                "/_matrix"
                "/_matrix/*"
              ];
            }
          ];
          terminal = true;
          handle = [
            {
              handler = "subroute";
              routes = [
                {
                  handle = [
                    {
                      handler = "reverse_proxy";
                      upstreams = [ { dial = "unix/@continuwuity"; } ];
                    }
                  ];
                }
              ];

              errors.routes = [
                {
                  match = [
                    {
                      vars."{http.error.status_code}" = [ "502" ];
                      path = [
                        "/_matrix"
                        "/_matrix/*"
                      ];
                    }
                  ];
                  terminal = true;
                  handle = [
                    {
                      handler = "static_response";
                      status_code = "502";
                      body = builtins.toJSON {
                        errcode = "M_UNKNOWN";
                        error = "Backend is unreachable";
                      };
                    }
                  ];
                }
                {
                  terminal = true;
                  handle = [
                    {
                      handler = "static_response";
                      status_code = "{http.error.status_code}";
                    }
                  ];
                }
              ];
            }
          ];
        }
      ];

      systemd-socket-proxyd.continuwuity-caddy = {
        socket = {
          requiredBy = [ "caddy.service" ];
          listenStreams = [ "@continuwuity" ];
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
          unix_socket_perms = 666;

          well_known = {
            client = "https://gaysex.cloud";
            server = "gaysex.cloud:443";
          };
        };
      };
    };
}
