# IdeaPad Flex 5 14ALC05 (82HU) — Hyprland migration

Hardware: AMD Ryzen 5 5500U (Radeon iGPU) · 1× eDP-1 1080p · QCA6174 wifi · battery + lid.
From: GNOME/Wayland. AMD path — no NVIDIA, no MT7925/Logitech suspend fixes.

## Status
- [x] Install official-repo packages (AMD-trimmed, no NVIDIA) — Hyprland 0.55.4
- [x] Install AUR: nwg-dock-hyprland, bluetui, xremap-hypr-bin
- [x] Deploy configs (eDP-1 monitor, single bar, battery module, no GPU module, plain suspend)
- [x] xremap user unit enabled; dark theme (adw-gtk3-dark + Papirus-Dark) set
- [x] Bluetooth already enabled + active
- [ ] xremap input access (sudo): input group + uinput module/rule  ← next
- [ ] First launch from TTY + verify lid-close/resume
- [ ] System: vconsole ter-118b, GRUB text console (after test)
- [ ] Disable gdm, getty login (after test)

## Notes
- Configs split: `configs/shared` + `configs/ideapad-flex-5`; deploy via `./deploy.sh ideapad-flex-5`.
- SF Mono already installed; yay present; suspend/resume already clean (deep/S3).
- Hibernate deferred (no resume= on cmdline, 8G swapfile) — using plain suspend.
