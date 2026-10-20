{ nix-update-script, ... }:
{ fluxer-component, custom-deps }:
nix-update-script {
  extraArgs = [
    "--flake" # <-- mostly specific to this repo. might want to remove that flag if this packageset goes elsewhere
    "--version-regex"
    "${fluxer-component}@(.*)"
  ]
  ++ builtins.concatLists (
    builtins.map (drv: [
      "--custom-dep"
      "custom-dep-${drv.name}"
    ]) custom-deps
  );
}
