{
  fetchurl,
  stdenvNoCC,
  ...
}:
stdenvNoCC.mkDerivation {
  pname = "bee-movie-script";
  version = "latest";
  src = fetchurl {
    url = "https://s3.madhouse-project.org/mirror/bee-movie.txt";
    hash = "sha256-P1EfUDemilKKsOtjzZJZrPfH7IhyU4CWNBu3ulBRxn4=";
  };
  dontUnpack = true;
  installPhase = ''
    cp $src $out
  '';
}
