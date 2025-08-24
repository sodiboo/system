{
  oxygen =
    {
      lib,
      config,
      ...
    }:
    {
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

      systemd-socket-proxyd.continuwuity = {
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
