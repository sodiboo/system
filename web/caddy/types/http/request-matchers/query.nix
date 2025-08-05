{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.query = lib.types.attrsOf (lib.types.listOf lib.types.str);
}
