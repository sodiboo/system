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
  version = "2025.4.2";

  src = fetchFromGitLab {
    domain = "activitypub.software";
    owner = "TransFem-org";
    repo = "Sharkey";
    rev = finalAttrs.version;
    fetchSubmodules = true;
    hash = "sha256-gCZY9d/YLNQRGVFqsK7//UDiS19Jtqa7adGliIdE+4c=";
  };

  pnpmDeps = pnpm_9.fetchDeps {
    inherit (finalAttrs) src pname;
    hash = "sha256-2bt/sHKGNIjKfOvZ6DCXvdJcKoOJX/ueWdLULlYK3YU=";
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

  # This environment variable is required for `node-gyp`, which is used by some native dependencies we build below.
  # Without it, `node-gyp` won't know where the source code for node.js is, and will fail to download it instead.
  npm_config_nodedir = nodejs;

  # Sharkey depends on some packages with native code that needs to be built.
  # These aren't built by default, so we need to run their build scripts manually.
  #
  # The tricky thing is that not all of them are required for Sharkey to "successfully" build.
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

  installPhase = ''
    runHook preInstall

    mkdir -p $out/Sharkey

    cp -r * $out/Sharkey

    makeWrapper ${lib.getExe pnpm_9} $out/bin/sharkey \
      --chdir $out/Sharkey \
      --set-default NODE_ENV production \
      --prefix PATH : ${
        lib.makeBinPath [
          bash
          pnpm_9
          nodejs
        ]
      } \
      --prefix LD_LIBRARY_PATH : ${
        lib.makeLibraryPath [
          jemalloc
          ffmpeg-headless
          stdenv.cc.cc.lib
        ]
      }

    runHook postInstall
  '';

  passthru = {
    inherit (finalAttrs) pnpmDeps;
  };

  meta = {
    description = "🌎 A Sharkish microblogging platform 🚀";
    homepage = "https://joinsharkey.org";
    license = lib.licenses.gpl3Only;
    maintainers = with lib.maintainers; [ sodiboo ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "sharkey";
  };
})
