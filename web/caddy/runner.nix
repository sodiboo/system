{
  lib,
  stdenv,
  rustc,
  caddy,
}:
stdenv.mkDerivation {
  name = "caddy-runner";

  src = ./runner.rs;
  dontUnpack = true;

  nativeBuildInputs = [ rustc ];

  env.EXECUTABLE = lib.getExe caddy;

  buildPhase = "rustc -Copt-level=3 --crate-name runner $src --out-dir $out/bin";

  meta.mainProgram = "runner";
}
