{
  lib,
  runCommand,
  makeWrapper,
  symlinkJoin,

  cargo,
  rustc,
  rustPlatform,

  git,
  cacert,

  zstd,

  fetch-fluxer-source,
  fluxer-update-script,
  make-fluxer-derivation,

  beamMinimal28Packages,
}:
let
  zstdStatic = zstd.override { enableStatic = true; };

  make-native-function =
    src: function:
    lib.extendMkDerivation {
      constructDrv = make-fluxer-derivation;
      extendDrvArgs = fnAttrs: args: {
        fluxer-component = "fluxer-gateway/${function}";
        inherit src;
        version = null;
        fluxer-ci = null;
        update-script = null;
        cargoRoot = "fluxer_gateway/native/${function}";

        env = {
          buildAndTestSubdir = fnAttrs.cargoRoot;
          cargoBuildType = "release";
        }
        // args.env or { };

        nativeBuildInputs = [
          cargo
          rustc
          # pkg-config
          rustPlatform.cargoSetupHook
          rustPlatform.cargoBuildHook
          rustPlatform.cargoInstallHook
        ]
        ++ args.nativeBuildInputs or [ ];

        postInstall = ''
          mv $out/lib/lib${function}.so $out/${function}.so
          rmdir $out/lib

          ${args.postInstall or ""}
        '';
      };
    };

  beamPackages = beamMinimal28Packages;
in
make-fluxer-derivation (
  finalAttrs:
  let
    make-native-functions = builtins.mapAttrs (make-native-function finalAttrs.src);
  in
  {
    fluxer-component = "fluxer-gateway";
    version = "2026.1026.202726";

    src = fetch-fluxer-source {
      inherit (finalAttrs) fluxer-component version;
      hash = "sha256-NzgBQwvJSHCwnF2bG/+vywp8mgPpAhUzTP/irrvCQjM=";
    };

    custom-deps =
      map (function: function.cargoDeps.vendorStaging) (
        builtins.attrValues finalAttrs.passthru.native-functions
      )
      ++ [
        finalAttrs.beam-checkouts.staging
      ];

    passthru = {
      native-functions = make-native-functions {
        guild_member_list_oset_nif.cargoHash = "sha256-lECOMdkbdWAeL829MrWPWGQI44P+4VMnLIp9Jd+xJJo=";
        push_markdown_plaintext_nif.cargoHash = "sha256-9HDcMd1qfIOJPIw6D9bLR4rSfbz8Zv/wz9zQe3PoZjM=";
      };
    };

    update-script = fluxer-update-script { inherit (finalAttrs) fluxer-component custom-deps; };

    cargoHash = null;
    fluxer-ci = null;

    nativeBuildInputs = [
      makeWrapper

      beamPackages.erlang
      beamPackages.rebar3
    ];

    beam-checkouts =
      runCommand "fluxer-gateway-beam-checkouts"
        {
          staging =
            (beamPackages.fetchRebar3Deps {
              name = finalAttrs.pname;
              version = "0";
              src = "${finalAttrs.src}/fluxer_gateway";

              sha256 = "sha256-rGSvSCUjH+BedJga2Kq2B7diDT5M68l2xmp9hbDD5xI=";
            }).overrideAttrs
              (
                _: prev: {
                  name = "fluxer-gateway-beam-checkouts-staging";

                  nativeBuildInputs = [
                    git
                    cacert
                  ]
                  ++ prev.nativeBuildInputs or [ ];

                  postInstall = ''
                    find $out -name .git -prune -execdir rm -r {} +
                  '';
                }
              );
        }
        ''
          cp -r $staging $out
          chmod -R +w $out

          cd $out/_checkouts

          (
            cd eqwalizer_support
            cp -rT eqwalizer_support .
            rm -rf eqwalizer_support
          )

          (
            cd ezstd

            patchShebangs --build build_deps.sh
            chmod +x build_deps.sh

            mkdir -p _build/deps/zstd/lib
            cp ${zstd.dev}/include/*.h _build/deps/zstd/lib
            cp ${zstdStatic.out}/lib/libzstd.a _build/deps/zstd/lib
          )
        '';

    configurePhase = ''
      runHook preConfigure
      (
        cd fluxer_gateway
        cp -ra ${finalAttrs.beam-checkouts}/_checkouts .
        chmod -R +w _checkouts
        ln -s ${
          symlinkJoin {
            name = "fluxer-gateway-native-functions";
            paths = builtins.attrValues (finalAttrs.passthru.native-functions);
          }
        } priv

        cp config/sys.config.template config/sys.config
      )
      runHook postConfigure
    '';

    postPatch = ''
      substituteInPlace fluxer_gateway/rebar.config ${
        lib.escapeShellArgs [
          "--replace-fail"
          "../tools/ci/run.sh build-gateway-nifs --gateway-dir ."
          "true"
        ]
      }
    '';

    buildPhase = ''
      runHook preBuild
      (
        cd fluxer_gateway
        HOME=. DEBUG=1 rebar3 as prod release
      )
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      (
        cd fluxer_gateway

        mkdir -p "$out/rel" "$out/bin"
        cp -Ra "_build/prod/rel" "$out"

        substitute scripts/docker_entrypoint.sh $out/bin/fluxer-gateway \
          --replace-fail "/opt/fluxer_gateway/bin/fluxer_gateway" "$out/rel/bin/fluxer_gateway"

        patchShebangs --host $out/bin/fluxer-gateway
        chmod +x $out/bin/fluxer-gateway
      )
      runHook postInstall
    '';

    meta = {
      description = "A free and open source instant messaging and VoIP chat app";
      license = lib.licenses.agpl3Plus;
      homepage = "https://github.com/fluxerapp/fluxer";
      maintainers = with lib.maintainers; [ sodiboo ];
      mainProgram = "fluxer-gateway";
    };
  }
)
