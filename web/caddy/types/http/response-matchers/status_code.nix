{ lib, config, ... }:
{
  caddy.lib.types.http.response-matcher.status_code =
    let
      class = lib.types.ints.between 1 5;
      code = lib.types.ints.between 100 599;
    in
    lib.types.listOf (lib.types.either code class);
}
