# Minimal "TTY-vibes" Hyprland — Reproduction Guide

A minimal, functional Hyprland desktop on **Arch Linux**: black everything, no
wallpaper, a thin black bar, dmenu-style launcher, text login, text GRUB.
Built to grow from a bare TTY into a productive setup.

Exact working copies of every config live in [`configs/`](./configs) next to this
file. The offline copy of the Hyprland wiki is in [`wiki/`](./wiki) (it's
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
| Launcher | `fuzzel` | dmenu-style, type-to-run, app icons (Papirus-Dark) |
| Bar | `waybar` | flat black, Nerd Font icon modules |
| Notifications | `dunst` | minimal, themeable |
| Idle/lock | `hypridle` + `hyprlock` | first-party |
| Login | plain `getty` | **no display manager** — text TTY login; Hyprland started manually with `start-hyprland` |
| Bootloader | GRUB text console | minimal |
| Polkit | `hyprpolkitagent` | GUI privilege prompts |

---

## Step 1 — Install packages

Already present on a typical GNOME-based Arch install: `pipewire`,
`wireplumber`, `xdg-desktop-portal-gtk`, `polkit` (omitted below). `--needed`
skips anything you already have.

```bash
sudo pacman -Syu --needed \
  hyprland foot waybar dunst fuzzel papirus-icon-theme \
  hypridle hyprlock hyprpicker hyprpolkitagent \
  xdg-desktop-portal-hyprland qt5-wayland qt6-wayland \
  ttf-jetbrains-mono-nerd grim slurp cliphist wl-clipboard brightnessctl \
  terminus-font bluez bluez-utils
```

> No display manager / greeter package is needed — login is the plain `getty`
> text console (Step 4).

> **gnome-keyring is intentionally removed.** On a getty login there is no PAM
> step to auto-unlock the GNOME login keyring, so every Hyprland launch popped
> an "Authentication required — the login keyring did not get unlocked" dialog.
> Since this is a minimal Hyprland setup with no apps that depend on the Secret
> Service, the fix is simply: `sudo pacman -Rns gnome-keyring`. It's an optional
> dep of git, github-cli, google-chrome, libsecret and VS Code — those fall back
> to a plaintext/basic store (Chrome) or re-prompt for sign-in (VS Code sync) if
> you use them. Reinstall + add `pam_gnome_keyring.so` to `/etc/pam.d/login`
> (auth `optional`, session `optional auto_start`) if you ever need real keyring.

> **Debloating the leftover GNOME desktop.** If you migrated from GNOME, the full
> desktop is still installed and does nothing on a getty + Hyprland box. Removed:
> `gdm gnome-shell mutter gnome-session gnome-settings-daemon gnome-control-center`
> `xdg-desktop-portal-gnome` (redundant — Hyprland + GTK portals already run, and
> the GNOME one can conflict) `gnome-shell-extension-dash-to-panel gnome-tour`
> `gnome-software gnome-user-docs gnome-backgrounds gnome-remote-desktop`
> `gnome-user-share gnome-color-manager gnome-menus` plus most apps (`nautilus`,
> calculator, text-editor, maps, music, weather, clocks, contacts, calendar, etc.).
> **Kept:** `gnome-system-monitor`, `gnome-disk-utility`.
>
> **Before a big `pacman -Rns` of the GNOME stack, dry-run it** (`pacman -Rsp …`)
> and mark genuinely-wanted packages explicit (`pacman -D --asexplicit <pkg>`) so
> the cascade doesn't orphan-remove them. On this box that rescued: `pipewire-pulse`
> (PulseAudio shim — audio dies without it), `noto-fonts-emoji`, `webkit2gtk-4.1`
> (webview/Tauri apps — see the fractional-scale gotcha below), `unzip`,
> `python-argcomplete`. `pacman -Qdtq` lists orphans to review afterward.

> **xremap: use the build that matches the compositor.** This box had
> `xremap-gnome-bin` left from GNOME; on Hyprland that's `xremap-hypr-bin` (both
> install `/usr/bin/xremap`, so the user `xremap.service` unit is unchanged — just
> swap the package and `systemctl --user restart xremap.service`). The wrong build
> only loses per-application remapping; device-level remaps work either way.

`bluez`/`bluez-utils` power the waybar `bluetooth` module. Enable the daemon:

```bash
sudo systemctl enable --now bluetooth
```

The bar's bluetooth icon (`󰂯`) toggles `bluetui` (AUR), a keyboard-driven TUI
for scanning/pairing/connecting — no commands to memorize. It opens in a
floating `foot` window (`--app-id=bluetui`) pinned to the top-right of the
active monitor via a `hl.window_rule` in `hyprland.lua`; the click is a true
toggle (`pkill -x bluetui || foot ...`), so clicking again closes it and it
never stacks duplicates:

```bash
yay -S --needed bluetui
```

The bar's volume icon left-click runs `configs/hypr/scripts/audio-picker`, a
small two-stage `fuzzel` chooser (pinned top-right like the bluetui panel):
first pick **Output** or **Input**, then pick the device (current default is
marked ●). The choice is set as default and
any already-running streams move onto it. No extra package — it's just `pactl`
+ `fuzzel` (both already installed). Right-click mutes and scroll changes
volume, so the quick actions stay on the icon. (Monitor sources are hidden.)

(`fuzzel` and `papirus-icon-theme` are in the official repos — already in the
`pacman` line above. The launcher shows app icons via the Papirus-Dark theme;
drop `icons-enabled`/`icon-theme` in `fuzzel.ini` for a pure-text look.)

> Use `-Syu` (full refresh+upgrade), **never** a bare `-Sy` — partial upgrades
> break Arch.

---

## Step 2 — NVIDIA (OPTIONAL — skip on AMD/Intel)

Hyprland runs fine on AMD/Intel with no special steps. **Only do this section if
you have an NVIDIA GPU.** Reference: [`wiki/Nvidia/`](./wiki/Nvidia).

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

> **These are copies, not symlinks.** The live config lives in `~/.config/`;
> editing `configs/` here and reloading does nothing until you re-copy. Re-run the
> relevant `cp` (then `hyprctl reload`) after every change.

Copy from [`configs/`](./configs) into place:

```bash
mkdir -p ~/.config/hypr ~/.config/foot ~/.config/waybar ~/.config/dunst ~/.config/fuzzel
cp -r configs/hypr/*       ~/.config/hypr/   # includes scripts/ (chmod +x them)
cp configs/foot/foot.ini   ~/.config/foot/
cp configs/waybar/*        ~/.config/waybar/
cp configs/dunst/dunstrc   ~/.config/dunst/
cp configs/fuzzel/fuzzel.ini ~/.config/fuzzel/
```

What each file is:

| File | Purpose |
| --- | --- |
| `hypr/hyprland.lua` | main config (Lua) — env, monitors, look, autostart, keybinds |
| `hypr/scripts/audio-picker` | fuzzel chooser to set the default audio device (waybar volume click) |
| `hypr/scripts/power-menu` | fuzzel power menu — lock/logout/suspend/hibernate/reboot/shutdown, with a confirm step on the irreversible ones (`SUPER + Escape`) |
| `hypr/hypridle.conf` | idle ladder: lock @5min, screen off @10min, suspend-then-hibernate @30min (hyprlang format) — see [Idle, lock & hibernate](#idle-lock--hibernate) |
| `hypr/hyprlock.conf` | minimal black lock screen w/ clock (hyprlang format) |
| `foot/foot.ini` | black terminal, `size=11` font |
| `waybar/config.jsonc` | bar modules: workspaces · clock · vol/bt/net/cpu/mem (Nerd Font glyphs, need `ttf-jetbrains-mono-nerd`) · tray. Volume: left-click → `audio-picker` (fuzzel device chooser), right-click mute, scroll = volume. Bluetooth: click → floating `bluetui` TUI (toggle). Both pinned top-right via window rules |
| `waybar/style.css` | flat solid-black bar |
| `dunst/dunstrc` | black notifications |
| `fuzzel/fuzzel.ini` | launcher: flat black, white-bar selection, app icons (Papirus-Dark) |

> **hypridle/hyprlock use the old `.conf` (hyprlang) format** — that's correct;
> only the main Hyprland config moved to Lua. Other `hypr*` tools didn't.

**Adjust for your hardware** (in `hyprland.lua`):
- **Monitors:** the `hl.monitor(...)` lines hardcode `DP-1`/`DP-2`, positions, and
  `scale = 1.25`. Run `hyprctl monitors all` to get your output names, then fix
  names/positions/scale. See [Monitors & scaling](#monitors--fractional-scaling).
- **Keyboard:** `input = { kb_layout = "us" }` — change if not US.
- **Focus:** `input = { follow_mouse = 0 }` — focus changes only on click, not on
  hover. Set back to `1` for classic focus-follows-mouse.

---

## Idle, lock & hibernate

`hypridle` (autostarted from `hyprland.lua`) drives an escalating idle ladder.
Edit `hypr/hypridle.conf`, then deploy + restart:

```bash
cp configs/hypr/hypridle.conf ~/.config/hypr/ && pkill -x hypridle; setsid hypridle &
```

| Idle | Action | Listener |
| --- | --- | --- |
| 5 min | lock screen | `loginctl lock-session` |
| 10 min | monitors off (DPMS) | `hyprctl dispatch dpms off` |
| 60 min | suspend (→ hibernate @120min) | `systemctl suspend-then-hibernate` |

**`suspend-then-hibernate`** suspends to RAM first (instant wake if you return
soon), then after a delay wakes briefly and hibernates to disk for a full
power-off. The delay lives in a systemd drop-in (the default estimate is
battery-based and never fires on a desktop, so it must be set explicitly):

```bash
sudo install -Dm644 configs/system/sleep.conf.d-hibernate.conf \
     /etc/systemd/sleep.conf.d/10-hibernate.conf      # HibernateDelaySec=60min
```

**Hibernate prerequisites** (all already true on this box — verify on a new one):

- **Swap ≥ hibernation image.** Hibernate writes RAM to swap. Kernel
  `image_size` (`cat /sys/power/image_size`, ~26.8 G here) must fit in swap
  (32 G partition). If swap is smaller than that, logind refuses to hibernate —
  enlarge swap.
- **`resume=` on the kernel cmdline** pointing at the swap partition's UUID
  (`resume=UUID=…` — already in `configs/system/grub.snippet` / GRUB cmdline).
- **`systemd` initrd hook** in `/etc/mkinitcpio.conf` `HOOKS` — it handles
  resume automatically (no separate `resume` hook needed with the systemd init).
- **NVIDIA only:** suspend/hibernate corrupt the GPU on resume unless you enable
  the driver's power-management services and preserve VRAM:
  ```bash
  sudo systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
  echo 'options nvidia NVreg_PreserveVideoMemoryAllocations=1' | \
      sudo tee /etc/modprobe.d/nvidia-power.conf
  sudo mkinitcpio -P     # rebuild initramfs after the modprobe change
  ```

Verify the system will accept it before trusting the timer:

```bash
busctl call org.freedesktop.login1 /org/freedesktop/login1 \
    org.freedesktop.login1.Manager CanSuspendThenHibernate   # expect: s "yes"
sudo systemctl suspend-then-hibernate                        # test manually once
```

---

## Step 4 — Login (plain getty, manual Hyprland start)

This setup uses **no display manager**. You log in at the normal Arch text
console (`getty` on tty1) and land at a plain shell. Hyprland is **not**
auto-started — you launch it by hand when you want the desktop. This is the
simplest, most robust path, and it sidesteps a nasty NVIDIA multi-monitor
console bug that breaks graphical/TUI greeters (see Step 6).

**a) Ensure `getty@tty1` is enabled** (it is by default on Arch):

```bash
sudo systemctl enable getty@tty1.service
```

**b) Start Hyprland manually.** After logging in, run:

```sh
start-hyprland
```

Exit with **SUPER + M**, which drops you straight back to the tty1 shell.

Make sure your login shell profile (`~/.zprofile` for zsh, `~/.bash_profile`
for bash) does **not** auto-exec Hyprland. The intended note in `~/.zprofile`:

```sh
# Hyprland is NOT auto-started. Login lands at a plain tty1 shell; start the
# desktop manually with:
#     start-hyprland
# `start-hyprland` is the official session wrapper (systemd/dbus user session,
# env import, portals) — bare `Hyprland` warns it's unsupported. Run it WITHOUT
# `exec` so that exiting Hyprland (SUPER + M) returns to this same tty1 shell
# instead of logging out.
```

> **Want auto-start back?** Append this guard to `~/.zprofile` to launch
> Hyprland automatically on tty1 login (drop `exec` if you'd rather return to
> the same shell on exit instead of logging out):
>
> ```sh
> if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
>   exec start-hyprland
> fi
> ```

> **Run `start-hyprland` without `exec`.** A bare `start-hyprland` keeps the
> login shell alive underneath, so SUPER + M returns to that tty1 prompt. Using
> `exec start-hyprland` would replace the shell and log you out on exit instead.

> **Use `start-hyprland`, not bare `Hyprland`.** The `/usr/bin/start-hyprland`
> wrapper (what `hyprland.desktop` itself execs) sets up the session properly;
> launching the raw `Hyprland` binary triggers a *"started without
> start-hyprland… highly not recommended"* warning. Either way, do **not**
> `sudo` it.

> **Why not greetd/tuigreet?** A `configs/greetd/` config is kept in the repo as
> an alternative, but it's **not used by default**: on mismatched dual monitors
> the NVIDIA text-console clone bug (Step 6) leaves the greeter zoomed/cropped,
> and the workaround (`fbdev=0`) black-screened this hardware entirely. A plain
> `getty` is readable and reliable; Hyprland fixes the displays once it starts.

**c) Hyprland raises the systemd graphical session itself.** A display manager
normally starts `graphical-session.target` on login — a plain `getty` does
**not**. Any user service bound to that target (`xremap`, `hyprpolkitagent`,
the gvfs / `xdg-desktop-portal` services, anything `WantedBy=graphical-session.target`)
would then silently never start. So `hyprland.lua` does it on the
`hyprland.start` event (and tears it down on `hyprland.shutdown`):

```lua
hl.on("hyprland.start", function()
  hl.exec_cmd(
    "systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP "
    .. "&& dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP "
    .. "&& systemctl --user start hyprland-session.target"
  )
  -- …rest of autostart…
end)

hl.on("hyprland.shutdown", function()
  hl.exec_cmd("systemctl --user stop hyprland-session.target")
end)
```

Importing the env **before** starting the target is what lets those services
inherit `WAYLAND_DISPLAY`. `hyprland-session.target` `BindsTo`
`graphical-session.target`, so starting it pulls the whole session up.

> **Symptom if this is missing:** `xremap` (and the polkit agent, portals, etc.)
> just don't run, even though Hyprland is up. Check with
> `systemctl --user is-active graphical-session.target` — if it's `inactive`
> while Hyprland runs, this bootstrap didn't fire. This is the one thing a
> display manager did for free that the bare `getty` path must do explicitly.

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

## Step 6 — Console font (login size)

On a HiDPI/4K panel the default console font is microscopic, which makes the
text login look tiny. Set a big bitmap font (`configs/system/vconsole.conf`):

```bash
sudo cp configs/system/vconsole.conf /etc/vconsole.conf   # FONT=ter-132b
```
`ter-132b` is the largest Terminus (16×32). Smaller steps: `ter-128b`, `ter-124b`.
On a 1080p screen, `ter-116b`/`ter-118b` is plenty. Applied at boot by
`systemd-vconsole-setup`; to apply now: `sudo setfont ter-132b`.

> **Gotcha (NVIDIA + mismatched dual monitors): the text console is zoomed into
> the top-left quarter on BOTH screens.** This hits *every* text console — the
> GRUB menu, the `getty` login, and shutdown messages. Symptom: the same content
> is mirrored on both monitors, zoomed, showing only the top-left chunk. Confirm
> with `cat /sys/class/graphics/fb0/virtual_size` (e.g. `3840,2160`) vs
> `/sys/class/graphics/fb0/modes` (e.g. `1920x1080`) — a 4K console *canvas*
> scanned out at 1080p.
> **Cause:** with `nvidia_drm.fbdev=1` (default since driver 570), NVIDIA drives
> the text console and **clones it to every monitor**. If the monitors are
> different models (here an MSI MAG322UPF + an LG ULTRAFINE, different EDID
> timings), the only mode NVIDIA trusts on both is **1920×1080@60**, so it scans
> that out while sizing the canvas to the 4K preferred mode → a 4K grid shown
> through a 1080p window, which each panel upscales.
> **Status: NOT solved — and don't burn time chasing it.** None of these helped:
> `video=CONNECTOR:MODE` (NVIDIA's kernel modules ignore it),
> `GRUB_GFXPAYLOAD_LINUX=text`, or kernel cmdline mode pins. **Do NOT set
> `nvidia_drm.fbdev=0`** to hand the console to `simpledrm`: on this hardware it
> produced a fully **black console / soft-lock after GRUB**, not a centered one.
> **What we do instead:** stop caring how the text console *looks*. The login is
> a plain `getty` (Step 4) — the prompt is legible in that top-left region (the
> big console font above helps), you log in, and **Hyprland drives both monitors
> correctly at native 4K**. The bug is specific to the *kernel text console*;
> a real Wayland compositor sets proper per-monitor modes and is unaffected.
> (Single-model identical monitors usually clone fine and won't hit this — there
> you could keep a graphical greeter.)

---

## Step 7 — Disable any display manager

This setup has **no** display manager (login is the plain `getty` from Step 4).
Migrating from GNOME/etc.? Disable the old DM so it doesn't grab the VT:

> **Don't use `--now`** — that kills your current GNOME/X session. Plain
> disable takes effect on the **next reboot**, keeping your current session safe.

```bash
sudo systemctl disable gdm      # or sddm / lightdm / greetd
# getty@tty1 (Step 4) then provides the text login
```

If a DM was set as the `display-manager.service` alias, disabling it also clears
that symlink. Reboot when ready. **Recovery:** Hyprland never auto-starts, so a
broken `hyprland.lua` can't lock you out — login always lands at a plain shell.
Fix the config and re-run `start-hyprland`, or `sudo systemctl enable gdm` to
fall back to a display manager.

---

## Step 8 — First launch & keybinds

Log in at tty1, then start the desktop manually with `start-hyprland` (do
**not** `sudo` it). `SUPER + M` exits back to the tty. Mod = `SUPER`.

| Keys | Action |
| --- | --- |
| `SUPER + C` | terminal (foot / console) |
| `SUPER + B` | default browser (`gtk-launch "$(xdg-settings get default-web-browser)"` — follows your `xdg-settings` default) |
| `SUPER + R` or `SUPER + Space` | launcher (fuzzel; latter is macOS Cmd+Space muscle memory) |
| `SUPER + Q` | close window (macOS Cmd+Q quit) |
| `SUPER + M` | exit Hyprland |
| `SUPER + SHIFT + R` | reload config |
| `SUPER + V` / `F` | float / fullscreen toggle |
| `SUPER + L` or `SUPER + CTRL + Q` | lock now (hyprlock; latter is macOS-style) |
| `SUPER + E` | color picker (hyprpicker) |
| `SUPER + .` | clipboard history (cliphist via fuzzel --dmenu) |
| `SUPER + Escape` | power menu (lock/logout/suspend/hibernate/reboot/shutdown via fuzzel --dmenu) |
| `SUPER + arrows` | move focus |
| `SUPER + CONTROL + arrows` | move window |
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

> **Limitation (high refresh + 4K OBS recording):** with the MSI panel at
> `3840x2160@160` and OBS recording 4K at a high fps (e.g. 80), recordings
> dropped almost all frames (encoding lag ~84%, render lag ~38%) and the
> desktop hitched under heavy tiling. Pinning the monitor to `3840x2160@120`
> **and** the OBS output to 60 fps cleared it up completely. This is a
> per-hardware balancing act, not a rule — match the monitor mode and OBS fps
> to what your GPU/encoder (here an RTX 5060 Ti / NVENC) can actually sustain;
> the exact numbers will differ on other displays/GPUs.

---

## Dark theme for GTK apps & Chrome

No GUI settings app is installed, so set the dark preference with `gsettings`
(it persists in `~/.config/dconf/user` across reboots):

```bash
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'   # GTK4/libadwaita + the xdg portal
gsettings set org.gnome.desktop.interface gtk-theme    'Adwaita-dark'  # GTK3 apps (e.g. gnome-system-monitor)
```

- `color-scheme=prefer-dark` is what the **xdg-desktop-portal** reports to apps
  that ask (Chrome's "system" theme, GTK4/libadwaita apps).
- **GTK3** apps don't read `color-scheme`; they follow the theme *name*, so
  `gtk-theme` must be a dark theme (`Adwaita-dark` is built into GTK3 — no
  package needed). Without this, GTK3 windows stay light even with prefer-dark.
- Already-open apps don't switch live — relaunch them.

> **If Chrome ignores it:** the portal only runs once `graphical-session.target`
> is up (Step 4c). If that target isn't active, Chrome can't read the preference
> and falls back to light — so a missing session bootstrap shows up as "Chrome
> went light after reboot." Verify with:
> `dbus-send --session --print-reply --dest=org.freedesktop.portal.Desktop /org/freedesktop/portal/desktop org.freedesktop.portal.Settings.Read string:'org.freedesktop.appearance' string:'color-scheme'`
> → `uint32 1` means prefer-dark.

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

## External A/V devices (iPhone webcam, DJI mic)

These are runtime peripherals, not part of the Hyprland config, but recorded
here so the setup is reproducible.

### iPhone as a USB webcam

There is **no native Continuity Camera on Linux**, and the off-the-shelf apps
were rejected: **DroidCam** watermarks unless you pay, and **Iriun** is
**Wi-Fi-only for iPhone** (its USB mode is Android-only). The chosen route is a
**self-built app** ("USBCam", built on a Mac Mini with Xcode) — the iPhone
captures its camera and serves it as a multipart-MJPEG HTTP stream that the
Linux host reaches over the cable via `usbmuxd`/`iproxy`. No watermark, no
Wi-Fi, full resolution.

**Linux prerequisites** (only `v4l2loopback` had to be added — `usbmuxd` /
`libimobiledevice`/`iproxy` are already present as iOS/PipeWire deps):

```bash
sudo pacman -S v4l2loopback-dkms     # official extra/ module → virtual /dev/video0
```

`exclusive_caps=1` is **required** or Chrome/Firefox/Zoom won't see the device:

```bash
# /etc/modprobe.d/v4l2loopback.conf
options v4l2loopback exclusive_caps=1 card_label="OBS Virtual Camera"
# /etc/modules-load.d/v4l2loopback.conf   (auto-load at boot)
v4l2loopback
```

```bash
sudo modprobe v4l2loopback           # creates /dev/video0 "OBS Virtual Camera"
v4l2-ctl --list-devices              # verify
```

**Wire protocol** (iPhone is the server; usbmux is host-initiated so the phone
must listen): TCP **:5000**, HTTP `multipart/x-mixed-replace; boundary=frame`,
JPEG frames. Linux receiver:

```bash
iproxy 5000:5000 &                                   # tunnel USB → iPhone:5000
ffmpeg -f mpjpeg -i http://127.0.0.1:5000 \
       -pix_fmt yuv420p -f v4l2 /dev/video0          # feed the virtual cam
```

> The iOS half (USBCam) lives in its own project, not this repo. Built/signed on
> a Mac Mini; a free Apple cert expires every 7 days. Status: app not yet built;
> the Linux side above is ready.

### DJI Mic Mini 2 (USB receiver)

Plug the receiver in and **power it ON** — DJI receivers act as a USB *drive*
when off and a UAC *audio device* only when on (off/asleep shows a
vendor-specific `class ff` interface and a ~once-per-minute re-enumeration loop,
never appearing in `/proc/asound/cards`). Once on it shows up as a PipeWire
source and is selectable in OBS / `pactl list short sources`. No driver needed.

## Quick gotcha recap

- Config is **Lua** (`hyprland.lua`), not hyprlang — ignore old tutorials.
- `hypridle.conf` / `hyprlock.conf` are still **hyprlang** `.conf` format.
- Launch Hyprland manually with `start-hyprland` from the tty1 shell, never as root.
- Monitor positions are **logical** pixels (after scale).
- **No display manager, no autostart** — `getty` login → plain shell → manual `start-hyprland`; `SUPER + M` returns to the tty.
- **No DM means `hyprland.lua` must start `graphical-session.target` itself** (Step 4c) — otherwise `xremap` / polkit / portals never run even though Hyprland is up.
- NVIDIA 50xx **requires** the open kernel modules.
- NVIDIA + mismatched dual monitors → the **text console** (GRUB/login/shutdown)
  is zoomed top-left; unsolved, and **don't** use `fbdev=0` (it black-screens).
  Hyprland itself renders both monitors fine.
- GTK3/webview apps + fractional scale = blur; see the section above.
- iPhone webcam = self-built USBCam app (MJPEG over `usbmuxd`/`iproxy`) + `v4l2loopback` (`exclusive_caps=1`); DroidCam (watermark) and Iriun (Wi-Fi-only on iOS) were rejected. DJI mic must be powered **on** to enumerate as audio.
