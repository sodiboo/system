{
  lib,
  stdenv,
  runCommand,
  callPackage,
  symlinkJoin,
  makeWrapper,

  jq,
  rsync,

  nodejs_26,
  pnpm_11,
  pnpmConfigHook,
  electron_44,

  cargo,
  rustc,
  rustPlatform,

  pkg-config,

  make-fluxer-derivation,
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
      build-channel,
      libfluxcore,
      libfluxwebp,
      native-addons,
      ...
    }:

    let
      libflux-args =
        {
          src ? finalAttrs.src,
          version ? finalAttrs.version,
          ...
        }:
        {
          inherit src version;
        };

      renderer = callPackage ./fluxer-app-desktop-renderer.nix { } {
        inherit (finalAttrs)
          src
          version
          build-channel
          cargoDeps
          pnpmDeps
          ;

        libfluxcore = lib.extendMkDerivation {
          constructDrv = callPackage ./libfluxcore.nix { };
          extendDrvArgs = _: libflux-args;
        } args.libfluxcore;

        libfluxwebp = lib.extendMkDerivation {
          constructDrv = callPackage ./libfluxwebp.nix { };
          extendDrvArgs = _: libflux-args;
        } args.libfluxwebp;

        markdown-parser-wasm = callPackage ./fluxer-markdown-parser.nix { } {
          inherit (finalAttrs) src version cargoDeps;
        };
      };

      inherit (finalAttrs)
        electron
        nodejs
        pnpm
        ;
    in
    {
      electron = args.electron or electron_44;
      nodejs = args.nodejs or nodejs_26;
      pnpm = args.pnpm or (pnpm_11.override { nodejs-slim = nodejs; });
      custom-deps =
        (map (addon: addon.cargoDeps.vendorStaging) (builtins.attrValues finalAttrs.passthru.native-addons))
        ++ [
          renderer.libfluxcore.cargoDeps
          renderer.libfluxwebp.cargoDeps
        ]
        ++ args.custom-deps or [ ];

      passthru = {
        inherit renderer;

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
        ../fluxer-ci-binary-in-desktop-build-js.patch

        # by default, the build scripts assert that glibc dependency is <= what Ubuntu ships, and that anything not installed on Ubuntu by default (libfido2) must be included.
        # but neither of these constraints are relevant in Nix; the fluxer modules will statically refer to a compatible glibc and libfido2 by construction; they cannot be missing at runtime.
        ../dont-assert-abi-compatibility.patch

        ./desktop-dont-check-linux-archive.patch
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
          ln -s ${renderer} dist/renderer
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
