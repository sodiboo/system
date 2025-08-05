{ lib, config, ... }:
{
  caddy.lib.types.tls.handshake-matcher.sni_regexp = config.caddy.lib.types.regexp;
}
