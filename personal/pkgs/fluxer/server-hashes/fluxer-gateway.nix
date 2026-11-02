{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-gateway ? callPackage ../server/fluxer-gateway.nix { },
}:
make-fluxer-gateway (finalAttrs: {
  version = "2026.1026.202726";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-NzgBQwvJSHCwnF2bG/+vywp8mgPpAhUzTP/irrvCQjM=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  beamHash = "sha256-rGSvSCUjH+BedJga2Kq2B7diDT5M68l2xmp9hbDD5xI=";

  native-functions = {
    guild_member_list_oset_nif.cargoHash = "sha256-lECOMdkbdWAeL829MrWPWGQI44P+4VMnLIp9Jd+xJJo=";
    push_markdown_plaintext_nif.cargoHash = "sha256-9HDcMd1qfIOJPIw6D9bLR4rSfbz8Zv/wz9zQe3PoZjM=";
  };
})
