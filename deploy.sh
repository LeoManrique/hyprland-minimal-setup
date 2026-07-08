#!/usr/bin/env bash
# deploy.sh <device-key> — copy the live config into place for one machine.
#
#   ./deploy.sh ideapad-flex-5
#   ./deploy.sh desktop-intel-nvidia
#
# Configs are split under configs/:
#   shared/       files identical on every machine
#   <device-key>/ files that differ on that machine (override/extend shared)
# A given relative path lives in exactly one of the two, so deploying = the union
# of shared + <device-key>. This copies the USER-SPACE config only
# (~/.config, ~/.cache, ~/.local) — the frequently-redeployed stuff, no sudo.
#
# System files (configs/*/system, configs/shared/greetd) go to /etc, /usr/lib,
# etc. and are one-time sudo steps — deploy them by hand per SETUP.md.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
dev="${1:-}"
avail="$(cd "$here/configs" 2>/dev/null && ls -d */ 2>/dev/null | tr -d / | grep -v '^shared$' | paste -sd', ')"
if [ -z "$dev" ] || [ ! -d "$here/configs/$dev" ]; then
  echo "usage: $0 <device-key>   (available: ${avail:-none})" >&2
  exit 1
fi

copytree() {   # copytree <srcroot>  — copy one config root into the live dirs
  local s="$1"; [ -d "$s" ] || return 0
  mkdir -p ~/.config/hypr/scripts ~/.config/foot ~/.config/fuzzel ~/.config/dunst \
           ~/.config/waybar ~/.config/bluetui ~/.config/gtk-3.0 ~/.config/xremap \
           ~/.config/systemd/user ~/.config/nwg-dock-hyprland ~/.config/xfce4 \
           ~/.local/share/xfce4/helpers ~/.cache
  [ -d "$s/hypr" ]          && cp -r "$s/hypr/."          ~/.config/hypr/
  [ -d "$s/foot" ]          && cp -r "$s/foot/."          ~/.config/foot/
  [ -d "$s/fuzzel" ]        && cp -r "$s/fuzzel/."        ~/.config/fuzzel/
  [ -d "$s/dunst" ]         && cp -r "$s/dunst/."         ~/.config/dunst/
  [ -d "$s/waybar" ]        && cp -r "$s/waybar/."        ~/.config/waybar/
  [ -d "$s/bluetui" ]       && cp -r "$s/bluetui/."       ~/.config/bluetui/
  [ -d "$s/gtk-3.0" ]       && cp -r "$s/gtk-3.0/."       ~/.config/gtk-3.0/
  [ -d "$s/xremap" ]        && cp -r "$s/xremap/."        ~/.config/xremap/
  [ -d "$s/systemd/user" ]  && cp -r "$s/systemd/user/."  ~/.config/systemd/user/
  [ -f "$s/nwg-dock-hyprland/style.css" ] && cp "$s/nwg-dock-hyprland/style.css" ~/.config/nwg-dock-hyprland/
  [ -f "$s/nwg-dock-hyprland/pinned" ]    && cp "$s/nwg-dock-hyprland/pinned"    ~/.cache/nwg-dock-pinned
  [ -d "$s/xfce4/helpers" ] && cp -r "$s/xfce4/helpers/." ~/.local/share/xfce4/helpers/
  [ -f "$s/xfce4/helpers.rc" ] && cp "$s/xfce4/helpers.rc" ~/.config/xfce4/
  return 0   # don't let a trailing false [ -f ] test trip `set -e` at the caller
}

copytree "$here/configs/shared"
copytree "$here/configs/$dev"
chmod +x ~/.config/hypr/scripts/* 2>/dev/null || true

echo "Deployed shared + $dev → ~/.config (+ ~/.cache, ~/.local)."
echo "System files (configs/$dev/system, configs/shared/system) are manual sudo steps — see SETUP.md."
