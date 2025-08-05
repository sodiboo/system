{ lib, config, ... }:
{
  caddy.lib.types.tls.handshake-matcher.sni = lib.types.listOf lib.types.str;
}
