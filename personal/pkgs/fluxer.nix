{
  lib,
  stdenv,
  runCommand,
  symlinkJoin,
  makeWrapper,
  fetchFromGitHub,

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

  buildWasmBindgenCli,

  lld,
  clang,
  pkg-config,

  openssl,
  libfido2,

  pipewire,

  udev,

  zstd,
}:
let
  pname = "fluxer-desktop";
  version = "2026.1017.133957";
  app-id = "app.fluxer.Fluxer";

  src = fetchFromGitHub {
    owner = "fluxerapp";
    repo = "fluxer";
    rev = "fluxer-desktop-stable@${version}";
    hash = "sha256-LG+zCRihq5u2T7wVvnMXNynsaNyN4rXfVBkwCz/rFVE=";
  };

  nodejs = nodejs_26;
  pnpm = pnpm_11.override { nodejs-slim = nodejs-slim_26; };
  electron = electron_44;

  pnpmDeps = fetchPnpmDeps {
    pname = "fluxer";
    inherit src;
    fetcherVersion = 4;
    hash = "sha256-mmkgT7nhZ7LiaLWrwO0zKxGMuSKURsPE6AN/lYl4sp4=";
  };

  root-cargoDeps = rustPlatform.fetchCargoVendor {
    name = "fluxer";
    inherit src;
    hash = "sha256-zE2nBLHrrESjOqKzAuPbl7F3FTh6QtO4rqyddRgykJc=";
  };

  native-addons =
    {
      webauthn = {
        nativeBuildInputs = [ rustPlatform.bindgenHook ];
        buildInputs = [
          openssl
          libfido2
        ];
        hash = "sha256-/YSjmYOUJqp9P68MgPsnuRf5pgYLItTWoaDeMu61xt8=";
      };
      hardware-encoder.hash = "sha256-GylpEE/JlVxrbeK62w5vDizbNfGq6mSO47wZHqGBR9Y=";
      app-store.hash = "sha256-NQsRJqlLDe6nf4msrVdTKiLtgFZHX/1Ys9xPIMwyW74=";
      gateway-socket.hash = "sha256-ZWntY3bcRx4PuLHV7aepdA6anPrW8USMtWo6kkvpebo=";
      linux-audio-capture = {
        nativeBuildInputs = [ rustPlatform.bindgenHook ];
        buildInputs = [ pipewire ];
        hash = "sha256-4cMvuI8juS8n4HtDkMk5ueXlFEldXvFrp7q70Pm8jRs=";
      };
      linux-portals.hash = "sha256-Ejilk90J72C946oyPPXafxBDZAgEqedUJFQ39pvqk1A=";
      linux-notifications.hash = "sha256-HpgpXzXqwBa2K3FIzUJVcJPpoLrd9UAruyrcYVhGSFU=";
      linux-evdev = {
        buildInputs = [ udev ];
        hash = "sha256-L7xUfohe4aOI555u2hzhf7SeTk6Pv2IdTYHaLx5CEVo=";
      };
      system-hunspell = {
        nativeBuildInputs = [ rustPlatform.bindgenHook ];
        hash = "sha256-UZiiU10RzU60jFooFaY82idN6vwTpMOY6pWLcdL1Cd0=";
      };
      linux-input-hook.hash = "sha256-aOSzf5YrPfxUYYs8xsEjFBRkBxZrewNh/2srpj6mdSw=";
      platform-info.hash = "sha256-qppRUj6Unyyswe4gNY4khwwBI+IAtbmMaUcrX3JW5B0=";
    }
    |> builtins.mapAttrs (
      addon:
      {
        nativeBuildInputs ? [ ],
        buildInputs ? [ ],
        hash,
      }:
      stdenv.mkDerivation ({
        name = "fluxer-desktop/${addon}";
        nativeBuildInputs = [
          cargo
          rustc
          fluxer-ci
          pkg-config
          rustPlatform.cargoSetupHook
        ]
        ++ nativeBuildInputs;
        inherit buildInputs;

        cargoRoot = "fluxer_desktop/native/${addon}";
        cargoDeps = rustPlatform.fetchCargoVendor {
          name = "fluxer-desktop/${addon}";
          cargoRoot = "fluxer_desktop/native/${addon}";
          inherit src hash;
        };

        inherit src;
        buildPhase = ''
          fluxer-ci build-desktop-native-addon --addon-root fluxer_desktop/native/${addon}
        '';

        installPhase = ''
          pkg_dir="$out/node_modules/$(cat fluxer_desktop/native/${addon}/package.json | ${lib.getExe jq} -r .name)"
          mkdir -p $pkg_dir
          cp --target-directory $pkg_dir fluxer_desktop/native/${addon}/{package.json,*.{js,cjs,ts,node}}
        '';
      })
    );

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

  copyVendorDeps =
    deps:
    ''cp -r --no-clobber --no-preserve=mode "${deps}/source-registry-0/." "$out/source-registry-0/"'';
  mergeVendorDeps =
    root-dep: extra-dep-list:
    runCommand "merge-vendor-deps" { } ''
      mkdir -p $out

      cp -r --no-preserve=mode "${root-dep}/." "$out/"

      ${lib.join "\n" (lib.map copyVendorDeps extra-dep-list)}
    '';

  fluxer-ci = rustPlatform.buildRustPackage {
    name = "fluxer-ci";
    inherit src;
    buildAndTestSubdir = "tools/ci";
    cargoDeps = root-cargoDeps;

    meta.mainProgram = "fluxer-ci";
  };
in
stdenv.mkDerivation (finalAttrs: {
  inherit pname src version;
  patches = [
    ./fluxer-ci-binary-in-desktop-build-js.patch

    # by default, the build scripts assert that glibc dependency is <= what Ubuntu ships, and that anything not installed on Ubuntu by default (libfido2) must be included.
    # but neither of these constraints are relevant in Nix; the fluxer modules will statically refer to a compatible glibc and libfido2 by construction; they cannot be missing at runtime.
    ./dont-assert-abi-compatibility.patch
  ];

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
    fluxer-ci
    wasm-bindgen-cli
    electron
  ];

  buildInputs = [
    zstd
  ];

  passthru = {
    inherit native-addons;
  };

  env.npm_config_nodedir = nodejs;
  env.BUNDLE_LOCAL_ASSETS = true;

  postPatch = ''
    patchShebangs --build tools/ci/run.sh
  '';

  preBuild = ''
    (
      cd fluxer_desktop
      echo "version is: $version"
      pnpm version $version --no-git-tag-version --allow-same-version
    )
  '';

  inherit pnpmDeps;
  cargoDeps = mergeVendorDeps root-cargoDeps [
    (rustPlatform.fetchCargoVendor {
      name = "libfluxcore";
      cargoRoot = "fluxer_app/rust/libfluxcore";
      inherit src;
      hash = "sha256-n9hA0WaUyYpXV9ply8QwUgq4NvmBERIebrfzz2lCd/A=";
    })
    (rustPlatform.fetchCargoVendor {
      name = "libfluxwebp";
      cargoRoot = "fluxer_app/rust/libfluxwebp";
      inherit src;
      hash = "sha256-zz5JD3jiNCx8FOReZmCm4O2F20s7UbMsfZIM2sIcSS0=";
    })
  ];

  env.FLUXER_SKIP_NATIVE = "true";
  env.FLUXER_CI_BIN = lib.getExe fluxer-ci;

  env.ELECTRON_ARCH = "x64";

  buildPhase = ''
    runHook preBuild

    (
      cd fluxer_desktop
      pnpm build

      cp -r ${electron.dist} electron-dist
      chmod -R +w electron-dist

      ${lib.getExe rsync} --chmod=+w -Lr ${
        symlinkJoin {
          name = "fluxer-desktop-native-addons";
          paths = builtins.attrValues native-addons;
        }
      }/ .

      pnpm exec electron-builder \
        --dir --linux --x64 \
        -c.electronDist=electron-dist \
        -c.electronVersion=${electron.version} \
        --config electron-builder.config.cjs
    )


    runHook postBuild
  '';

  installPhase = ''
    mkdir -p $out/share/${app-id}
    cp -t $out/share/${app-id} -r ./fluxer_desktop/dist-electron/linux-unpacked/resources/*

    mkdir -p $out/bin
    makeWrapper ${lib.getExe electron} $out/bin/fluxer-desktop \
      --add-flags "$out/share/${app-id}/app.asar"

    (
      cd fluxer_desktop/packaging/linux
      substituteInPlace ${app-id}.desktop \
        --replace-fail "Exec=${app-id}" "Exec=$out/bin/fluxer-desktop"

      install -Dm444 ${app-id}.desktop $out/share/applications/${app-id}.desktop
      install -Dm444 ${app-id}.metainfo.xml $out/share/metainfo/${app-id}.metainfo.xml

      install -Dm444 ${app-id}.svg $out/share/icons/hicolor/scalable/apps/${app-id}.svg
    )

    for size in 16 24 32 48 64 128 256 512; do
      install -Dm644 fluxer_desktop/dist-electron/linux-unpacked/resources/icons/"$size"x"$size".png \
        $out/share/icons/hicolor/"$size"x"$size"/apps/${app-id}.png
    done
  '';

  meta = {
    description = "A free and open source instant messaging and VoIP chat app";
    license = lib.licenses.agpl3Plus;
    homepage = "https://github.com/fluxerapp/fluxer";
    mainProgram = "fluxer-desktop";
    maintainers = with lib.maintainers; [ sodiboo ];
  };
})
