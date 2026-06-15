# Minimal "TTY-vibes" Hyprland

A minimal, functional [Hyprland](https://hypr.land) desktop on **Arch Linux** —
black everything, no wallpaper, a thin black bar, a dmenu-style launcher, a text
login, and a text GRUB. Designed to grow from a bare TTY into a productive setup.

## What's here

| Path | What it is |
| --- | --- |
| **[SETUP.md](./SETUP.md)** | Full step-by-step reproduction guide (install → greeter → first launch) |
| [`configs/`](./configs) | Exact working copies of every config file |
| [`wiki/`](./wiki) | Offline mirror of the Hyprland wiki — the **Lua**-syntax reference |
| `html2md.py` | Small script used to convert the mirrored wiki HTML → Markdown |

## Highlights / hard-won notes

- **Config is Lua, not hyprlang** — since Hyprland 0.55, `~/.config/hypr/hyprland.lua`.
  Most online tutorials use the old `hyprland.conf` syntax and won't work. SETUP.md
  has an old→new translation table.
- **NVIDIA is optional** and clearly isolated (skip it on AMD/Intel).
- **Fractional-scaling + GTK3/webview apps** (Tauri/WebKitGTK) blur — SETUP.md
  documents the working fix (XWayland zero-scaling + `GDK_DPI_SCALE`).
- **gnome-keyring removed** — it popped an unlock dialog on every getty login
  (no PAM step to auto-unlock it). Uninstalled; SETUP.md Step 1 explains why.
- **Leftover GNOME desktop stripped** — gdm/shell/mutter/session/control-center/
  portal-gnome and most apps removed (kept system-monitor + disk-utility). SETUP.md
  Step 1 lists what to protect from the `-Rns` cascade (pipewire-pulse, webkit, …)
  and the `xremap-gnome-bin` → `xremap-hypr-bin` swap.

- **App dock**: an always-visible bottom-center dock (`nwg-dock-hyprland`, AUR) with
  pinned + running apps, real Papirus icons, and click-to-focus/launch. Themed
  minimal: transparent (icons-only, no panel) with a single cyan accent
  (`#33ccff`, matching the active-window border) for hover + running indicators,
  pinned to the main monitor (`-o DP-1`) so it doesn't hop between screens.
  No macOS-style icon magnification — that needs `transform: scale`, which GTK3
  CSS lacks (Plank can, but only as a janky XWayland app). eww and an in-`waybar`
  dock were both tried and rejected (eww has no tray + looked off; waybar's
  `image` module crashes on this box's gdk-pixbuf). See SETUP.md "App dock".

- **Clickable, per-monitor workspace tags**: waybar's native `hyprland/workspaces`
  click can't switch workspaces under the Lua config — it sends `dispatch
  workspace N`, which Hyprland evaluates as Lua and rejects (`hl.dispatch(workspace
  N)` → syntax error). Rebuilt as ten `custom/ws1..ws10` modules that dispatch the
  correct `hl.dsp.focus({...})` form, with one bar per monitor so each shows only
  its own output's workspaces, and a tiny Python event listener refreshing the
  highlight (no `jq`/`socat`). See SETUP.md "Clickable workspace tags".

- **Idle → lock → hibernate**: `hypridle` escalates lock @5min, monitors-off
  @10min, `suspend-then-hibernate` @30min. NVIDIA needs its sleep services +
  `NVreg_PreserveVideoMemoryAllocations=1` or it corrupts on resume; swap must be
  ≥ the kernel hibernation image. See SETUP.md "Idle, lock & hibernate".

- **High refresh vs 4K OBS recording**: 4K@160 + high-fps OBS recording dropped
  ~84% of frames; capping the monitor to 120 Hz and OBS to 60 fps fixed it. A
  per-hardware tuning note (not a fixed rule) — see SETUP.md "Monitors & scaling".

- **External A/V**: iPhone-as-webcam over USB via a **self-built MJPEG app**
  (`usbmuxd`/`iproxy` + `v4l2loopback`; no native Continuity Camera on Linux, and
  DroidCam/Iriun were rejected) and the DJI Mic Mini 2 receiver — both documented
  in SETUP.md ("External A/V devices").

Start with **[SETUP.md](./SETUP.md)**.

## Attribution

The [`wiki/`](./wiki) directory is an **offline mirror of the
official Hyprland wiki** (<https://wiki.hypr.land>), included here purely as a
reference. That content is the work of the **Hyprland project and its
contributors** and remains under its original license — not part of this repo's
own authorship.
