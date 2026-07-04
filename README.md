# Minimal "TTY-vibes" Hyprland

A minimal, functional [Hyprland](https://hypr.land) desktop on **Arch Linux** —
black everything, no wallpaper, a thin black bar, a dmenu-style launcher, a text
login, and a text GRUB. Designed to grow from a bare TTY into a productive setup.

## What's here

| Path | What it is |
| --- | --- |
| **[SETUP.md](./SETUP.md)** | Full step-by-step reproduction guide (install → greeter → first launch) |
| [`configs/`](./configs) | Config files, split into `shared/` + one folder per machine (`desktop-intel-nvidia`, `ideapad-flex-5`) — see [Repo layout](./SETUP.md#repo-layout-shared--per-device) |
| [`deploy.sh`](./deploy.sh) | `./deploy.sh <device-key>` — copies `shared/` + that machine's configs into `~/.config` |
| [`tracking/`](./tracking) | Per-machine migration checklists (`<device-key>.md`) |
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

- **macOS-style Alt = Command** — `xremap` (`configs/shared/xremap/`, autostarted by a
  user `xremap.service`) remaps `Alt+C/V/X/Z/…` to `Ctrl+…` for app shortcuts,
  with a `foot`-only block keeping the terminal on `Ctrl+Shift`. xremap sits in
  front of the compositor, so any `Alt+<key>` it remaps never reaches a Hyprland
  bind — `Alt+Q` is left out of the remap list on purpose so it falls through to
  Hyprland's close-window bind (`ALT + Q`, mirroring `SUPER + Q`). A trailing
  `Screenshots` block also maps `Alt+Ctrl+Shift+4` to the PrintScreen key (region
  grab) at the input layer, so it isn't tied to Hyprland. SETUP.md
  "macOS-style Alt = Command (xremap)" has the details.

- **App dock**: an always-visible bottom-center dock (`nwg-dock-hyprland`, AUR) with
  pinned + running apps, real Papirus icons, and click-to-focus/launch. GTK widget
  theme is **adw-gtk3-dark** so the right-click context menu (and all GTK apps)
  render dark. Themed
  minimal: transparent (icons-only, no panel) with a single cyan accent
  (`#33ccff`, matching the active-window border) for hover + running indicators,
  pinned to the main monitor (`-o DP-1`) so it doesn't hop between screens.
  No macOS-style icon magnification — that needs `transform: scale`, which GTK3
  CSS lacks (Plank can, but only as a janky XWayland app). eww and an in-`waybar`
  dock were both tried and rejected (eww has no tray + looked off; waybar's
  `image` module crashes on this box's gdk-pixbuf). See SETUP.md "App dock".

- **File manager**: **Thunar** (`SUPER + E`), chosen over Nautilus/Nemo/PCManFM
  for the best capability-per-dependency ratio with **no GNOME/Cinnamon session
  baggage**. One gotcha: on this minimal install its "Open Terminal Here" fails
  (`Could not find fallback TerminalEmulator`) — fixed by registering `foot` as
  the exo `TerminalEmulator` helper by hand (`configs/shared/xfce4/`). See SETUP.md
  "File manager (Thunar)".

- **Clickable, per-monitor workspace tags**: waybar's native `hyprland/workspaces`
  click can't switch workspaces under the Lua config — it sends `dispatch
  workspace N`, which Hyprland evaluates as Lua and rejects (`hl.dispatch(workspace
  N)` → syntax error). Rebuilt as ten `custom/ws1..ws10` modules that dispatch the
  correct `hl.dsp.focus({...})` form, with one bar per monitor so each shows only
  its own output's workspaces, and a tiny Python event listener refreshing the
  highlight (no `jq`/`socat`). Left-click focuses; **right-click renames** the
  workspace (fuzzel prompt → shows as `<id>: <name>`, persisted across reboots).
  Names clear automatically when a workspace empties out and Hyprland destroys it.
  See SETUP.md "Clickable workspace tags".

- **CPU / GPU bar indicators**: `custom/cpu` shows usage with a
  model/freq/temp/package-power tooltip (no per-core noise), and `custom/gpu`
  shows NVIDIA utilization (`nvidia-smi`) with a temp/VRAM/power tooltip. Both
  are fed by one `hypr/scripts/sys-stats` (the nvidia-smi call is cached and only
  the GPU module uses it). The CPU-watt tooltip field needs RAPL readable as
  non-root, via a udev rule that relaxes the PLATYPUS (CVE-2020-8694) lock. See
  SETUP.md "CPU and GPU indicators".

- **Close a whole workspace**: `SUPER + CTRL + SHIFT + Q` runs
  `scripts/close-workspace`, which gracefully closes every window on the active
  workspace (apps still get to run their own quit/save logic — no force-kill, no
  confirm), then focuses the **previous** workspace so the now-empty one collapses
  (Hyprland destroys a regular workspace once it's empty and undisplayed). Hyprland
  has no native "close workspace" dispatcher, so it enumerates clients with
  `hyprctl` + `jq`. Two gotchas it works around: (1) this is a Lua config, so
  `hyprctl dispatch` is evaluated as Lua — the close goes through
  `hl.dsp.window.close("address:..")`, not the bare `closewindow` (which is a Lua
  syntax error, the same trap the workspace tags hit); (2) closing is async and
  racy, so it re-snapshots and re-closes until the workspace is actually empty
  (bounded, so a window with an unsaved-changes dialog can't spin it forever).
  Deliberately one Shift away from the `SUPER + CTRL + Q` lock bind, mirroring the
  macOS-style `Q` = quit family.

- **Idle → screen-off → lock → hibernate**: `hypridle` escalates monitors-off
  @5min, lock @10min, `suspend-then-hibernate` @60min. The DPMS listener **must**
  use the Lua dispatch form (`hl.dsp.dpms({ action = "disable" })`) — the bare
  `hyprctl dispatch dpms off` is parsed as Lua and errors, so screen-off silently
  never fires. NVIDIA needs its sleep services +
  `NVreg_PreserveVideoMemoryAllocations=1` or it corrupts on resume; swap must be
  ≥ the kernel hibernation image. See SETUP.md "Idle, lock & hibernate".

- **Suspend fixes (desktop hardware)**: two machine-specific suspend bugs, both
  fixed at the system level (`configs/desktop-intel-nvidia/system/`; the AMD
  laptop needs neither). A **Logitech receiver**
  (`046d:c548`) armed as a USB wake source made the box wake itself ~14s after
  every suspend — disarmed with a udev rule. The **MediaTek MT7925** Wi-Fi card
  (`mt7925e`) fails PCI resume with `-110` (ETIMEDOUT) and comes back dead — a
  `systemd-sleep` hook reloads the driver across sleep. See SETUP.md
  "Power management / suspend fixes".

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
