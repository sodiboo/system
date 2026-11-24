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
          pkgs.lemminx
        ];

        programs = {
          helix.enable = true;
          vscode.enable = true;
          # vscode.package = pkgs.vscode-fhs;

          gram =
            let
              gram-extensions = inputs.gram-extensions.packages.${pkgs.system};
            in
            {
              enable = true;

              # some languages that i'd like extension support for, please.
              package = gram-extensions.wrapGramWithExtensions pkgs.gram [
                gram-extensions.dart
                gram-extensions.git-firefly
              ];

              # *usually*, i'd be configuring language servers per-project.
              # for example, i often work with nightly rust-analyzer or custom dotnet toolchains
              # but some languages are agnostic enough where actually i don't need to manage the toolchain that granularly.
              extraPackages = [
                # like json. this is not getting updates. also it's required for editing gram's settings comfortably. that can't be per project
                pkgs.vscode-json-languageserver
                # yaml too. this is just a stable format. why do we need an LSP for this?
                pkgs.yaml-language-server
                # so . much . serialization (toml)
                pkgs.tombi

                # this one is very npm. but npm is stable.
                pkgs.package-version-server

                # typst is the kind of thing i could get away with doing per project, but i'd rarely want to downgrade for any reason?
                # i don't think typst is super breaking or anything...
                # it feels on the level of markdown
                pkgs.tinymist

                # python is so introspectable that the language server doesn't really depend on any internal ABI or anything.
                # i'll configure python per project, but the language server itself can be global.
                # because pyright is far enough removed from the actual toolchain that it doesn't even need to statically know a Python version.
                pkgs.basedpyright
                # gram uses two LSPs for python??
                pkgs.ruff

                # bash is basically just *posix shell* which never gets updated. certainly nothing nightly about it.
                # if python is stable, bash is even more so!
                pkgs.bash-language-server
              ];
            };
        };
      };
    };
}
