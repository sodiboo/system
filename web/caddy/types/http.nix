{ lib, config, ... }:
let
  nonzero-port = lib.types.addCheck lib.types.port (x: x != 0);
in
{
  caddy.lib.types.apps.http = config.caddy.lib.types.sparse-submodule {
    options = {
      http_port = lib.mkOption { type = nonzero-port; };
      https_port = lib.mkOption { type = nonzero-port; };

      grace_period = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      shutdown_delay = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };

      servers = lib.mkOption { type = lib.types.attrsOf config.caddy.lib.types.http.server; };
    };
  };
}
