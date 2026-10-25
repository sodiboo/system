{
  lib,
  clangStdenv,
  stdenvNoCC,
  runCommand,
  symlinkJoin,
  makeWrapper,

  jq,
  rsync,

  nodejs_26,
  nodejs-slim_26,
  pnpm_11,
  fetchPnpmDeps,
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
let

  wasm-bindgen-cli = buildWasmBindgenCli rec {
    src = fetchCrate {
      pname = "wasm-bindgen-cli";
      version = "0.2.128";
      hash = "sha256-a7lcXJnnZkYReja+iUO7NqqrWyv3toxnUgQb8s4IS5s=";
    };

    cargoDeps = rustPlatform.fetchCargoVendor {
      inherit src;
      inherit (src) pname version;
      hash = "sha256-R1Tas33Ursy8kqsxguAkG0ZhNed2n5uFTAhw1l2qlLY=";
    };
  };

  libfluxwebp-variant = lib.extendMkDerivation {
    constructDrv = make-fluxer-derivation.override {
      stdenv = clangStdenv;
    };

    excludeDrvArgNames = [
      "cflags"
      "rustflags"
    ];

    extendDrvArgs =
      finalAttrs:
      args@{
        cflags ? [ ],
        rustflags ? [ ],
        ...
      }:
      {
        fluxer-ci = null;
        update-script = null;

        nativeBuildInputs = [
          makeWrapper
          cargo
          rustc
          clang.cc
          lld
          rustPlatform.cargoSetupHook
          wasm-bindgen-cli
          jq
        ]
        ++ args.nativeBuildInputs or [ ];

        buildInputs = [
          zstd
        ]
        ++ args.buildInputs or [ ];

        env = {
          CFLAGS_wasm32_unknown_unknown = builtins.concatStringsSep " " cflags;
          CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_RUSTFLAGS = builtins.concatStringsSep " " rustflags;
        }
        // args.env or { };

        buildPhase = ''
          (
            cd fluxer_app/rust/libfluxwebp

            cargo build --release --target wasm32-unknown-unknown
          )
        '';

        installPhase = ''
          wasm-bindgen --target web --out-dir $out --out-name "libfluxwebp" \
            fluxer_app/rust/libfluxwebp/target/wasm32-unknown-unknown/release/libfluxwebp.wasm
        '';

        meta = {
          description = "A free and open source instant messaging and VoIP chat app";
          license = lib.licenses.agpl3Plus;
          homepage = "https://github.com/fluxerapp/fluxer";
          maintainers = with lib.maintainers; [ sodiboo ];
        }
        // args.meta or { };
      };
  };

in
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation.override {
    stdenv = stdenvNoCC;
  };

  extendDrvArgs =
    finalAttrs:
    args@{ ... }:
    {
      fluxer-component = "libfluxwebp";
      version = null;
      fluxer-ci = null;
      update-script = null;

      cargoRoot = "fluxer_app/rust/libfluxwebp";

      libfluxwebp-simd = libfluxwebp-variant {
        fluxer-component = "${finalAttrs.fluxer-component}-simd";
        inherit (finalAttrs)
          src
          version
          cargoRoot
          cargoDeps
          ;
        cflags = [
          "-isystem ${finalAttrs.src}/fluxer_app/rust/libfluxwebp/shim"
          "-isystem ${finalAttrs.src}/fluxer_app/rust/libfluxwebp/simd"
          "-msimd128"
          "-DEMSCRIPTEN"
          "-D__SSE__"
          "-D__SSE2__"
          "-DWEBP_HAVE_SSE2"
          "-DNDEBUG"
          "-O3"
        ];
        rustflags = [
          "-C target-feature=+simd128"
        ];
      };

      libfluxwebp-scalar = libfluxwebp-variant {
        fluxer-component = "${finalAttrs.fluxer-component}-scalar";
        inherit (finalAttrs)
          src
          version
          cargoRoot
          cargoDeps
          ;
        cflags = [
          "-isystem ${finalAttrs.src}/fluxer_app/rust/libfluxwebp/shim"
          "-Oz"
        ];
      };

      dontBuild = true;

      installPhase =
        let
          inherit (finalAttrs) libfluxwebp-simd libfluxwebp-scalar;

          spdx-header = "SPDX-License-Identifier: AGPL-3.0-or-later";
          spdx-header-js = builtins.toFile "spdx-agpl-header.js" ''
            // ${spdx-header}
          '';
        in
        ''
          ${builtins.concatStringsSep "\n" (
            map
              (f: ''
                if [[ "$(cat ${libfluxwebp-simd}/${f} | sha256sum)" != "$(cat ${libfluxwebp-scalar}/${f} | sha256sum)" ]]; then
                  echo "libfluxwebp scalar glue ${f} differs from the simd build"
                  sha256sum ${libfluxwebp-simd}/${f} ${libfluxwebp-scalar}/${f}
                  exit 1
                fi
              '')
              [
                "libfluxwebp.js"
                "libfluxwebp.d.ts"
                "libfluxwebp_bg.wasm.d.ts"
              ]
          )}

          mkdir $out
          cd $out

          cat ${spdx-header-js} ${libfluxwebp-simd}/libfluxwebp.js > libfluxwebp.js
          cat ${spdx-header-js} ${libfluxwebp-simd}/libfluxwebp.d.ts > libfluxwebp.d.ts

          cp ${libfluxwebp-simd}/libfluxwebp_bg.wasm libfluxwebp_simd_bg.wasm
          cp ${libfluxwebp-simd}/libfluxwebp_bg.wasm.d.ts libfluxwebp_simd_bg.wasm.d.ts

          cp ${libfluxwebp-scalar}/libfluxwebp_bg.wasm libfluxwebp_bg.wasm
          cp ${libfluxwebp-scalar}/libfluxwebp_bg.wasm.d.ts libfluxwebp_bg.wasm.d.ts
        '';
    };
}
