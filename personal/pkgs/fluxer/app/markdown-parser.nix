{
  lib,
  runCommand,
  makeWrapper,

  cargo,
  rustc,
  rustPlatform,

  clang,
  lld,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  extendDrvArgs =
    finalAttrs:
    args@{ ... }:
    {
      fluxer-component = "fluxer-markdown-parser.wasm";
      version = null;

      fluxer-ci = null;

      update-script = null;

      nativeBuildInputs = [
        makeWrapper
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

      meta = {
        description = "A free and open source instant messaging and VoIP chat app";
        license = lib.licenses.agpl3Plus;
        homepage = "https://github.com/fluxerapp/fluxer";
        maintainers = with lib.maintainers; [ sodiboo ];
      }
      // args.meta or { };
    };

}
