{ lib, config, ... }:
{
  caddy.lib.types.http.request-matcher.file = config.caddy.lib.types.sparse-submodule {
    options = {
      fs = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      root = lib.mkOption { type = config.caddy.lib.types.nonempty-str; };
      try_files = lib.mkOption { type = lib.types.listOf lib.types.str; };
      try_policy = lib.mkOption {
        type = lib.types.enum [
          "first_exist"
          "first_exist_fallback"
          "largest_size"
          "smallest_size"
          "most_recently_modified"
        ];
      };
      split_path = lib.mkOption { type = lib.types.listOf lib.types.str; };
    };
  };
}
