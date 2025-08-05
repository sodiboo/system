{ lib, config, ... }:
{
  caddy.lib.types.dns.provider.acmedns = config.caddy.lib.types.sparse-submodule {
    options = {
      name = config.caddy.lib.mkRequiredOption { type = lib.types.enum [ "acmedns" ]; };

      username = config.caddy.lib.mkRequiredOption { type = config.caddy.lib.types.secret; };
      password = config.caddy.lib.mkRequiredOption { type = config.caddy.lib.types.secret; };
      subdomain = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
      server_url = config.caddy.lib.mkRequiredOption { type = lib.types.str; };

      config = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              username = lib.mkOption { type = config.caddy.lib.types.secret; };
              password = lib.mkOption { type = config.caddy.lib.types.secret; };
              subdomain = lib.mkOption { type = lib.types.str; };
              fulldomain = lib.mkOption { type = lib.types.str; };
              server_url = lib.mkOption { type = lib.types.str; };
            };
          }
        );
      };
    };
  };
}
