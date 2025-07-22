{
  lib,
  runCommandLocal,
  jq,
  makeWrapper,
  sharkey,
  nodejs,
}:

runCommandLocal "sharkey-precise-${sharkey.version}"
  {

    nativeBuildInputs = [
      jq
      makeWrapper
    ];

    outputs = [
      "out"
      "typeorm"
    ];

    # This package serves to replace the following scripts.
    # As such, it is important that the package.json files contain the expected scripts.
    # If they change, this package must be updated.

    ensure_toplevel = builtins.toJSON {
      "scripts" = {
        "check:connect" = "pnpm --filter backend check:connect";
        "migrate" = "pnpm --filter backend migrate";
        "revert" = "pnpm --filter backend revert";
        "migrateandstart" = builtins.concatStringsSep " && " [
          "pnpm migrate"
          "pnpm start"
        ];
        "start" = builtins.concatStringsSep " && " [
          "pnpm check:connect"
          "cd packages/backend"
          "MK_WARNED_ABOUT_CONFIG=true node ./built/boot/entry.js"
        ];
      };
    };
    ensure_backend = builtins.toJSON {
      "scripts" = {
        "migrate" = "pnpm typeorm migration:run -d ormconfig.js";
        "revert" = "pnpm typeorm migration:revert -d ormconfig.js";
        "check:connect" = "node ./scripts/check_connect.js";
      };
    };

    ensure_typeorm = builtins.toJSON {
      "bin" = {
        "typeorm" = "./cli.js";
      };
    };

    jqCheck = ''
      [

      $expected | path(.. | scalars) as $path |

      if ($actual | getpath($path)) == ($expected | getpath($path))
      then
        empty
      else
        {
          path: $path,
          actual: $actual | getpath($path),
          expected: $expected | getpath($path),
        }
      end

      ] | select (length > 0) |

      "

      package assertions failed in \($filename):\n\(map("
        at \(.path | map(".[\(tojson)]") | join("")):
          expected: \(.expected | tojson),
          found: \(.actual | tojson)
      ") | join(""))


      " | halt_error
    '';

    sharkey = "${sharkey}/Sharkey";

    node = lib.getExe nodejs;
  }
  ''
    verify() {
      jq -n "$jqCheck" --argjson expected "$1" --arg filename "$2" --argjson actual "$(cat "$2")"
    }

    verify "$ensure_toplevel" "$sharkey/package.json"
    verify "$ensure_backend" "$sharkey/packages/backend/package.json"
    verify "$ensure_typeorm" "$sharkey/packages/backend/node_modules/typeorm/package.json"

    mkdir -p $out/bin
    mkdir -p $typeorm/bin

    makeWrapper $node $typeorm/bin/typeorm \
      --add-flags "$sharkey/packages/backend/node_modules/typeorm/cli.js --"

    makeWrapper $typeorm/bin/typeorm $out/bin/sharkey-migrate \
      --set-default NODE_ENV production \
      --add-flags "migration:run -d $sharkey/packages/backend/ormconfig.js"

    makeWrapper $typeorm/bin/typeorm $out/bin/sharkey-revert \
      --set-default NODE_ENV production \
      --add-flags "migration:revert -d $sharkey/packages/backend/ormconfig.js"

    makeWrapper $node $out/bin/sharkey-start \
      --set-default NODE_ENV production \
      --add-flags "$sharkey/packages/backend/built/boot/entry.js"
  ''
