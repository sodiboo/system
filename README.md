Heya! This repo contains the system configuration for all the computers i control.

Currently, it handles three computers: `sodium`, `lithium`, and `oxygen`.
The first two are personal machines i own, and the third is a VPS.

### sodium

This is my main workstation. It's a desktop computer with a Ryzen 5 7600X, 32 GB of RAM, and an RX 7800 XT. I built it myself in early 2024.

It also has the following unique hardware:

- Samsung Odyssey G9 monitor, which has a 5120x1440 resolution (32:9 aspect ratio).  
  This is a bit of a pain to configure, and one of the main reasons i started using niri.
- Wooting Two HE, which is an analog mechanical keyboard.  
  It works just fine as a regular keyboard, but i need Wootility to configure it.
- Razer Nari, which is a wireless headset with two audio outputs (game and chat).  
  For this, i have a nixos module at [`github:sodiboo/nixos-razer-nari`](https://github.com/sodiboo/nixos-razer-nari).
- Launchpad Pro, which is an 8x8 MIDI button grid.  
  I don't use it much, but i play with it from time to time.  
- Some other Razer peripherals, namely a mouse and a mousepad, but they're not really unique.
  At least, i don't do anything special with them.

### lithium

This is my laptop. It's a ThinkPad X1 Carbon Gen 9, and is less interesting than sodium. I use it more, though, because i'm literally not at home for 12 hours a day most days.

It has a 3840x2400 display (16:10 aspect ratio), and the most interesting parts about it are the following:

- It has a fingerprint reader, which i use to authenticate with sudo and polkit.
- The touchpad doesn't fucking work. It used to, but it's genuinely just awful. I disabled it.
- It has a TrackPoint instead, but i prefer using my bluetooth mouse.

### oxygen

This is a VPS with Contabo. It's their "VPS 1" with an external SSD, because that gives me more storage capcity than an NVMe drive and the performance difference likely won't ever matter to me. I installed NixOS on it using `nixos-infect`, because they charge for object storage if i want to upload a custom iso.

It doesn't really have any unique hardware; it's just a qemu guest. See [`nginx.mod.nix`](./nginx.mod.nix) for a more complete overview of the stuff i host on it; nginx handles all communication with the outside world.

## Files

Modules have a `*.mod.nix` extension, which is loaded in [`flake.nix`](/flake.nix). The structure of `*.mod.nix` files is essentially `{ <system>.modules :: arrayOf(nixosModule), <system>.home_modules :: arrayOf(homeModule) }`. They can also take the flake inputs at the top.

`<system>` is either `sodium`, `lithium` or more commonly `personal` which contains stuff common for both. There is also `oxygen`, which is a VPS and `universal` which is common to all three. `universal` will generally contain stuff like a command line environment (prompts, editors, tooling), whereas `personal` will contain stuff that doesn't/can't exist on the server, such as bluetooth, audio, GUI/Wayland environment (niri, waybar, etc), and leisure/games

My secrets are managed using a very unsophisticated homemade solution. `secrets` is a flake input that is gitignored. It's preprocessed such that the files within are passed as strings of the `secrets` attrset; this is the only flake input that is modified before being passed to all modules.

Most modules have a self-explanatory name. Here are some of the less obvious ones:

- [`hardware.mod.nix`](/hardware.mod.nix) has the equivalent of `nixos-generate-config --show-hardware-config` for each machine.
- [`peripherals.mod.nix`](/peripherals.mod.nix) deals with some of the unique hardware i have.
- [`home.mod.nix`](/home.mod.nix) handles setup of home-manager.
- [`lock.mod.nix`](/lock.mod.nix) handles a lock script that blurs a screenshot of the screen.
- [`login.mod.nix`](/login.mod.nix) uses the same script to blur just the wallpaper when logging in.
- [`sodipkgs.mod.nix`](/sodipkgs.mod.nix) just has some of my nixpkgs PRs that haven't been merged yet.
- [`vpn.mod.nix`](/vpn.mod.nix) handles a VPN connection i use to get around a firewall at school, though it doesn't work right now.
- [`niri.mod.nix`](/niri.mod.nix) handles my niri configuration. I maintain [`github:sodiboo/niri-flake`](https://github.com/sodiboo/niri-flake), which is the backend for this.

These modules may be removed, renamed, merged, or split in the future. I'm not very good at naming things.