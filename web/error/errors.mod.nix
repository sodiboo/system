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
      error-pages =
        pkgs.runCommandNoCC "error-pages"
          {
            nativeBuildInputs = [ pkgs.pandoc ];
          }
          ''
            mkdir $out
            ${builtins.concatStringsSep "\n" (
              let
                root = "${./pages}";
                files = lib.filesystem.listFilesRecursive root;
              in
              map (
                file:
                let
                  file' = lib.removePrefix "${root}/" file;
                in
                ''
                  mkdir -p ${builtins.dirOf "$out/${file'}"}
                  pandoc --from gfm-gfm_auto_identifiers -i ${file} --to html --template ${./template.html} -o $out/${lib.removeSuffix ".md" file'}.html
                  sed -i -e 's#<br />#<br>#' $out/${lib.removeSuffix ".md" file'}.html
                  sed -i -e 's#<hr />#<hr>#' $out/${lib.removeSuffix ".md" file'}.html
                ''
              ) files
            )}
          '';
    in
    {
      imports = [
        {
          options.caddy.lib.serve-error-page = lib.mkOption { readOnly = true; };
        }
      ];

      caddy.sites."static.sodi.boo".routes = [
        {
          terminal = true;
          handle = config.caddy.lib.handle-static-files {
            content = pkgs.runCommandNoCC "static-resources" { } ''
              mkdir $out
              cp -r ${picocss}/css $out/css
              cp ${./error.css} $out/error.css
            '';
          };
        }
      ];

      caddy.lib.serve-error-page =
        status: path:
        config.caddy.lib.static-response-file {
          root = error-pages;
          inherit status path;
        };

      caddy.routes.unknown = [
        {
          terminal = true;
          handle = config.caddy.lib.serve-error-page 418 "unknown.html";
        }
      ];
    };
}
