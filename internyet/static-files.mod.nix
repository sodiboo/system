{
  nitrogen =
    { lib, pkgs, ... }:
    {
      options.caddy.lib.static-response-file = lib.mkOption { readOnly = true; };
      config.caddy.lib.static-response-file =
        {
          status ? 200,
          root,
          path,
          extraFormats ? [ ],
        }:
        [
          {
            handler = "rewrite";
            uri = "/${path}";
          }
          {
            handler = "headers";
            response = {
              deferred = true;
              delete = [ "Last-Modified" ];
            };
          }
          {
            handler = "file_server";
            root = toString (
              pkgs.compressDrvWeb root {
                inherit extraFormats;
              }
            );

            status_code = toString status;

            precompressed = {
              br = { };
              gzip = { };
              zstd = { };
            };

            precompressed_order = [
              "br"
              "gzip"
              "zstd"
            ];
          }
        ];

      options.caddy.lib.handle-static-files = lib.mkOption { readOnly = true; };
      config.caddy.lib.handle-static-files =
        {
          extraFormats ? [ ],
          content,
        }:
        let
          compressed = pkgs.compressDrvWeb content {
            inherit extraFormats;
          };
          with-etags =
            let
              hash = pkgs.writeScript "hash" ''
                echo -n "\"$(sha256sum $1 | head -c 64)\"" > $1.hash
              '';
            in
            pkgs.compressDrvWeb compressed {
              extraFormats = extraFormats ++ [
                "br"
                "gz"
                "zst"
              ];

              compressors.hash = "${hash} {}";
            };
        in
        [
          {
            handler = "headers";
            response = {
              deferred = true;
              # unix epoch because it's in nix store.
              delete = [ "Last-Modified" ];
            };
          }
          {
            handler = "file_server";
            root = "${with-etags}";

            # these are sidecar files. don't expose them as real URLs to request.
            hide = [
              "*.br"
              "*.zst"
              "*.gz"
              "*.hash"
            ];

            precompressed = {
              br = { };
              gzip = { };
              zstd = { };
            };

            precompressed_order = [
              "br"
              "gzip"
              "zstd"
            ];

            etag_file_extensions = [ ".hash" ];
          }
        ];
    };
}
