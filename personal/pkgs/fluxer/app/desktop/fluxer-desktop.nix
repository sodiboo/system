{
  lib,
  callPackage,
  symlinkJoin,
  makeWrapper,

  jq,
  rsync,

  nodejs_26,
  pnpm_11,
  pnpmConfigHook,

  cargo,
  rustc,
  rustPlatform,

  pkg-config,

  make-fluxer-ci,
  make-fluxer-derivation,
  make-fluxer-app-desktop ? callPackage ./fluxer-app-desktop.nix { },
}:
lib.extendMkDerivation {
  constructDrv = make-fluxer-derivation;

  excludeDrvArgNames = [
    "libfluxcore"
    "libfluxwebp"
    "native-addons"
  ];

  extendDrvArgs =
    finalAttrs:
    args@{
      app-id,
      electron,
      build-channel,
      libfluxcore,
      libfluxwebp,
      native-addons,
      ...
    }:
    let
      inherit (finalAttrs)
        electron
        nodejs
        pnpm
        ;
    in
    {
      fluxer-ci = make-fluxer-ci { inherit (finalAttrs) src cargoDeps; };

      nodejs = args.nodejs or nodejs_26;
      pnpm = args.pnpm or (pnpm_11.override { nodejs-slim = nodejs; });
      custom-deps =
        (map (addon: addon.cargoDeps.vendorStaging) (builtins.attrValues finalAttrs.passthru.native-addons))
        ++ [
          finalAttrs.renderer.libfluxcore.cargoDeps.vendorStaging
          finalAttrs.renderer.libfluxwebp.cargoDeps.vendorStaging
        ]
        ++ args.custom-deps or [ ];

      renderer = make-fluxer-app-desktop {
        inherit (args) libfluxcore libfluxwebp;
        inherit (finalAttrs)
          src
          version
          build-channel
          fluxer-ci
          cargoDeps
          pnpmDeps
          ;
      };

      passthru = {
        native-addons = builtins.mapAttrs (
          addon:
          lib.extendMkDerivation {
            constructDrv = make-fluxer-derivation;
            extendDrvArgs = _: args: {
              fluxer-component = "fluxer-desktop/${addon}";
              inherit (finalAttrs) src fluxer-ci;
              version = null;
              update-script = null;
              cargoRoot = "fluxer_desktop/native/${addon}";

              nativeBuildInputs = [
                cargo
                rustc
                pkg-config
                rustPlatform.cargoSetupHook
              ]
              ++ args.nativeBuildInputs or [ ];

              buildPhase = ''
                fluxer-ci build-desktop-native-addon --addon-root fluxer_desktop/native/${addon}
              '';

              installPhase = ''
                pkg_dir="$out/node_modules/$(cat fluxer_desktop/native/${addon}/package.json | ${lib.getExe jq} -r .name)"
                mkdir -p $pkg_dir
                cp --target-directory $pkg_dir fluxer_desktop/native/${addon}/{package.json,*.{js,cjs,ts,node}}
              '';
            };
          }
        ) native-addons;
      }
      // args.passthru or { };

      patches = [
        ./patches/fluxer-ci-binary-in-desktop-build-js.patch

        # by default, the build scripts assert that glibc dependency is <= what Ubuntu ships, and that anything not installed on Ubuntu by default (libfido2) must be included.
        # but neither of these constraints are relevant in Nix; the fluxer modules will statically refer to a compatible glibc and libfido2 by construction; they cannot be missing at runtime.
        ./patches/dont-assert-abi-compatibility.patch

        # the way this validation is done is currently inconvenient to do with Nix, so just skip it.
        # (in particular, it expects the electron distribution to be zipped; but Nix doesn't love when binaries are compressed)
        ./patches/dont-check-linux-archive.patch

        # including sourcemaps makes the binary go from like 400M->500M . but on my system i think that's worth it, ish.
        ./patches/include-sourcemaps.patch
      ]
      ++ args.patches or [ ];

      nativeBuildInputs = [
        makeWrapper
        nodejs
        pnpm
        pnpmConfigHook
        cargo
        rustc
        rustPlatform.cargoSetupHook
        electron
      ]
      ++ args.nativeBuildInputs or [ ];

      env = {
        npm_config_nodedir = nodejs;

        FLUXER_ELECTRON_DIST = "garbage data lol"; # this check is patched out for now
        FLUXER_SKIP_NATIVE = "true";
        ELECTRON_ARCH = "x64";
      }
      // args.env or { };

      preBuild = ''
        (
          cd fluxer_desktop
          fluxer-ci build-desktop --step update_version
          fluxer-ci build-desktop --step set_build_channel

          mkdir dist
          ln -s ${finalAttrs.renderer} dist/renderer
        )
      '';

      buildPhase = ''
        runHook preBuild

        (
          cd fluxer_desktop
          pnpm build --use-shared-renderer

          cp -r ${electron.dist} electron-dist
          chmod -R +w electron-dist

          ${lib.getExe rsync} --chmod=+w -Lr ${
            symlinkJoin {
              name = "fluxer-desktop-native-addons";
              paths = builtins.attrValues (finalAttrs.passthru.native-addons);
            }
          }/ .

          pnpm exec electron-builder \
            --dir --linux --x64 \
            -c.electronDist=electron-dist \
            -c.electronVersion=${electron.version} \
            --config electron-builder.config.cjs
        )

        runHook postBuild
      '';

      installPhase = ''
        mkdir -p $out/share/${app-id}
        cp -t $out/share/${app-id} -r ./fluxer_desktop/dist-electron/linux-unpacked/resources/*

        mkdir -p $out/bin
        makeWrapper ${lib.getExe electron} $out/bin/${finalAttrs.meta.mainProgram} \
          --add-flags "$out/share/${app-id}/app.asar"

        (
          cd fluxer_desktop/packaging/linux
          substituteInPlace ${app-id}.desktop \
            --replace-fail "Exec=${app-id}" "Exec=$out/bin/${finalAttrs.meta.mainProgram}"

          install -Dm444 ${app-id}.desktop $out/share/applications/${app-id}.desktop
          install -Dm444 ${app-id}.metainfo.xml $out/share/metainfo/${app-id}.metainfo.xml

          install -Dm444 ${app-id}.svg $out/share/icons/hicolor/scalable/apps/${app-id}.svg
        )

        for size in 16 24 32 48 64 128 256 512; do
          install -Dm644 fluxer_desktop/dist-electron/linux-unpacked/resources/icons/"$size"x"$size".png \
            $out/share/icons/hicolor/"$size"x"$size"/apps/${app-id}.png
        done
      '';

      meta = {
        description = "A free and open source instant messaging and VoIP chat app";
        license = lib.licenses.agpl3Plus;
        homepage = "https://github.com/fluxerapp/fluxer";
        maintainers = with lib.maintainers; [ sodiboo ];
      }
      // args.meta;
    };

}
