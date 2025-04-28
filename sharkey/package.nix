{
  lib,
  stdenv,
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
  pnpm_9,
  nodejs,
  pixman,
  pango,
  cairo,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "sharkey";
  version = "2025.2.3";

  src = fetchFromGitLab {
    owner = "TransFem-org";
    repo = "Sharkey";
    domain = "activitypub.software";
    rev = finalAttrs.version;
    hash = "sha256-VBfkJuoQzQ93sUmJNnr1JUjA2GQNgOIuX+j8nAz3bb4=";
    fetchSubmodules = true;
  };

  pnpmDeps = stdenv.mkDerivation {
    pname = "${finalAttrs.pname}-pnpm-deps";
    inherit (finalAttrs) src version;

    nativeBuildInputs = [
      jq
      moreutils
      pnpm_9
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
    outputHash = "sha256-ALstAaN8dr5qSnc/ly0hv+oaeKrYFQ3GhObYXOv4E6I=";
  };

  nativeBuildInputs = [
    copyDesktopItems
    pnpm_9
    nodejs
    makeWrapper
    python3
    pkg-config
  ];

  buildInputs = [
    glib
    vips

    pixman
    pango
    cairo
  ];

  configurePhase = ''
    runHook preConfigure

    export HOME=$(mktemp -d)
    export STORE_PATH=$(mktemp -d)

    export npm_config_nodedir=${nodejs}

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
    (
      cd node_modules/.pnpm/node_modules/canvas
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
      pnpm_9
      nodejs
    ];
  in ''
    runHook preInstall

    mkdir -p $out/Sharkey

    ln -s /var/lib/sharkey $out/Sharkey/files
    ln -s /run/sharkey $out/Sharkey/.config
    cp -r * $out/Sharkey

    # https://gist.github.com/MikaelFangel/2c36f7fd07ca50fac5a3255fa1992d1a

    makeWrapper ${lib.getExe pnpm_9} $out/bin/sharkey \
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
