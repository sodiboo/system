{
  lib,
  clangStdenv,
  makeWrapper,

  jq,

  cargo,
  rustc,
  fetchCrate,
  rustPlatform,

  clang,
  lld,

  zstd,

  buildWasmBindgenCli,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation.override {
    stdenv = clangStdenv;
  };

  extendDrvArgs =
    finalAttrs:
    args@{ ... }:
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
    in
    {
      fluxer-component = "libfluxcore";
      version = null;
      fluxer-ci = null;
      update-script = null;

      cargoRoot = "fluxer_app/rust/libfluxcore";

      nativeBuildInputs = [
        makeWrapper
        cargo
        rustc
        clang.cc
        lld
        rustPlatform.cargoSetupHook
        wasm-bindgen-cli
        jq
      ];

      buildInputs = [
        zstd
      ];

      buildPhase = ''
        (
          cd fluxer_app/rust/libfluxcore

          cargo build --release --target wasm32-unknown-unknown

        )
      '';

      installPhase =
        let
          spdx-header = "SPDX-License-Identifier: AGPL-3.0-or-later";
          spdx-header-js = builtins.toFile "spdx-agpl-header.js" ''
            // SPDX-License-Identifier: AGPL-3.0-or-later
          '';
        in
        ''
          wasm-bindgen --target web --out-dir $out --out-name "libfluxcore" \
            fluxer_app/rust/libfluxcore/target/wasm32-unknown-unknown/release/libfluxcore.wasm
          (
            cd $out

            ${builtins.concatStringsSep "\n" (
              map
                (
                  {
                    marker,
                    reset-export,
                    raw,
                    out,
                  }:
                  ''
                    substituteInPlace ${raw} ${
                      lib.escapeShellArgs [
                        "--replace-fail"
                        marker
                        ("${reset-export}${marker}")
                      ]
                    }

                    cat ${spdx-header-js} ${raw} > ${out}
                    rm ${raw}
                  ''
                )
                [
                  {
                    raw = "libfluxcore.js";
                    out = "libfluxcore_bindgen.js";
                    marker = "async function __wbg_load(module, imports) {";
                    reset-export = ''
                      export function __resetLibfluxcoreWasmForMemoryPressure() {
                          wasmModule = undefined;
                          wasmInstance = undefined;
                          wasm = undefined;
                          cachedDataViewMemory0 = null;
                          cachedUint8ArrayMemory0 = null;
                          heap = new Array(1024).fill(undefined);
                          heap.push(undefined, null, true, false);
                          heap_next = heap.length;
                          numBytesDecoded = 0;
                      }
                    '';
                  }
                  {
                    raw = "libfluxcore.d.ts";
                    out = "libfluxcore_bindgen.d.ts";
                    marker = "export type InitInput";
                    reset-export = ''
                      export function __resetLibfluxcoreWasmForMemoryPressure(): void;
                    '';
                  }
                ]
              ++ [
                (
                  let
                    libfluxcore-index = builtins.toFile "libfluxcore.js" ''
                      // ${spdx-header}


                      export * from './libfluxcore_bindgen.js';
                      export {default} from './libfluxcore_bindgen.js';
                    '';

                    package-json = {
                      "name" = "libfluxcore";
                      "private" = true;
                      "type" = "module";
                      "version" = "0.0.0";
                      "license" = "AGPL-3.0-or-later";
                      "sideEffects" = false;
                      "files" = [
                        "libfluxcore.js"
                        "libfluxcore.d.ts"
                        "libfluxcore_bindgen.js"
                        "libfluxcore_bindgen.d.ts"
                        "libfluxcore_bg.wasm"
                        "libfluxcore_bg.wasm.d.ts"
                        "README.md"
                      ];
                      "main" = "libfluxcore.js";
                      "module" = "libfluxcore.js";
                      "types" = "libfluxcore.d.ts";
                      "exports" = {
                        "." = {
                          "types" = "./libfluxcore.d.ts";
                          "default" = "./libfluxcore.js";
                        };
                        "./libfluxcore_bg.wasm" = "./libfluxcore_bg.wasm";
                      };
                    };
                  in
                  ''
                    cp ${libfluxcore-index} libfluxcore.js
                    cp ${libfluxcore-index} libfluxcore.d.ts
                    cat ${builtins.toFile "package.json" (builtins.toJSON package-json)} | jq '.' > package.json
                    cp ${builtins.toFile "README.md" ''
                      <!-- ${spdx-header} -->
                      # libfluxcore

                      Rust WebAssembly helpers for Fluxer media processing.
                    ''} README.md
                  ''
                )
              ]
            )}
          )
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
