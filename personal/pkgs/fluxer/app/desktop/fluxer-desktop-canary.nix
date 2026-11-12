{
  callPackage,

  rustPlatform,

  openssl,
  libfido2,

  sqlite,

  pipewire,

  udev,

  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-desktop ? callPackage ./fluxer-desktop.nix { },
  make-fluxer-electron-bin ? callPackage ./fluxer-electron-bin.nix { },
}:
make-fluxer-desktop (finalAttrs: {
  fluxer-component = "fluxer-desktop-canary";
  version = "2026.1101.230752";

  build-channel = "canary";
  app-id = "app.fluxer.FluxerCanary";
  meta.mainProgram = "fluxer-desktop-canary";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-mWi3S9mAulCk8Jeugh5n55thrGybkqyQYElIU5OQmZs=";
  };

  electron = make-fluxer-electron-bin {
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

  cargoHash = "sha256-KBKwdYW3tpZmjoqlA5Lx4b0FTlPcHKrDsXXtazuQO0g=";

  pnpmHash = "sha256-89bJwzGZ6JoFQxBInH4kMQzfhgXMqOgBVn31EGJ7Tps=";

  libfluxcore.cargoHash = "sha256-OO4aw0TmibmV9NAfVMDue8PAbHsXHKgM/XuYVN8QOQg=";
  libfluxwebp.cargoHash = "sha256-9kG0urKGRwGGYenIdmW/E9XZ/lSC3dO0mZ8RuzSA61E=";

  native-addons = {
    webauthn = {
      nativeBuildInputs = [ rustPlatform.bindgenHook ];
      buildInputs = [
        openssl
        libfido2
      ];
      cargoHash = "sha256-wIDP4YUk7ZoSlU+XOQPp2TT67Nre4rmfLIFDSE7WiSc=";
    };
    hardware-encoder.cargoHash = "sha256-6kby+eWqE/VRsrbw1q4MIIaiN/u0WOJFyxGe5VQcNYI=";
    app-store = {
      buildInputs = [ sqlite ];
      cargoHash = "sha256-Q0wKX/pTFNeAxJNGBNMbHwC78MJO6uxq5jRuO3PQg1g=";
    };
    gateway-socket.cargoHash = "sha256-6pMA5paREz/8SuCwNpXM4lna7YvZdCtFEDS2rZVdVOw=";
    linux-audio-capture = {
      nativeBuildInputs = [ rustPlatform.bindgenHook ];
      buildInputs = [ pipewire ];
      cargoHash = "sha256-q+qCK8x18ZplOIeyyCLYfVvlukG9n0UKXvV8B2JZQ5o=";
    };
    linux-portals.cargoHash = "sha256-b3XnwJEfuVW7mUjRmMbiWX5xfE1ZQY7DPJJAQOvjnmY=";
    linux-notifications.cargoHash = "sha256-8dbgHf8tVtAwPBjiIJhhUnqqeco5xZzwAIJqpdPA3rw=";
    linux-evdev = {
      buildInputs = [ udev ];
      cargoHash = "sha256-M23WQbguQJYGnbH41jnnnOM9cuytXKfEgVLPy48kT3U=";
    };
    system-hunspell = {
      nativeBuildInputs = [ rustPlatform.bindgenHook ];
      cargoHash = "sha256-RWKN4c8l3FrinNsSwh/FCVm/j829uf/mPyRakKkPNGY=";
    };
    linux-input-hook.cargoHash = "sha256-AIwXWKrl2eIDv+rBJ3qZdat1Ov8bvnuCHps3LDOgSDA=";
    platform-info.cargoHash = "sha256-bTLPUaD2EQ2+ywBw7MS8mnN6sTad7MV43II03wa1uM4=";
  };
})
