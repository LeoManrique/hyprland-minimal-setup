# Desktop (Intel + NVIDIA) — Hyprland — RETIRED 2026-09-01

**This machine no longer runs Hyprland.** It was migrated to KDE Plasma on
2026-09-01 and is now tracked in the `kde-plasma-setup` repo under the same
device key. Nothing here is live any more.

The Hyprland stack (hyprland, hypridle, hyprlock, hyprpicker, hyprpolkitagent,
xdg-desktop-portal-hyprland, waybar, fuzzel, dunst, nwg-dock-hyprland, cliphist,
greetd, greetd-tuigreet) was removed from the box. Its `~/.config` Hyprland
directories were moved to `~/.config/_hyprland-retired-20260901/`, not deleted.

`configs/desktop-intel-nvidia/` is left in this repo as reference — several of
its system files (NVIDIA suspend, the Logitech wake rule, the MT7925 resume
hook) are hardware fixes that were copied into the KDE repo unchanged, and the
waybar/dock/script work may still be useful to `ideapad-flex-5`. Delete it if
you decide otherwise.

## Left undone at migration
Two items were open in this file and were never deployed under Hyprland. Both
were finally applied on the KDE side instead:
- foot `SF Mono:weight=medium` (+ `primary-paste=none`)
- xremap `--mouse` + `BTN_MIDDLE→BTN_LEFT`

## Hardware, for reference
Intel CPU (Gigabyte B760M GAMING X DDR4) · NVIDIA RTX 5060 Ti (nvidia-open-dkms)
· 2× 4K, DP-1 MSI MAG322UPF @120Hz + DP-2 LG ULTRAFINE @60Hz, both scale 1.25
· MediaTek MT7925 Wi-Fi · 32G swap partition.
