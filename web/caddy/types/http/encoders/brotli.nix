{ lib, config, ... }:
{
  caddy.lib.types.http.precompressed.br = lib.types.submodule { };
}
