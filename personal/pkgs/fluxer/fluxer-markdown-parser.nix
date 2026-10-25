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

  extendDrvArgs =
    finalAttrs:
    args@{ ... }:
    {
      # nodejs = args.nodejs or nodejs_26;
      # pnpm = args.pnpm or (pnpm_11.override { nodejs-slim = nodejs; });
      # custom-deps = (
      #   map (addon: addon.cargoDeps.vendorStaging) (builtins.attrValues finalAttrs.passthru.native-addons)
      # );

      fluxer-component = "fluxer-markdown-parser.wasm";
      version = null;

      fluxer-ci = null;

      update-script = null;

      nativeBuildInputs = [
        makeWrapper
        # nodejs
        # pnpm
        # pnpmConfigHook
        cargo
        rustc
        clang.cc
        lld
        rustPlatform.cargoSetupHook
      ];

      buildPhase = ''
        (
          cd packages/markdown_parser/rust
          cargo build --release --target wasm32-unknown-unknown
        )
      '';

      installPhase = ''
        cp target/wasm32-unknown-unknown/release/fluxer_markdown_parser.wasm $out
      '';

      passthru = {
        base64-typescript =
          let
            template = builtins.toFile "fluxer-markdown-parser.wasm.base64.ts.template" ''
              // SPDX-License-Identifier: AGPL-3.0-or-later

              export const MARKDOWN_PARSER_WASM_BASE64 =
                '@sentinel@';
            '';
          in
          runCommand "fluxer-markdown-parser.wasm.base64.ts" { } ''
            substitute ${template} $out \
              --replace-fail '@sentinel@' "$(base ${finalAttrs.finalPackage})" 
          '';
      }
      // args.passthru or { };

      # buildInputs = [ zstd ];

      # env.npm_config_nodedir = nodejs;
      # env.BUNDLE_LOCAL_ASSETS = true;
      # preBuild = ''
      #   (
      #     cd fluxer_desktop
      #     fluxer-ci build-desktop --step update_version
      #     fluxer-ci build-desktop --step set_build_channel
      #   )
      # '';

      meta = {
        description = "A free and open source instant messaging and VoIP chat app";
        license = lib.licenses.agpl3Plus;
        homepage = "https://github.com/fluxerapp/fluxer";
        maintainers = with lib.maintainers; [ sodiboo ];
      }
      // args.meta or { };
    };

}
