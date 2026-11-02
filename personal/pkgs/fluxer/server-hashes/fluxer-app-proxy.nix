{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-app-proxy ? callPackage ../app/web/fluxer-app-proxy-wrapper.nix { },
}:
make-fluxer-app-proxy (finalAttrs: {
  version = "2026.1102.30752";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-H5+DaHvJvkX3BJ68ZenGOT2HnxXYUOza9yiNVHsUxTI=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  cargoHash = "sha256-KBKwdYW3tpZmjoqlA5Lx4b0FTlPcHKrDsXXtazuQO0g=";

  pnpmHash = "sha256-JLMS59QISQFZieXC4sUgfkPEJEN7JXbJN73Aea8huJo=";

  libfluxcore.cargoHash = "sha256-OO4aw0TmibmV9NAfVMDue8PAbHsXHKgM/XuYVN8QOQg=";
  libfluxwebp.cargoHash = "sha256-9kG0urKGRwGGYenIdmW/E9XZ/lSC3dO0mZ8RuzSA61E=";
})
