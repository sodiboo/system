{
  lib,
  makeWrapper,

  nodejs_26,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
  pnpmBuildHook,

  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-derivation,
}:
make-fluxer-derivation (
  finalAttrs:
  let
    inherit (finalAttrs) pnpm nodejs;
  in
  {
    fluxer-component = "fluxer-api";
    version = "2026.1026.151750";

    src = fetch-fluxer-source {
      inherit (finalAttrs) fluxer-component version;
      hash = "sha256-+wgDWFzAafPt3LPUASGkE0FppQS65zHKqvlc3AQ6Qzk=";
    };

    update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

    nodejs = nodejs_26;
    pnpm = (pnpm_11.override { nodejs-slim = nodejs; });

    nativeBuildInputs = [
      makeWrapper
      nodejs
      pnpm
      pnpmConfigHook
      pnpmBuildHook
    ];

    cargoHash = null;
    fluxer-ci = null;

    env = {
      npm_config_nodedir = nodejs;
    };

    pnpmWorkspaces = [ "fluxer_api..." ];
    pnpmDeps = fetchPnpmDeps {
      inherit (finalAttrs) pname src pnpmWorkspaces;
      fetcherVersion = 4;
      hash = "sha256-jbWCzdUkT9WZK7TjHV95LqJvggF8lous+2q/4HjVzx0=";
    };

    installPhase = ''
      runHook preInstall

      mkdir -p $out/{bin,lib}

      pnpm config set --location=project injectWorkspacePackages true
      pnpm deploy \
        --filter=fluxer_api \
        --prod \
        $out/lib

      mkdir -p $out/lib/fluxer-api
      cp -r fluxer_api/dist/* $out/lib/fluxer-api/

      makeWrapper ${lib.getExe nodejs} $out/bin/fluxer-api \
        --add-flags "$out/lib/fluxer-api/AppEntrypoint.js" \
        --set "NODE_PATH" $out/lib/node_modules

      makeWrapper ${lib.getExe nodejs} $out/bin/fluxer-api-worker \
        --add-flags "$out/lib/fluxer-api/WorkerEntrypoint.js" \
        --set "NODE_PATH" $out/lib/node_modules

      runHook postInstall
    '';

    meta = {
      description = "A free and open source instant messaging and VoIP chat app";
      license = lib.licenses.agpl3Plus;
      homepage = "https://github.com/fluxerapp/fluxer";
      maintainers = with lib.maintainers; [ sodiboo ];
      mainProgram = "fluxer-api";
    };
  }
)
