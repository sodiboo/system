{ picocss, ... }:
{
  oxygen =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      content = pkgs.runCommandNoCC "personal-website-content" { } ''
        cp -r ${./sodi.boo/public} $out
        chmod +w $out
        cp -r ${picocss}/css $out/css
      '';
    in
    {
      caddy.sites."sodi.boo".routes = [
        {
          match = [ { path = [ "/.well-known/discord" ]; } ];
          terminal = true;
          handle = [
            {
              handler = "static_response";
              body = builtins.readFile ./sodi.boo/discord-domain-verification;
            }
          ];
        }
        {
          match = [
            {
              file = {
                root = "${content}";
                try_files = [
                  "{http.request.uri.path}.html"
                  "{http.request.uri.path}/"
                  "{http.request.uri.path}"
                ];
              };
            }
          ];
          handle = [
            {
              handler = "rewrite";
              uri = "{http.matchers.file.relative}";
            }
          ];
        }
        {
          terminal = true;
          handle = config.caddy.lib.handle-static-files {
            extraFormats = [ "atom" ];
            inherit content;
          };
        }
      ];

      caddy.sites."sodi.gay".routes = [
        {
          terminal = true;
          handle = [
            {
              handler = "static_response";
              status_code = "308";
              headers.Location = [ "https://sodi.boo{http.request.orig_uri}" ];
            }
          ];
        }
      ];
    };
}
