{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.header_regexp =
    lib.types.attrsOf config.caddy.lib.types.regexp;
}
