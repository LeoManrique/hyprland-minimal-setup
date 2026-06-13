# Leo Hyprland Configuration

## Always update

Always update both README.md and SETUP.md with enough information so that the configuration of Hyprland can be replicated on another device.

## Don't guess

Documentation is mirrored at wiki/ directory, check that before doing any configuration change.

## This repo is NOT the live config

Files in `configs/` are the git source of truth, but the live config lives in
`~/.config/` (and `/etc/` for greetd/system) as plain **copies**, not symlinks.
Editing `configs/` and reloading does nothing — deploy first, e.g.
`cp configs/hypr/hyprland.lua ~/.config/hypr/ && hyprctl reload`, then verify.
