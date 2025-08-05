{ lib, config, ... }:
{
  options.caddy.lib.types.tls.connection-policy = lib.mkOption { type = lib.types.optionType; };
  config.caddy.lib.types.tls.connection-policy = config.caddy.lib.types.sparse-submodule {
    options = {
      match = lib.mkOption { type = config.caddy.lib.types.tls.handshake-matcher; };
      cipher_suites = lib.mkOption { type = lib.types.listOf lib.types.str; };
      curves = lib.mkOption { type = lib.types.listOf lib.types.str; };
      alpn = lib.mkOption { type = lib.types.listOf lib.types.str; };
      protocol_min = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      protocol_max = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      default_sni = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
    };
  };
}
