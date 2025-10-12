{ lib, config, ... }:
{
  caddy.lib.types.tls.certificates.load_files = lib.types.listOf (config.caddy.lib.types.sparse-submodule {
    options = {
      certificate = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
      key = config.caddy.lib.mkRequiredOption { type = lib.types.str; };
      format = lib.mkOption { type = lib.types.str; };
      tags = lib.mkOption { type = lib.types.listOf lib.types.str; };
    };
  });
}
