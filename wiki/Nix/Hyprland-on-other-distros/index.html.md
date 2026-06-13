[Nix](../index.html)

Hyprland on Other Distros

# Hyprland on Other Distros

Using hyprland via Nix on distros that aren’t NixOS is very simple.

First, install nix with your package manager, be that `apt`, `pacman`, `dnf`, etc. The package
is almost always called `nix`.

For example:

```
sudo pacman -S nix
```

Then enable the daemon:

```
sudo systemctl enable --now nix-daemon
```

Advanced users might want to use [Home Manager](https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager). If you don’t know what
this is, just don’t.

Before you do anything, [enable flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes), by adding this to `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`:

```
experimental-features = nix-command flakes
```

once that is done, install Hyprland through `nix profile`:

From hyprnix (Recommended)From NixpkgsFrom the Flake

Installing Hyprland (and other hypr\* tools) can be done like so:

```
sudo nix profile add --profile /nix/var/nix/profiles/default github:hyprwm/hyprnix#hyprland
```

Replace `#hyprland` with a different app from the flake to install it (e.g. `#hyprpaper`)

You can get Hyprland directly from Nixpkgs:

```
sudo nix profile install --profile /nix/var/nix/profiles/default nixpkgs#hyprland
```

Note

Make sure to enable [Cachix](https://wiki.hypr.land/Nix/Cachix) first.

Warning

This builds the latest, unstable git branch.

```
sudo nix profile add --profile /nix/var/nix/profiles/default github:hyprwm/Hyprland
```

Since you’re using Hyprland outside of NixOS, it won’t be able to find graphics
drivers. To get around that, you can use [nixGL](https://github.com/guibou/nixGL).

Just install it like so:

```
sudo nix profile add --profile /nix/var/nix/profiles/default github:guibou/nixGL --impure
```

`--impure` is needed due to `nixGL`’s reliance on hardware information.

Since 0.53.2, `start-hyprland` will automatically use `nixGL` if needed. For versions before that,
you must use `nixGL start-hyprland`.

Lastly, if you are using a Login Manager, like SDDM or GDM, you need to symlink the `.desktop` file
like so:

```
sudo mkdir -p /usr/share/wayland-sessions
sudo ln -sf /nix/var/nix/profiles/default/share/wayland-sessions/hyprland.desktop /usr/share/wayland-sessions/hyprland.desktop
```

so that the login manager can find Hyprland.

## Upgrading / updating

In order to upgrade all your packages, you can run:

```
sudo nix profile upgrade --profile /nix/var/nix/profiles/default '.*'
```

Check the
[nix profile](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-profile.html)
command documentation for other upgrade options if that interests you.

Last updated on June 12, 2026

[Hyprland on NixOS](../Hyprland-on-NixOS/index.html "Hyprland on NixOS")[Hyprland on Home Manager](../Hyprland-on-Home-Manager/index.html "Hyprland on Home Manager")