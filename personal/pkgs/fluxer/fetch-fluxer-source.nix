{
  fetchFromGitHub,
  ...
}:
{
  fluxer-component,
  version,
  hash ? null,
  ...
}@args:
fetchFromGitHub (
  {
    owner = "fluxerapp";
    repo = "fluxer";
    rev = "${fluxer-component}@${version}";
  }
  // (builtins.removeAttrs args [
    "fluxer-component"
    "version"
  ])
)
