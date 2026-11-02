{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-gateway ? callPackage ../server/fluxer-gateway.nix { },
}:
make-fluxer-gateway (finalAttrs: {
  version = "2026.1102.30901";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-H5+DaHvJvkX3BJ68ZenGOT2HnxXYUOza9yiNVHsUxTI=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  beamHash = "sha256-MeH4F6ncfJPfC/N+EvP4zWsRBDiDqrECaWELBYhXXlA=";

  native-functions = {
    guild_member_list_oset_nif.cargoHash = "sha256-2rC75bs0LvcV2K+quzl9qJ9DizkEV5FMjU73+mxsue0=";
    push_markdown_plaintext_nif.cargoHash = "sha256-/2Jx8vYz2SCrwLGvz/F3f7GHp4xv44rL6ZESv9hYJwM=";
  };
})
