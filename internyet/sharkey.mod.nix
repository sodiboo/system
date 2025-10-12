{
  nitrogen =
    {
      pkgs,
      config,
      ...
    }:
    {
      caddy.sites."social.sodiboo.p.nyet".routes = [
        {
          terminal = true;
          handle = [
            {
              handler = "subroute";
              routes = [
                {
                  handle = [
                    {
                      handler = "reverse_proxy";
                      upstreams = [ { dial = "unix/@sharkey"; } ];
                    }
                  ];
                }
              ];

              errors.routes = [
                {
                  match = [
                    {
                      vars."{http.error.status_code}" = [ "502" ];
                      path = [ "/api/*" ];
                    }
                  ];
                  terminal = true;
                  handle = [
                    {
                      handler = "static_response";
                      status_code = "502";
                      body = builtins.toJSON {
                        error = {
                          message = "Backend is unreachable";
                          code = "BAD_GATEWAY";
                          kind = "server";
                          id = "502 Bad Gateway"; # should be a uuid.
                        };
                      };
                    }
                  ];
                }
                {
                  match = [ { vars."{http.error.status_code}" = [ "502" ]; } ];
                  terminal = true;
                  handle = config.caddy.lib.serve-error-page 502 "social.sodiboo.p.nyet/502.html";
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

      systemd-socket-proxyd.sharkey = {
        connections-max = 4096;

        socket = {
          requiredBy = [ "caddy.service" ];
          listenStreams = [ "@sharkey" ];
        };

        service = {
          bindsTo = [ "sharkey.service" ];
          after = [ "sharkey.service" ];
        };
        upstream = config.services.sharkey.settings.socket;
      };

      services.sharkey = {
        enable = true;
        database.createLocally = true;
        redis.createLocally = true;
        # meilisearch.createLocally = true;
        settings = {
          id = "aidx";
          url = "https://social.sodiboo.p.nyet/";

          publishTarballInsteadOfProvideRepositoryUrl = true;

          socket = "/run/sharkey/socket";
          chmodSocket = "666";

          fulltextSearch.provider = "sqlLike";

          maxNoteLength = 8192;
          maxFileSize = 1024 * 1024 * 1024;

          allowedPrivateNetworks = [
            "10.13.36.0/22"
            "fc00::/64"
          ] ;

          signToActivityPubGet = true;
          CheckActivityPubGetSigned = false;
        };
      };

      systemd.services.sharkey.serviceConfig = {
        IPAddressAllow = [
          "10.13.36.0/22"
          "fc00::/64"
          "127.0.0.1/8"
          "::1/128"
        ];

        BindReadOnlyPaths = [
          "${builtins.toFile "resolv.conf" ''
            nameserver 10.13.37.1
            nameserver fc00::1337
          ''}:/etc/resolv.conf"
        ];
      };
    };
}
