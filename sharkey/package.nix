{
  lib,
  stdenv,
  stdenvNoCC,
  fetchFromGitLab,
  bash,
  makeWrapper,
  copyDesktopItems,
  jemalloc,
  ffmpeg-headless,
  jq,
  python3,
  pkg-config,
  glib,
  vips,
  moreutils,
  cacert,
  nodePackages,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "sharkey";
  version = "2024.3.3";

  src = fetchFromGitLab {
    owner = "TransFem-org";
    repo = "Sharkey";
    domain = "activitypub.software";
    rev = finalAttrs.version;
    hash = "sha256-5kxIsabOuLcmkFTZlpYx0mj0Lpy7NWpzcH5SMNae+0c="; # "sha256-+lu0l/TA2Ge/flTUyyV/i0uzh4aycSGVCSQMkush8zA=";
    fetchSubmodules = true;
  };

  # NOTE: This requires pnpm 8.10.0 or newer
  # https://github.com/pnpm/pnpm/pull/7214
  pnpmDeps = assert lib.versionAtLeast nodePackages.pnpm.version "8.10.0";
    stdenv.mkDerivation {
      pname = "${finalAttrs.pname}-pnpm-deps";
      inherit (finalAttrs) src version;

      nativeBuildInputs = [
        jq
        moreutils
        nodePackages.pnpm
        cacert
      ];

      # https://github.com/NixOS/nixpkgs/blob/763e59ffedb5c25774387bf99bc725df5df82d10/pkgs/applications/misc/pot/default.nix#L56
      installPhase = ''
        export HOME=$(mktemp -d)

        pnpm config set store-dir $out
        pnpm config set side-effects-cache false
        pnpm install --force --frozen-lockfile --ignore-scripts
      '';

      fixupPhase = ''
        rm -rf $out/v3/tmp
        for f in $(find $out -name "*.json"); do
          sed -i -E -e 's/"checkedAt":[0-9]+,//g' $f
          jq --sort-keys . $f | sponge $f
        done
      '';

      dontBuild = true;
      outputHashMode = "recursive";
      outputHash = "sha256-MOqgSlVryJQPi1sPehLIhQjKF8nCin5kPZCZNCfrBkU="; # "sha256-foRIx8j+HVzJe7DKlKlI4S5xtK76H1B2VgFlWNpDw6g=";
    };

  nativeBuildInputs = [
    copyDesktopItems
    nodePackages.pnpm
    nodePackages.nodejs
    makeWrapper
    python3
    pkg-config
  ];

  buildInputs = [
    glib
    vips
  ];

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)
    export STORE_PATH=$(mktemp -d)

    export npm_config_nodedir=${nodePackages.nodejs}

    cp -Tr "$pnpmDeps" "$STORE_PATH"
    chmod -R +w "$STORE_PATH"

    pnpm config set store-dir "$STORE_PATH"
    pnpm install --offline --frozen-lockfile --ignore-scripts

    (
      cd node_modules/.pnpm/node_modules/v-code-diff
      pnpm run postinstall
    )
    (
      cd node_modules/.pnpm/node_modules/re2
      pnpm run rebuild
    )
    (
      cd node_modules/.pnpm/node_modules/sharp
      pnpm run install
    )

    runHook postConfigure
  '';

  buildPhase = ''
    runHook preBuild

    pnpm build

    runHook postBuild
  '';

  installPhase = let
    libPath = lib.makeLibraryPath [
      jemalloc
      ffmpeg-headless
      stdenv.cc.cc.lib
    ];

    binPath = lib.makeBinPath [
      bash
      nodePackages.pnpm
    ];
  in ''
    runHook preInstall

    mkdir -p $out/Sharkey

    ln -s /var/lib/sharkey $out/Sharkey/files
    ln -s /run/sharkey $out/Sharkey/.config
    cp -r * $out/Sharkey

    # https://gist.github.com/MikaelFangel/2c36f7fd07ca50fac5a3255fa1992d1a

    makeWrapper ${nodePackages.pnpm}/bin/pnpm $out/bin/sharkey \
      --chdir $out/Sharkey \
      --prefix PATH : ${binPath} \
      --prefix LD_LIBRARY_PATH : ${libPath}

    runHook postInstall
  '';

  passthru = {
    inherit (finalAttrs) pnpmDeps;
  };

  meta = with lib; {
    description = "🌎 A Sharkish microblogging platform 🚀";
    homepage = "https://joinsharkey.org";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [aprl sodiboo];
    platforms = ["x86_64-linux" "aarch64-linux"];
    mainProgram = "sharkey";
  };
})
