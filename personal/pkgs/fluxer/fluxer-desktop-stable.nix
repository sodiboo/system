{
  lib,
  callPackage,
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
  fluxer-component = "fluxer-desktop-stable";
  version = "2026.1026.24218";

  build-channel = "stable";
  app-id = "app.fluxer.Fluxer";
  meta.mainProgram = "fluxer-desktop";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-XF6PZDl9eq41g6QiNFcvnjrw0ZhwSJoyobyXrglRCzQ=";
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

  cargoHash = "sha256-mC7Y84XD1GkEPvrQi2sTit3HMRObsDIryfSPmwhf69A=";

  pnpmDeps = fetchPnpmDeps {
    pname = "fluxer";
    inherit (finalAttrs) src;
    fetcherVersion = 4;
    hash = "sha256-XUpKPSzZr99p4d29m4wYxouRKVZygF0vTiSaXOKI4KM=";
  };

  libfluxcore.cargoHash = "sha256-n9hA0WaUyYpXV9ply8QwUgq4NvmBERIebrfzz2lCd/A=";
  libfluxwebp.cargoHash = "sha256-zz5JD3jiNCx8FOReZmCm4O2F20s7UbMsfZIM2sIcSS0=";

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
    app-store.cargoHash = "sha256-ZmoKvQDdEdMQo27Z66Vqj5NPmpaJ+GAgcaC7OZr2SEM=";
    gateway-socket.cargoHash = "sha256-vCSk1qHPDui+NiGkB2cKs+SPrA/BvRSVdQPo2Ae9/QA=";
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
      cargoHash = "sha256-65F2CsCChIGMaKjg8k6GJlkb4LVWCacG4mDTuRI9BVE=";
    };
    linux-input-hook.cargoHash = "sha256-aOSzf5YrPfxUYYs8xsEjFBRkBxZrewNh/2srpj6mdSw=";
    platform-info.cargoHash = "sha256-qppRUj6Unyyswe4gNY4khwwBI+IAtbmMaUcrX3JW5B0=";
  };
})
