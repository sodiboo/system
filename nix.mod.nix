{secrets, ...}: let
  caches = {
    # "https://niri.cachix.org" = "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964=";
  };
in {
  universal.modules = [
    {
      nix.settings = {
        experimental-features = ["nix-command" "flakes"];
        substituters = builtins.attrNames caches;
        trusted-public-keys = builtins.attrValues caches;
      };
      # will !include soon
      nix.extraOptions = ''
        access-tokens = github.com=${secrets.github-token}
      '';
      nixpkgs.config.allowUnfree = true;
      system.stateVersion = "23.11";
    }
  ];
  universal.home_modules = [
    ({
      pkgs,
      lib,
      ...
    }: {
      home.packages = with pkgs; [
        cachix
        nil
        nurl
        nix-diff
        nh
        nix-output-monitor
        nvd
        nix-init
      ];

      programs.fish.shellAliases = let
        conf = ''env NIX_CONFIG="warn-dirty = false"'';
        rebuild = verb: dry: "fish -c '${builtins.concatStringsSep " && " [
          "cd /etc/nixos"
          # The secrets are synced out-of-band, and timestamps are not guaranteed to be accurate.
          # Nix considers a changed timestamp to be lockfile-worthy, so we reset them to the epoch.
          # This ensures that between systems, nix will not keep trying to update the lockfile.
          "touch -d $(date -d @0) secrets{,/{,.}*}"
          "${conf} nix fmt -- --quiet *"
          "git add ."
          (
            if dry
            then "${conf} nh os ${verb} --update --dry ."
            else "${conf} nh os ${verb} --update ."
          )
        ]}'";
      in
        lib.mergeAttrsList (map (verb: {
          "nix.${verb}" = rebuild verb false;
          "nix+${verb}" = rebuild verb true;
        }) ["switch" "boot" "test"])
        // {
          nix-shell = "nix-shell --run fish";
        };
    })
  ];
}
