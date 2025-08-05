{ lib, config, ... }:
{
  caddy.lib.types.tls.certificates.automate = lib.types.listOf lib.types.str;
}
