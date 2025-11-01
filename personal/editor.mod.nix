inputs: {
  physical.home-shortcut = {
    imports = [ inputs.vscode-server.homeModules.default ];
    services.vscode-server.enable = true;
  };

  personal =
    { lib, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (final: prev: {
          sodi-vscode-fhs = final.writeShellScriptBin "code-fhs" ''
            exec ${lib.getExe final.vscode-fhs} $@
          '';
        })
      ];

      home-shortcut = {
        home.packages = [
          pkgs.sodi-vscode-fhs
        ];

        programs = {
          helix.enable = true;
          vscode.enable = true;
          # vscode.package = pkgs.vscode-fhs;
        };
      };
    };
}
