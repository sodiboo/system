{
  lib,
  fetchpatch,
  fetchFromGitHub,
  buildNpmPackage,
  esbuild,
  firefox-addons,
  ...
}:
let
  darkreader-version_unchecked = "4.9.133";
  darkreader-version =
    let
      # rycee packages don't expose a `version` attr.
      rycee-packaged-version = firefox-addons.darkreader.name;
      this-packaged-version = "darkreader-${darkreader-version_unchecked}";
    in
    lib.warnIf (this-packaged-version != rycee-packaged-version)
      "darkreader is outdated. it's ${this-packaged-version} but rycee has ${rycee-packaged-version}"
      darkreader-version_unchecked;

  darkreader-xpi = buildNpmPackage {
    pname = "darkreader.xpi";
    version = darkreader-version;
    env.ESBUILD_BINARY_PATH = lib.getExe esbuild;

    src = fetchFromGitHub {
      owner = "darkreader";
      repo = "darkreader";
      rev = "v${darkreader-version}";
      hash = "sha256-dtFsM4xeiBoF9mNRC8Y1RN1/boW/cGVim4UZBFUCBtc=";
    };

    patches = [
      (fetchpatch {
        name = "managed-config.patch";
        url = "https://github.com/darkreader/darkreader/commit/ce64457b5ef1229c96e5526a7786f880b192b41e.patch";
        hash = "sha256-0sYsF0CufBtLP5ADoFJOSDW7vXOekPUuySFbiLDRBfI=";
      })
    ];
    npmDepsHash = "sha256-FsuIsoVHYOBnG0RiryCoKmh3B8f/FbOihMPh3c7nKXw=";

    installPhase = ''
      cp build/release/darkreader-firefox.xpi $out
    '';
  };
in
firefox-addons.darkreader.overrideAttrs {
  version = darkreader-version;
  src = darkreader-xpi;
}
