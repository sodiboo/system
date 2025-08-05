{ lib, config, ... }:
{
  caddy.lib.types.storage.file_system = lib.types.submodule {
    options = {
      module = lib.mkOption { type = lib.types.enum [ "file_system" ]; };
      root = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
    };
  };
}
