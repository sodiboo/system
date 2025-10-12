{ lib, config, ... }:
{
  caddy.lib.types.tls.certificates.load_pem = lib.types.listOf (config.caddy.lib.types.sparse-submodule {
    options = {
      certificate = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
      key = config.caddy.lib.mkRequiredOption { type = config.caddy.lib.types.secret; };
      tags = lib.mkOption { type = lib.types.listOf lib.types.str; };
    };
  });
}
