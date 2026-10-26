{
  lib,
  callPackage,
  makeWrapper,

  nodejs_26,
  pnpm_11,
  pnpmConfigHook,

  cargo,
  rustc,
  rustPlatform,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  excludeDrvArgNames = [
    "libfluxcore"
    "libfluxwebp"
  ];

  extendDrvArgs =
    finalAttrs:
    args@{
      build-channel,
      libfluxcore,
      libfluxwebp,
      buildPhase,
      ...
    }:

    let

      inherit (finalAttrs)
        nodejs
        pnpm
        ;

      libflux-args =
        {
          src ? finalAttrs.src,
          version ? finalAttrs.version,
          ...
        }:
        {
          inherit src version;
        };

      inherit (finalAttrs) libfluxcore libfluxwebp markdown-parser-wasm;
    in
    {
      update-script = null;
      nodejs = args.nodejs or nodejs_26;
      pnpm = args.pnpm or (pnpm_11.override { nodejs-slim = nodejs; });

      libfluxcore = lib.extendMkDerivation {
        constructDrv = callPackage ./libfluxcore.nix { };
        extendDrvArgs = _: libflux-args;
      } args.libfluxcore;

      libfluxwebp = lib.extendMkDerivation {
        constructDrv = callPackage ./libfluxwebp.nix { };
        extendDrvArgs = _: libflux-args;
      } args.libfluxwebp;

      markdown-parser-wasm = callPackage ./markdown-parser.nix { } {
        inherit (finalAttrs) src version cargoDeps;
      };

      postUnpack = ''
        (
          cd source/fluxer_app

          ln -s ${libfluxcore} pkgs/libfluxcore
          ln -s ${libfluxwebp} pkgs/libfluxwebp

          ${
            let
              markdown-template = builtins.toFile "MarkdownParserWasmBytes.ts" ''
                // SPDX-License-Identifier: AGPL-3.0-or-later

                export const MARKDOWN_PARSER_WASM_BASE64 =
                  '@sentinel@';
              '';
            in
            ''
              substitute ${markdown-template} src/features/messaging/utils/markdown/parser/MarkdownParserWasmBytes.ts \
                --replace-fail '@sentinel@' "$(base64 -w0 ${markdown-parser-wasm})"
            ''
          }
        )

        ${args.postUnpack or ""}
      '';

      postPatch = ''
        substituteInPlace fluxer_app/package.json ${
          lib.escapeShellArgs [
            "--replace-fail"
            ''"wasm:codegen": "../tools/ci/run.sh build-app-wasm"''
            ''"wasm:codegen": "true"''
          ]
        }

        ${args.postPatch or ""}
      '';

      nativeBuildInputs = [
        makeWrapper
        nodejs
        pnpm
        pnpmConfigHook
        cargo
        rustc
        rustPlatform.cargoSetupHook
      ]
      ++ args.nativeBuildInputs or [ ];

      env = {
        npm_config_nodedir = nodejs;
      }
      // args.env or { };

      meta = {
        description = "A free and open source instant messaging and VoIP chat app";
        license = lib.licenses.agpl3Plus;
        homepage = "https://github.com/fluxerapp/fluxer";
        maintainers = with lib.maintainers; [ sodiboo ];
      }
      // args.meta or { };
    };

}
