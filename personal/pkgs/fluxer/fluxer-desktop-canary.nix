{
  lib,
  fetchPnpmDeps,
  rustPlatform,

  openssl,
  libfido2,

  pipewire,

  udev,

  fetch-fluxer-source,
  make-fluxer-desktop,
  make-fluxer-desktop-electron-bin,
  fluxer-update-script,
}:
make-fluxer-desktop (finalAttrs: {
  fluxer-component = "fluxer-desktop-canary";
  version = "2026.1018.223341";

  build-channel = "canary";
  app-id = "app.fluxer.FluxerCanary";
  meta.mainProgram = "fluxer-desktop-canary";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-ir92ASsYrcdxXoXFTcvzrjVznW0nO5r/lD8VtFO3iJU=";
  };

  electron = make-fluxer-desktop-electron-bin {
    version = "44.9.1-fluxer.1";
    hashes = {
      linux-x64 = {
        archive = "ae36cae3dd723d94b414302598014beb6230a0c596ac6dc7a2dc95a6198a2568";
        manifest = "7eb2c5207392dc20e3a600b4608e1a9cdcbdfd0a9ad85a0b7f414906611733e9";
      };
      linux-arm64 = {
        achive = "b9160781a6f06038ad96aff2c3d3d677162281e95bbe8572f2c8b3408f769df0";
        manifest = "e8cef0d6b2a5b21c70894f58eed757fdadcf713a61faaecc371f4014a0e0157d";
      };
    };
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  cargoHash = "sha256-2iJ4S4JMekzXWF7IIrhs059unEox2TaL7QnMvwH+b/Q=";

  pnpmDeps = fetchPnpmDeps {
    pname = "fluxer";
    inherit (finalAttrs) src;
    fetcherVersion = 4;
    hash = "sha256-mmkgT7nhZ7LiaLWrwO0zKxGMuSKURsPE6AN/lYl4sp4=";
  };

  extraCargoDeps = [
    (rustPlatform.fetchCargoVendor {
      name = "libfluxcore";
      cargoRoot = "fluxer_app/rust/libfluxcore";
      inherit (finalAttrs) src;
      hash = "sha256-n9hA0WaUyYpXV9ply8QwUgq4NvmBERIebrfzz2lCd/A=";
    })
    (rustPlatform.fetchCargoVendor {
      name = "libfluxwebp";
      cargoRoot = "fluxer_app/rust/libfluxwebp";
      inherit (finalAttrs) src;
      hash = "sha256-zz5JD3jiNCx8FOReZmCm4O2F20s7UbMsfZIM2sIcSS0=";
    })
  ];

  native-addons = {
    webauthn = {
      nativeBuildInputs = [ rustPlatform.bindgenHook ];
      buildInputs = [
        openssl
        libfido2
      ];
      cargoHash = "sha256-/YSjmYOUJqp9P68MgPsnuRf5pgYLItTWoaDeMu61xt8=";
    };
    hardware-encoder.cargoHash = "sha256-GylpEE/JlVxrbeK62w5vDizbNfGq6mSO47wZHqGBR9Y=";
    app-store.cargoHash = "sha256-NQsRJqlLDe6nf4msrVdTKiLtgFZHX/1Ys9xPIMwyW74=";
    gateway-socket.cargoHash = "sha256-ZWntY3bcRx4PuLHV7aepdA6anPrW8USMtWo6kkvpebo=";
    linux-audio-capture = {
      nativeBuildInputs = [ rustPlatform.bindgenHook ];
      buildInputs = [ pipewire ];
      cargoHash = "sha256-4cMvuI8juS8n4HtDkMk5ueXlFEldXvFrp7q70Pm8jRs=";
    };
    linux-portals.cargoHash = "sha256-Ejilk90J72C946oyPPXafxBDZAgEqedUJFQ39pvqk1A=";
    linux-notifications.cargoHash = "sha256-HpgpXzXqwBa2K3FIzUJVcJPpoLrd9UAruyrcYVhGSFU=";
    linux-evdev = {
      buildInputs = [ udev ];
      cargoHash = "sha256-L7xUfohe4aOI555u2hzhf7SeTk6Pv2IdTYHaLx5CEVo=";
    };
    system-hunspell = {
      nativeBuildInputs = [ rustPlatform.bindgenHook ];
      cargoHash = "sha256-UZiiU10RzU60jFooFaY82idN6vwTpMOY6pWLcdL1Cd0=";
    };
    linux-input-hook.cargoHash = "sha256-aOSzf5YrPfxUYYs8xsEjFBRkBxZrewNh/2srpj6mdSw=";
    platform-info.cargoHash = "sha256-qppRUj6Unyyswe4gNY4khwwBI+IAtbmMaUcrX3JW5B0=";
  };

  patches = [
    ../fluxer-ci-binary-in-desktop-build-js.patch

    # by default, the build scripts assert that glibc dependency is <= what Ubuntu ships, and that anything not installed on Ubuntu by default (libfido2) must be included.
    # but neither of these constraints are relevant in Nix; the fluxer modules will statically refer to a compatible glibc and libfido2 by construction; they cannot be missing at runtime.
    ../dont-assert-abi-compatibility.patch
  ];
})
