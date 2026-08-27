inputs: {
  personal.home-shortcut =
    {
      lib,
      pkgs,
      ...
    }:
    let
      package = inputs.nixpkgs-wayland.packages.${pkgs.stdenv.hostPlatform.system}.awww;
      namespaces = [
        "main"
        "overview"
      ];
    in
    {
      home.packages = [ package ];

      transient-session.services = builtins.listToAttrs (
        builtins.map (namespace: {
          name = "awww-${namespace}@";
          value = {
            Service.ExecStart = "${lib.getExe' package "awww-daemon"} -n ${namespace}";
          };
        }) namespaces
      );
    };
}
