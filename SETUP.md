# Minimal "TTY-vibes" Hyprland — Reproduction Guide

A minimal, functional Hyprland desktop on **Arch Linux**: black everything, no
wallpaper, a thin black bar, dmenu-style launcher, text login, text GRUB.
Built to grow from a bare TTY into a productive setup.

Exact working copies of every config live in [`configs/`](./configs) next to this
file. The offline copy of the Hyprland wiki is in [`v0.55.4/`](./v0.55.4) (it's
the reference for the **Lua** config syntax — see the big gotcha below).

> **Tested on:** Arch Linux, Hyprland 0.55.x, dual 4K monitors, NVIDIA RTX 5060 Ti.
> Adjust monitor/scale/font values for your hardware (noted inline).

---

## ⚠️ The #1 gotcha: config is Lua, not hyprlang

**Since Hyprland 0.55, the config language is Lua** (`~/.config/hypr/hyprland.lua`),
and the old `hyprland.conf` (hyprlang) syntax is deprecated. **Almost every
tutorial/dotfiles repo online still uses the old syntax and will NOT work.**

| Old hyprlang (`hyprland.conf`) | New Lua (`hyprland.lua`) |
| --- | --- |
| `bind = SUPER, Q, exec, foot` | `hl.bind("SUPER + Q", hl.dsp.exec_cmd("foot"))` |
| `exec-once = waybar` | `hl.on("hyprland.start", function() hl.exec_cmd("waybar") end)` |
| `monitor=DP-1,1920x1080,0x0,1` | `hl.monitor({ output = "DP-1", mode = "1920x1080", position = "0x0", scale = 1 })` |
| `env = GTK_THEME,Nord` | `hl.env("GTK_THEME", "Nord")` |
| `general { border_size = 2 }` | `hl.config({ general = { border_size = 2 } })` |
| `source = ~/.config/hypr/x.conf` | `require("x")` |

Old-syntax docs (if ever needed): <https://wiki.hypr.land/0.54.0/>

---

## The stack

| Role | Choice | Why |
| --- | --- | --- |
| Compositor | `hyprland` | — |
| Terminal | `foot` | tiny, Wayland-native |
| Launcher | `tofi` (AUR) | dmenu-style, type-to-run |
| Bar | `waybar` | flat black, text modules |
| Notifications | `dunst` | minimal, themeable |
| Idle/lock | `hypridle` + `hyprlock` | first-party |
| Greeter | `greetd` + `tuigreet` | **text** login |
| Bootloader | GRUB text console | minimal |
| Polkit | `hyprpolkitagent` | GUI privilege prompts |

---

## Step 1 — Install packages

Already present on a typical GNOME-based Arch install: `pipewire`,
`wireplumber`, `xdg-desktop-portal-gtk`, `polkit` (omitted below). `--needed`
skips anything you already have.

```bash
sudo pacman -Syu --needed \
  hyprland foot waybar dunst \
  hypridle hyprlock hyprpicker hyprpolkitagent \
  xdg-desktop-portal-hyprland qt5-wayland qt6-wayland \
  ttf-jetbrains-mono-nerd grim slurp cliphist wl-clipboard brightnessctl \
  greetd greetd-tuigreet terminus-font
```

`tofi` is AUR-only:

```bash
yay -S --needed tofi          # or: paru -S tofi
```

> Use `-Syu` (full refresh+upgrade), **never** a bare `-Sy` — partial upgrades
> break Arch.

---

## Step 2 — NVIDIA (OPTIONAL — skip on AMD/Intel)

Hyprland runs fine on AMD/Intel with no special steps. **Only do this section if
you have an NVIDIA GPU.** Reference: [`v0.55.4/Nvidia/`](./v0.55.4/Nvidia).

**a) Driver.** Use the open kernel modules (**required** for 50xx-series and
newer; recommended for Turing/Ampere/Ada too):

```bash
sudo pacman -S --needed nvidia-open-dkms nvidia-utils egl-wayland linux-headers
# (use linux-lts-headers / linux-zen-headers to match your kernel)
```

**b) Early KMS.** Add the modules to `/etc/mkinitcpio.conf` (Arch usually does
this for you — check first):

```
MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)
```
On a hybrid Intel+NVIDIA laptop, put `i915` **first**. Then:
```bash
sudo mkinitcpio -P
```
Verify after reboot: `cat /sys/module/nvidia_drm/parameters/modeset` → `Y`.
(`modeset=1` is default on driver ≥ 570; Arch sets it automatically.)

**c) Env vars** — already included in `hyprland.lua` (the NVIDIA block near the
top). If you're **not** on NVIDIA, delete those three `hl.env(...)` lines:
```lua
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")   -- harmless to keep anywhere
```

---

## Step 3 — Drop in the config files

Copy from [`configs/`](./configs) into place:

```bash
mkdir -p ~/.config/hypr ~/.config/foot ~/.config/waybar ~/.config/dunst ~/.config/tofi
cp configs/hypr/*          ~/.config/hypr/
cp configs/foot/foot.ini   ~/.config/foot/
cp configs/waybar/*        ~/.config/waybar/
cp configs/dunst/dunstrc   ~/.config/dunst/
cp configs/tofi/config     ~/.config/tofi/
```

What each file is:

| File | Purpose |
| --- | --- |
| `hypr/hyprland.lua` | main config (Lua) — env, monitors, look, autostart, keybinds |
| `hypr/hypridle.conf` | lock after 5 min, screen off after 10 min (hyprlang format) |
| `hypr/hyprlock.conf` | minimal black lock screen w/ clock (hyprlang format) |
| `foot/foot.ini` | black terminal, `size=11` font |
| `waybar/config.jsonc` | bar modules: workspaces · clock · vol/net/cpu/mem · tray |
| `waybar/style.css` | flat solid-black bar |
| `dunst/dunstrc` | black notifications |
| `tofi/config` | centered vertical launcher, white-bar selection |

> **hypridle/hyprlock use the old `.conf` (hyprlang) format** — that's correct;
> only the main Hyprland config moved to Lua. Other `hypr*` tools didn't.

**Adjust for your hardware** (in `hyprland.lua`):
- **Monitors:** the `hl.monitor(...)` lines hardcode `DP-1`/`DP-2`, positions, and
  `scale = 1.25`. Run `hyprctl monitors all` to get your output names, then fix
  names/positions/scale. See [Monitors & scaling](#monitors--fractional-scaling).
- **Keyboard:** `input = { kb_layout = "us" }` — change if not US.

---

## Step 4 — Text greeter (greetd + tuigreet)

Copy the config (needs root):

```bash
sudo cp configs/greetd/config.toml /etc/greetd/config.toml
```

It launches `tuigreet` defaulting to Hyprland, with other sessions selectable
(press **F3**):

```toml
[terminal]
vt = 1
[default_session]
command = "tuigreet --remember --remember-session --time --sessions /usr/share/wayland-sessions --cmd start-hyprland"
user = "greeter"
```

---

## Step 5 — Minimal GRUB (text console)

Edit `/etc/default/grub`, set:

```
GRUB_TERMINAL_OUTPUT=console
```
(`configs/system/grub.snippet` shows the exact lines used.) Then regenerate:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

This forces a plain white-on-black text menu (overrides any theme/gfxmode).

---

## Step 6 — Console font (greeter size)

On a HiDPI/4K panel the default console font is microscopic, which makes the
greeter look tiny. Set a big bitmap font (`configs/system/vconsole.conf`):

```bash
sudo cp configs/system/vconsole.conf /etc/vconsole.conf   # FONT=ter-132b
```
`ter-132b` is the largest Terminus (16×32). Smaller steps: `ter-128b`, `ter-124b`.
On a 1080p screen, `ter-116b`/`ter-118b` is plenty. Applied at boot by
`systemd-vconsole-setup`; to apply now: `sudo setfont ter-132b`.

---

## Step 7 — Switch the display manager

> **Don't use `--now`** — that kills your current GNOME/X session. Plain
> enable/disable takes effect on the **next reboot**, keeping your current
> session safe.

```bash
sudo systemctl disable gdm      # or sddm / lightdm
sudo systemctl enable greetd
```

Reboot when ready. **Recovery:** if Hyprland/greetd misbehaves, switch to a TTY
(`Ctrl+Alt+F2`), log in, and run
`sudo systemctl disable greetd && sudo systemctl enable gdm && sudo reboot`.

---

## Step 8 — First launch & keybinds

Default session command is `start-hyprland` (do **not** `sudo` it). Mod = `SUPER`.

| Keys | Action |
| --- | --- |
| `SUPER + Q` | terminal (foot) |
| `SUPER + R` | launcher (tofi) |
| `SUPER + C` | close window |
| `SUPER + M` | exit Hyprland |
| `SUPER + SHIFT + R` | reload config |
| `SUPER + V` / `F` | float / fullscreen toggle |
| `SUPER + L` | lock now (hyprlock) |
| `SUPER + E` | color picker (hyprpicker) |
| `SUPER + .` | clipboard history (cliphist via tofi) |
| `SUPER + h/j/k/l` (or arrows) | move focus |
| `SUPER + SHIFT + h/j/k/l` | move window |
| `SUPER + 1..0` | switch workspace |
| `SUPER + SHIFT + 1..0` | move window to workspace |
| `SUPER + S` / `SUPER + SHIFT + S` | toggle / move-to scratchpad |
| `Print` / `SHIFT + Print` | region / full screenshot → clipboard |

If the config has an error, Hyprland still boots with emergency binds
`SUPER+Q` / `SUPER+R` / `SUPER+M`. Edit the live config and `hyprctl reload`.

---

## Monitors & fractional scaling

- List outputs: `hyprctl monitors all`.
- Empty `output = ""` is a **catch-all** rule; a per-output rule overrides it.
- **Position is in *logical* (post-scale) pixels.** At scale `s`, a monitor's
  logical width = native_width / s. So the monitor to its right starts at that x.
  - 4K @ scale 1.25 → logical 3072 wide → right monitor at `position = "3072x0"`.
  - 4K @ scale 1.2 → 3200. @ scale 1 → 3840.
- **Pick a scale that divides evenly** to avoid blur: on 4K, `1.25` (→3072×1728)
  and `1.2` (→3200×1800) are exact; `1.0`/`2.0` always are.

Live-test a scale without rebooting: edit `hyprland.lua`, `SUPER+SHIFT+R`
(or `hyprctl reload`).

---

## Gotcha: GTK3 / webview apps look blurry at fractional scale

GTK3 (and thus **Tauri / WebKitGTK-4.1** apps, Electron-ish webviews, etc.) has
**no Wayland fractional-scaling support**. At a fractional desktop scale (1.2,
1.25…) such an app renders at 1× and the compositor upscales it → **blurry**.

Levers (all imperfect, because toolkit scaling is integer-quantized):

1. **`GDK_SCALE=2`** → renders at 2×, sharp, but ~2× too big (and webview CSS
   viewport halves, truncating toolbars). Combine with in-app zoom (`Ctrl -`) to
   land between sizes.
2. **Run it on XWayland + unscale it** → sharp at native 1:1, then size it up
   with the fractional `GDK_DPI_SCALE`. **This is what worked best.**
3. **Real fix:** build the app against **GTK4 / webkitgtk-6.0**, which *does* do
   fractional scaling → crisp with zero hacks.

**Worked example** (the `leogit` Tauri app) — `configs/examples/leogit.sh`:
```bash
export WEBKIT_DISABLE_DMABUF_RENDERER=1   # NVIDIA WebKitGTK render fix
export GDK_BACKEND=x11                     # run on XWayland...
export GDK_DPI_SCALE=1.5                   # ...sized up; stays sharp 1:1
```
…paired with this in `hyprland.lua` (already included), which unscales **all**
XWayland apps (native-Wayland apps are unaffected):
```lua
hl.config({ xwayland = { force_zero_scaling = true } })
```

---

## Quick gotcha recap

- Config is **Lua** (`hyprland.lua`), not hyprlang — ignore old tutorials.
- `hypridle.conf` / `hyprlock.conf` are still **hyprlang** `.conf` format.
- Launch with **`start-hyprland`**, never as root.
- Monitor positions are **logical** pixels (after scale).
- Switch DMs **without `--now`**; keep a TTY recovery path.
- NVIDIA 50xx **requires** the open kernel modules.
- GTK3/webview apps + fractional scale = blur; see the section above.
