# IdeaPad Flex 5 14ALC05 (82HU) — Hyprland migration

Hardware: AMD Ryzen 5 5500U (Radeon iGPU) · 1× eDP-1 1080p · QCA6174 wifi · battery + lid.
From: GNOME/Wayland. AMD path — no NVIDIA, no MT7925/Logitech suspend fixes.

## Status
- [x] Install official-repo packages (AMD-trimmed, no NVIDIA) — Hyprland 0.55.4
- [x] Install AUR: nwg-dock-hyprland, bluetui, xremap-hypr-bin
- [x] Deploy configs (eDP-1 monitor, single bar, battery module, no GPU module, plain suspend)
- [x] xremap user unit enabled; dark theme (adw-gtk3-dark + Papirus-Dark) set
- [x] Bluetooth already enabled + active
- [x] xremap input access (input group + uinput node/module) + autostart fixed
- [x] First launch from TTY — Hyprland runs; xremap live
- [x] Fonts: foot/fuzzel dpi-aware=no (157-DPI eDP-1 was ~1.6× huge); foot SF Mono size=12 weight=medium
- [x] Touchpad natural scrolling (input.touchpad.natural_scroll)
- [x] gdm disabled; plain getty + manual `start-hyprland` (verified post-reboot)
- [x] GNOME stripped (gdm/shell/mutter/session/settings-daemon/control-center + nautilus + gnome-keyring + portal-gnome, ~97 pkgs). Keepers pinned explicit first: pipewire-pulse webkitgtk-6.0 gvfs udisks2 ffmpeg gst-plugins-good poppler-glib unzip
- [x] Lid-close/resume verified (close + reopen resumes clean)
- [x] Console/GRUB: keeping stock defaults (1080p panel is legible; ter-118b/text-GRUB not needed) — migration complete

## Notes
- Configs split: `configs/shared` + `configs/ideapad-flex-5`; deploy via `./deploy.sh ideapad-flex-5`.
- foot/fuzzel now per-device (dpi-aware). Added shared `systemd/user/hyprland-session.target` (was missing → xremap/portals didn't autostart).
- SF Mono already installed; yay present; suspend/resume already clean (deep/S3).
- Hibernate deferred (no resume= on cmdline, 8G swapfile) — using plain suspend.
- xremap `--mouse` + `BTN_MIDDLE→BTN_LEFT`: middle click acts as left click.
