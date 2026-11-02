{
  lib,
  makeWrapper,

  nodejs_26,
  pnpm_11,
  pnpmConfigHook,
  pnpmBuildHook,

  make-fluxer-derivation,
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  extendDrvArgs =
    finalAttrs: args:
    let
      inherit (finalAttrs) pnpm nodejs;
    in
    {
      fluxer-component = "fluxer-api";

      nodejs = args.nodejs or nodejs_26;
      pnpm = args.pnpm or (pnpm_11.override { nodejs-slim = nodejs; });

      nativeBuildInputs = [
        makeWrapper
        nodejs
        pnpm
        pnpmConfigHook
        pnpmBuildHook
      ]
      ++ args.nativeBuildInputs or [ ];

      fluxer-ci = null;

      env = {
        npm_config_nodedir = nodejs;
      }
      // args.env or { };

      pnpmWorkspaces = [ "fluxer_api..." ];

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
      }
      // args.meta or { };
    };
}
