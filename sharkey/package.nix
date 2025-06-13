{
  lib,
  stdenv,
  fetchFromGitLab,
  bash,
  makeWrapper,
  jemalloc,
  ffmpeg-headless,
  python3,
  pkg-config,
  glib,
  vips,
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
    domain = "activitypub.software";
    owner = "TransFem-org";
    repo = "Sharkey";
    rev = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-VBfkJuoQzQ93sUmJNnr1JUjA2GQNgOIuX+j8nAz3bb4=";
  };

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) src pname;
    hash = "sha256-ALstAaN8dr5qSnc/ly0hv+oaeKrYFQ3GhObYXOv4E6I=";
  };

  nativeBuildInputs = [
    pnpm_9.configHook
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

  # Sharkey depends on some packages with native code that needs to be built.
  # These aren't built by default, so we need to run their build scripts manually.
  #
  # The tricky thing is that not all of them required for Sharkey to "successfully" build.
  # They will trick you, make you think that Sharkey works, and successfully run your databse migrations.
  # And then, when your instance tries to run, it will crash with an error like:
  #
  #     Error [ERR_INTERNAL_ASSERTION]: This is caused by either a bug in Node.js or incorrect usage of Node.js internals.
  #     Please open an issue with this stack trace at https://github.com/nodejs/node/issues
  #
  # If you see that error, IT IS LYING TO YOU. It means Sharkey added a new dependency that required native code to be built.
  # Figure out what is the new dependency. You can ask in their discord, and they'll probably tell you.
  # And then, build it in the `buildPhase` below.

  buildPhase = ''
    runHook preBuild

    export npm_config_nodedir=${nodejs}

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
    maintainers = with maintainers; [sodiboo];
    platforms = ["x86_64-linux" "aarch64-linux"];
    mainProgram = "sharkey";
  };
})
