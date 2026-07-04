# Desktop (Intel + NVIDIA) — Hyprland

Hardware: Intel CPU · NVIDIA GPU · 4K display (dpi-aware=yes, scale 1.25).

## Status
- [ ] Deploy + verify foot `SF Mono:weight=medium` (added in repo, not yet applied on this box)
- [ ] Deploy xremap `--mouse` + `BTN_MIDDLE→BTN_LEFT` (in shared repo; needs `systemctl --user daemon-reload && restart xremap.service` on this box)

## Notes
- Configs split: `configs/shared` + `configs/desktop-intel-nvidia`; deploy via `./deploy.sh desktop-intel-nvidia`.
- foot stays `size=11` + `dpi-aware=yes` here (the ideapad uses `size=12` + `dpi-aware=no`).
