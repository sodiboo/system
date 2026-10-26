{
  lib,
  stdenv,
  fetchurl,
  substitute,

  nix-update-script,

  jq,
  unzip,
  makeWrapper,
  wrapGAppsHook3,

  runCommand,

  glib,
  gtk3,
  gtk4,
  at-spi2-atk,
  libdrm,
  libgbm,
  libxkbcommon,
  libxshmfence,
  libGL,
  vulkan-loader,
  alsa-lib,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  nss,
  nspr,
  libxrandr,
  libxfixes,
  libxext,
  libxdamage,
  libxcomposite,
  libx11,
  libxkbfile,
  libxcb,
  pango,
  systemd,
  pciutils,
  libnotify,
  pipewire,
  libsecret,
  libpulseaudio,
  speechd-minimal,
}:
{
  version,
  hashes,
}:
let
  stem = lib.head (lib.splitString "-fluxer" version);

  fetchers = platform: {
    archive =
      hash:
      fetchurl {
        url = "https://github.com/fluxerapp/fluxer/releases/download/desktop-electron-runtime-${version}/electron-v${stem}-${platform}.zip";
        sha256 = hash;
      };
    manifest =
      hash:
      fetchurl {
        url = "https://github.com/fluxerapp/fluxer/releases/download/desktop-electron-runtime-${version}/electron-v${stem}-${platform}.fluxer.json";
        sha256 = hash;
      };
  };
in
stdenv.mkDerivation (
  finalAttrs:
  let
    electron-platform =
      {
        x86_64-linux = "linux-x64";
        armv7l-linux = "linux-armv7l";
        aarch64-linux = "linux-arm64";
        aarch64-darwin = "darwin-arm64";
      }
      .${stdenv.hostPlatform.system};
    source = finalAttrs.passthru.sources.${electron-platform};
  in
  {
    __structuredAttrs = true;
    strictDeps = true;

    passthru.sources = builtins.mapAttrs (
      platform: builtins.mapAttrs (name: (fetchers platform).${name})
    ) hashes;

    meta = {
      license = [
        lib.licenses.mit
        lib.licenses.agpl3Plus # fluxer patches maybe aren't MIT licensed? unclear...
      ];

      mainProgram = "electron";
    };

    pname = "electron";
    inherit version;
    src = source.archive;

    buildInputs = [
      glib
      gtk3
      gtk4
    ];

    nativeBuildInputs = [
      jq
      unzip
      makeWrapper
      wrapGAppsHook3
    ];

    electronLibPath = lib.makeLibraryPath [
      alsa-lib
      at-spi2-atk
      cairo
      cups
      dbus
      expat
      gdk-pixbuf
      glib
      gtk3
      gtk4
      nss
      nspr
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxrandr
      libxkbfile
      pango
      pciutils
      stdenv.cc.cc
      systemd
      libnotify
      pipewire
      libsecret
      libpulseaudio
      speechd-minimal
      libdrm
      libgbm
      libxkbcommon
      libxshmfence
      libGL
      vulkan-loader
    ];

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out/libexec/electron
      unzip -d $out/libexec/electron $src
      chmod u-x $out/libexec/electron/*.so*
      cat ${source.manifest} | jq 'del(.archiveName, .archiveSha256)' > $out/libexec/electron/${source.manifest.name}
    '';
    #                              ^ yeah i know this makes the build completely reject this manifest. so why even have it.
    #                                but i don't wanna repack it to zip again. so i've included the manifest, minus the fields that are irrelevant.

    # We don't want to wrap the contents of $out/libexec automatically
    dontWrapGApps = true;

    preFixup = ''
      makeWrapper "$out/libexec/electron/electron" $out/bin/electron \
        "''${gappsWrapperArgs[@]}"
    '';

    postFixup = ''
      patchelf \
        --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        --set-rpath "${finalAttrs.electronLibPath}:$out/libexec/electron" \
        $out/libexec/electron/electron \
        $out/libexec/electron/chrome_crashpad_handler

      # replace bundled vulkan-loader
      rm "$out/libexec/electron/libvulkan.so.1"
      ln -s -t "$out/libexec/electron" "${lib.getLib vulkan-loader}/lib/libvulkan.so.1"
    '';

    passthru.dist = finalAttrs.finalPackage + "/libexec/electron";
  }
)
