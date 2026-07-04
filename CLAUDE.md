# Leo Hyprland Configuration

## Always update

Always update both README.md and SETUP.md with enough information so that the configuration of Hyprland can be replicated on another device.

Also update tracking/{device-key} when a change is being done, but done include any detail, just a very concise tracking log so we can see what has been already done there.

Dont include stale information or leave update notes, just keep the latest information.

## Don't guess

Documentation is mirrored at wiki/ directory, check that before doing any configuration change.

## This repo is NOT the live config

Files in `configs/` are the git source of truth, but the live config lives in
`~/.config/` (and `/etc/` for greetd/system) as plain **copies**, not symlinks.
`configs/` is split into `shared/` + one folder per machine (`ideapad-flex-5`,
`desktop-intel-nvidia`): a file that differs per machine lives in its device
folder, everything identical lives in `shared/`. Editing `configs/` and reloading
does nothing — deploy first with `./deploy.sh <device-key>` (or copy the single
file, e.g. `cp configs/ideapad-flex-5/hypr/hyprland.lua ~/.config/hypr/`), then
`hyprctl reload` and verify.
