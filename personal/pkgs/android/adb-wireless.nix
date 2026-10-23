{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:

rustPlatform.buildRustPackage {
  name = "adb-wireless";
  src = fetchFromGitHub {
    owner = "teamclouday";
    repo = "adb-wireless";
    rev = "d7936aa4acf7a9a8e84f6e4e8915ee7f3a924428";
    hash = "sha256-4IS00yUow7kiDi39VMCwfNRXwMzlby4dcOdu6MIb8BI=";
  };

  cargoHash = "sha256-AsmYqTSHJkkz47L5mr/3HK+tOCXOE9neA7hJom9iGFc=";

  meta.mainProgram = "adb-wireless";
}
