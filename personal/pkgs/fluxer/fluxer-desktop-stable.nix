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
  fluxer-update-script,
}:
make-fluxer-desktop (finalAttrs: {
  fluxer-component = "fluxer-desktop-stable";
  version = "2026.1017.133957";

  build-channel = "stable";
  app-id = "app.fluxer.Fluxer";
  meta.mainProgram = "fluxer-desktop";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-LG+zCRihq5u2T7wVvnMXNynsaNyN4rXfVBkwCz/rFVE=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  cargoHash = "sha256-zE2nBLHrrESjOqKzAuPbl7F3FTh6QtO4rqyddRgykJc=";

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
