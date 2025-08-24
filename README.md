Heya! This repo contains the system configuration for all the computers i control.

Currently, it handles four computers: `sodium`, `nitrogen`, `oxygen`, and `iridium`.
The first two are personal machines i own, a custom PC and a StarLite 5. The third is a VPS and the fourth is a custom-built NAS.

## VMs

`sodium` and `nitrogen` can be built as VMs. Some services are disabled when building as a VM, such as connectivity to my personal network (because you don't have the keys) and some hardware-specific stuff.

You can run the VMs with the following commands. They will be launched as an SDL window, so you can interact with them graphically, and the shell it was launched from will have instructions on how to ssh into the VM. It will also have a command to shut down the VM. When the VM shuts down, either from the command, from the VM itself sending ACPI signals, or from closing the SDL window, the shell will be restored to its original state.

-   `nix run github:sodiboo/system#sodium`
-   `nix run github:sodiboo/system#nitrogen`

The VPS and NAS have a lot of network-dependent services that depend on persistent storage. It's not useful to build them as VMs, so i don't provide them as VMs.

### sodium

This is my main workstation. It's a desktop computer with a Ryzen 5 7600X, 32 GB of RAM, and an RX 7800 XT. I built it myself in early 2024.

It also has the following unique hardware:

-   Samsung Odyssey G9 monitor, which has a 5120x1440 resolution (32:9 aspect ratio).  
    This is a bit of a pain to configure, and one of the main reasons i started using niri.
-   Wooting Two HE, which is an analog mechanical keyboard.  
    It works just fine as a regular keyboard, but i need Wootility to configure it.
-   Razer Nari, which is a wireless headset with two audio outputs (game and chat).  
    For this, i have a nixos module at [`github:sodiboo/nixos-razer-nari`](https://github.com/sodiboo/nixos-razer-nari).
-   Launchpad Pro, which is an 8x8 MIDI button grid.  
    I don't use it much, but i play with it from time to time.
-   Some other Razer peripherals, namely a mouse and a mousepad, but they're not really unique.
    At least, i don't do anything special with them.

### nitrogen

This is my laptop. It's a StarLite 5, and is less interesting than sodium.

It has a 2880x1920 display (3:2 aspect ratio), and the most interesting parts about it is the fact that it has a touch screen and a pen.

niri doesn't work extremely well with a touch screen, so it's mostly a regular laptop. I use it for school and when i'm not at my desk.

### oxygen

This is a VPS with Contabo. It's their "VPS 1" with an external SSD, because that gives me more storage capcity than an NVMe drive and the performance difference likely won't ever matter to me. I installed NixOS on it using `nixos-infect`, because they charge for object storage if i want to upload a custom iso.

It doesn't really have any unique hardware; it's just a qemu guest. See `/web/` for all the services that run mainly on this one.

### iridium

This is an old Fujitsu "PRIMERGY MX130 S2" functioning as a NAS. It has a 500 GB hard drive for the OS, and then i crammed another five hard drives inside it, stuffing it completely full because it only likes to have 3 non-OS hard drives. These suckers are held in place by friction! No duct tape needed! I will trust it with all my data. There's not much to say about this, other than that i have "non-genuine RAM" that isn't "covered by warranty" so,, uh, lol. Currently i don't do much with it, but i will be using it to host backups, Jellyfin, and maybe some other stuff. Might become the brains for home automation and/or personal infrastucture stuff (e.g. wireguard/tailscale, DNS, etc).

## Files

Modules have a `*.mod.nix` extension, which is loaded in [`flake.nix`](/flake.nix). The structure of `*.mod.nix` files is essentially `{ <system>.modules :: arrayOf(nixosModule), <system>.home_modules :: arrayOf(homeModule) }`. They can also take the flake inputs at the top.

`<system>` is either `sodium`, `nitrogen` or more commonly `personal` which contains stuff common for both. There is also `oxygen` and `iridium`, which are headless servers and `universal` which is common to all four. `universal` will generally contain stuff like a command line environment (prompts, editors, tooling), whereas `personal` will contain stuff that doesn't/can't exist on the server, such as bluetooth, audio, GUI/Wayland environment (niri, waybar, etc), and leisure/games.

My secrets are managed using `sops-nix`, which encrypts the secrets into `secrets.yaml` and a key is storerd in my home directory to decrypt them at boot-time. You can still run my configuration without the secret key, but the secrets will be missing and some services will not work as a result.

Most modules have a self-explanatory name. Here are some of the less obvious ones:

-   [`hardware.mod.nix`](/hardware.mod.nix) has the equivalent of `nixos-generate-config --show-hardware-config` for each machine.
-   [`peripherals.mod.nix`](/peripherals.mod.nix) deals with some of the unique hardware i have.
-   [`home.mod.nix`](/home.mod.nix) handles setup of home-manager.
-   [`lock.mod.nix`](/lock.mod.nix) handles a lock script that blurs a screenshot of the screen.
-   [`login.mod.nix`](/login.mod.nix) uses the same script to blur just the wallpaper when logging in.
-   [`sodipkgs.mod.nix`](/sodipkgs.mod.nix) just has some of my nixpkgs PRs that haven't been merged yet.
-   [`vpn.mod.nix`](/vpn.mod.nix) handles a VPN connection i use to get around a firewall at school, though it doesn't work right now.
-   [`niri.mod.nix`](/niri.mod.nix) handles my niri configuration. I maintain [`github:sodiboo/niri-flake`](https://github.com/sodiboo/niri-flake), which is the backend for this.

These modules may be removed, renamed, merged, or split in the future. I'm not very good at naming things.
