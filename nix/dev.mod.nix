{ nix-monitored, nil, ... }:
{
  universal =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        nix-monitored.overlays.default
        (final: prev: {
          nix-monitored = prev.nix-monitored.override {
            # I find the notifications annoying.
            withNotify = false;
          };
        })
        (final: prev: {
          nixos-rebuild = prev.nixos-rebuild.override {
            nix = prev.nix-monitored;
          };
          nix-direnv = final.runCommand "nix-direnv-monitored" { } ''
            cp -R ${
              prev.nix-direnv.override {
                # Okay, so what's happening here is that `nix-direnv` doesn't just use `nix` from PATH.
                # However, it also doesn't use `nix` from nix store. It uses both.
                # So what i'm doing here, is setting the "fallback path" to nix, being nix-monitored.
                nix = prev.nix-monitored;
              }
            } $out
            chmod -R +w $out
            ${
              # And then, i'm replacing the command that it uses to find nix with `false`.
              # This makes it think there's no nix in PATH, and it will use the fallback path.
              # And voila, i get nom output in direnv.
              "sed -i 's/command -v nix/false/' $out/share/nix-direnv/direnvrc"
            }
          '';

          nixmon = final.runCommand "nixmon" { } ''
            mkdir -p $out/bin
            ln -s ${prev.nix-monitored}/bin/nix $out/bin/nixmon
          '';
        })
      ];
      environment.systemPackages = [ pkgs.nixmon ];

      home-shortcut = {
        home.packages = with pkgs; [
          cachix
          nil.packages.x86_64-linux.nil
          nurl
          nix-diff
          nix-output-monitor
          nvd
          # nix-init
        ];
      };
    };
}
