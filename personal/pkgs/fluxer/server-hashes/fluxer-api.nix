{
  callPackage,
  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-api ? callPackage ../server/fluxer-api.nix { },
}:
make-fluxer-api (finalAttrs: {
  version = "2026.1026.151750";

  src = fetch-fluxer-source {
    inherit (finalAttrs) fluxer-component version;
    hash = "sha256-+wgDWFzAafPt3LPUASGkE0FppQS65zHKqvlc3AQ6Qzk=";
  };

  update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

  pnpmHash = "sha256-jbWCzdUkT9WZK7TjHV95LqJvggF8lous+2q/4HjVzx0=";
})
