# Minimal "TTY-vibes" Hyprland

A minimal, functional [Hyprland](https://hypr.land) desktop on **Arch Linux** —
black everything, no wallpaper, a thin black bar, a dmenu-style launcher, a text
login, and a text GRUB. Designed to grow from a bare TTY into a productive setup.

## What's here

| Path | What it is |
| --- | --- |
| **[SETUP.md](./SETUP.md)** | Full step-by-step reproduction guide (install → greeter → first launch) |
| [`configs/`](./configs) | Exact working copies of every config file |
| [`v0.55.4/`](./v0.55.4) | Offline mirror of the Hyprland wiki — the **Lua**-syntax reference |
| `html2md.py` | Small script used to convert the mirrored wiki HTML → Markdown |

## Highlights / hard-won notes

- **Config is Lua, not hyprlang** — since Hyprland 0.55, `~/.config/hypr/hyprland.lua`.
  Most online tutorials use the old `hyprland.conf` syntax and won't work. SETUP.md
  has an old→new translation table.
- **NVIDIA is optional** and clearly isolated (skip it on AMD/Intel).
- **Fractional-scaling + GTK3/webview apps** (Tauri/WebKitGTK) blur — SETUP.md
  documents the working fix (XWayland zero-scaling + `GDK_DPI_SCALE`).

Start with **[SETUP.md](./SETUP.md)**.

## Attribution

The [`v0.55.4/`](./v0.55.4) directory is an **unmodified offline mirror of the
official Hyprland wiki** (<https://wiki.hypr.land>), included here purely as a
reference. That content is the work of the **Hyprland project and its
contributors** and remains under its original license — not part of this repo's
own authorship.
