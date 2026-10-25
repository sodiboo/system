{
  lib,
  stdenv,
  runCommand,
  symlinkJoin,
  makeWrapper,

  jq,
  rsync,

  nodejs_26,
  nodejs-slim_26,
  pnpm_11,
  pnpmConfigHook,
  electron_44,

  cargo,
  rustc,
  fetchCrate,
  rustPlatform,

  pkg-config,
  clang,
  lld,

  zstd,

  buildWasmBindgenCli,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  excludeDrvArgNames = [ "native-addons" ];

  extendDrvArgs =
    finalAttrs:
    args@{
      build-channel,
      markdown-parser-wasm,
      libfluxcore,
      libfluxwebp,
      ...
    }:

    let
      inherit (finalAttrs)
        nodejs
        pnpm
        ;
    in
    {
      fluxer-component = "fluxer-app-desktop-renderer-${build-channel}";
      update-script = null;
      nodejs = args.nodejs or nodejs_26;
      pnpm = args.pnpm or (pnpm_11.override { nodejs-slim = nodejs; });

      passthru = {
        inherit libfluxcore libfluxwebp markdown-parser-wasm;
      }
      // args.passthru or { };

      patches = [
        ../fluxer-ci-binary-in-desktop-build-js.patch
        ./app-dont-build-wasm-stuff.patch
      ]
      ++ args.patches or [ ];

      nativeBuildInputs = [
        makeWrapper
        nodejs
        pnpm
        pnpmConfigHook
        cargo
        rustc
        clang.cc
        lld
        rustPlatform.cargoSetupHook
        # electron
      ]
      ++ args.nativeBuildInputs or [ ];

      buildInputs = [
        zstd
      ]
      ++ args.buildInputs or [ ];

      env = {
        npm_config_nodedir = nodejs;
      }
      // args.env or { };

      preBuild = ''
        (
          cd fluxer_app

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

        (
          cd fluxer_desktop

          fluxer-ci build-desktop --step update_version
          fluxer-ci build-desktop --step set_build_channel
        )
      '';

      buildPhase = ''
        runHook preBuild

        (
          cd fluxer_desktop
          
          fluxer-ci build-desktop --step build_shared_assets
        )

        runHook postBuild
      '';

      installPhase = ''
        cp -r fluxer_desktop/dist/renderer $out
      '';

      meta = {
        description = "A free and open source instant messaging and VoIP chat app";
        license = lib.licenses.agpl3Plus;
        homepage = "https://github.com/fluxerapp/fluxer";
        maintainers = with lib.maintainers; [ sodiboo ];
      }
      // args.meta or { };
    };

}
