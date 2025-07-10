{
  stdenv,
  rustc,
}:
stdenv.mkDerivation {
  name = "activate-transient-niri-session";

  src = ./activate.rs;
  dontUnpack = true;

  nativeBuildInputs = [ rustc ];

  buildPhase = "rustc -Copt-level=3 --crate-name activate $src --out-dir $out/bin";

  meta.mainProgram = "activate";
}
