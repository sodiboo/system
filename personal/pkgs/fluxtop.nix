{
  lib,
  stdenv,
  vesktop,
  electron_44,
  makeDesktopItem,
  ...
}:
let
  replace-vesktop-with-fluxtop =
    builtins.replaceStrings
      [ "vesktop" "Vesktop" ]
      [ "fluxtop" "Fluxtop" ];
in
(vesktop.override {
  electron_43 = electron_44;
}).overrideAttrs
  (
    finalAttrs: prevAttrs: {
      pname = "fluxtop";
      version = "1.8.0";
      src = prevAttrs.src.override {
        owner = "Patrosi73";
        repo = "Fluxtop";
        fetchSubmodules = true;
        hash = "sha256-yovOjjLX4t9MPULl5ZG6wfvOyTwgX5WJ4QNg5UZEJsg=";
      };

      pnpmDeps = prevAttrs.pnpmDeps.override {
        postInstall = ''
          (
            cd discord-adapter-meme

            pnpm config set reporter append-only
            pnpm config set store-dir $storePath

            echo "final pnpm config for discord-adapter-meme":
            pnpm config list

            pnpm install "''${installFlagsArray[@]}"
          )
        '';
        hash = "sha256-wJHDNUlrJkipeInZd8U4Adharp1QHLVVcsShvt7FVFE=";
      };

      preBuild = ''
        (
          cd discord-adapter-meme
          pnpm config set reporter append-only
          pnpm config set store-dir "$STORE_PATH"

          echo "final pnpm config for discord-adapter-meme":
          pnpm config list
          pnpm install \
            --offline \
            --ignore-scripts \
            "''${pnpmInstallFlags[@]}" \
            --frozen-lockfile
        )
        ${prevAttrs.preBuild or ""}
      '';

      desktopItems = lib.optional stdenv.hostPlatform.isLinux (makeDesktopItem {
        name = "fluxtop";
        desktopName = "Fluxtop";
        exec = "fluxtop %U";
        icon = "fluxtop";
        startupWMClass = "fluxtop";
        genericName = "Internet Messenger";
        comment = "Discord and Fluxer client";
        keywords = [
          "discord"
          "fluxer"
          "vencord"
          "vesktop"
          "electron"
          "chat"
        ];
        categories = [
          "Network"
          "InstantMessaging"
          "Chat"
        ];
        mimeTypes = [
          "x-scheme-handler/discord"
          "x-scheme-handler/fluxer"
        ];
      });

      installPhase = replace-vesktop-with-fluxtop prevAttrs.installPhase;
      postFixup = replace-vesktop-with-fluxtop prevAttrs.postFixup;
    }
  )
