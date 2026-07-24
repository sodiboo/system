{
  oxygen =
    { lib, config, ... }:
    {
      caddy.sites."loft.computers.gay".routes = [
        {
          terminal = true;
          handle = [
            {
              handler = "reverse_proxy";
              upstreams = [
                { dial = "${config.services.atticd.settings.listen}"; }
              ];
            }
          ];
        }
      ];

      sops.secrets."attic-server-token" = { };

      sops.templates.atticd-env.content = ''
        ATTIC_SERVER_TOKEN_RS256_SECRET_BASE64="${config.sops.placeholder.attic-server-token}"
      '';

      services.atticd = {
        enable = true;

        environmentFile = config.sops.templates.atticd-env.path;

        settings = {
          listen = "127.0.0.1:2588";
          database.url = "postgresql://atticd@localhost/atticd?host=/run/postgresql";
        };
      };

      services.postgresql.ensureDatabases = [ "atticd" ];
      services.postgresql.ensureUsers = [
        {
          name = "atticd";
          ensureDBOwnership = true;
        }
      ];
    };
}
