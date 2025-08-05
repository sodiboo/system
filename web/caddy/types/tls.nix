{ lib, config, ... }:
{
  caddy.lib.types.apps.tls = config.caddy.lib.types.sparse-submodule {
    options = {
      certificates = lib.mkOption { type = config.caddy.lib.types.tls.certificates; };

      automation = {
        on_demand.permission = lib.mkOption { type = config.caddy.lib.types.tls.permission; };

        policies = lib.mkOption {
          type = lib.types.listOf config.caddy.lib.types.tls.automation-policy;
        };
      };

      cache.capacity = lib.mkOption { type = lib.types.ints.positive; };
    };
  };
}
