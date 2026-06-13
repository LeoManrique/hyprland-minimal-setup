-- ~/.config/hypr/hyprland.lua
-- Hyprland 0.55 config — LUA syntax (hyprlang is deprecated since 0.55).
-- Minimal "TTY-vibes" setup: no wallpaper, sharp corners, black background.
-- Reference: the local wiki mirror in ~/Documents/Hyprland/v0.55.4
-- Docs: https://wiki.hypr.land/Configuring/Basics/

--------------------------------------------------------------------------------
-- ENVIRONMENT (set before anything else)
--------------------------------------------------------------------------------
-- NVIDIA (RTX 5060 Ti / open modules) — required per the Nvidia wiki page.
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")   -- native Wayland for Electron apps

-- Toolkit / Wayland
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("XCURSOR_SIZE", "24")

--------------------------------------------------------------------------------
-- MONITORS  (default = auto / preferred mode)
--------------------------------------------------------------------------------
-- List outputs with:  hyprctl monitors all
-- Catch-all fallback (scale 1.25 on 4K is exact: 3840/1.25=3072, 2160/1.25=1728).
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.25 })
-- Physical layout: DP-2 on the LEFT, DP-1 on the RIGHT (each 3072px wide @ scale 1.25).
hl.monitor({ output = "DP-2", mode = "preferred", position = "0x0", scale = 1.25 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "3072x0", scale = 1.25 })

--------------------------------------------------------------------------------
-- LOOK & FEEL  (minimal / flat / black)
--------------------------------------------------------------------------------
hl.config({
  general = {
    border_size = 2,
    gaps_in = 4,
    gaps_out = 8,
    layout = "dwindle",
    -- Muted blue border (aa alpha = ~67%, dims nicely against black)
    ["col.active_border"]   = "rgba(33ccffaa)",
    ["col.inactive_border"] = "rgba(45454566)",
  },

  decoration = {
    rounding = 8,                 -- gently rounded corners
    blur   = { enabled = false }, -- off: minimal + better perf
    shadow = { enabled = false },
  },

  animations = {
    enabled = false,              -- instant/snappy. Set true if you want motion.
  },

  input = {
    kb_layout = "us",             -- <-- change to your layout if needed
    follow_mouse = 1,
    sensitivity = 0,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    background_color = "#000000", -- solid black, no wallpaper
  },

  -- Render XWayland apps unscaled (1:1 native pixels) instead of blurry-upscaling
  -- them at the fractional desktop scale. leogit is forced onto XWayland
  -- (GDK_BACKEND=x11 in its launcher) to use this -> sharp at 1.0.
  xwayland = {
    force_zero_scaling = true,
  },
})

--------------------------------------------------------------------------------
-- WINDOW RULES
--------------------------------------------------------------------------------
-- bluetui (the waybar bluetooth-click TUI) opens in a dedicated foot instance
-- launched with `--app-id=bluetui`, which Hyprland sees as the window `class`.
-- Float it as a small panel pinned to the top-right of the active monitor,
-- tucked just under the 26px bar. The waybar click toggles it (open ⇄ close)
-- and never stacks duplicates.
hl.window_rule({
  match = { class = "bluetui" },
  float = true,
  size  = { 860, 560 },
  -- Anchor by the known width (860 + 12 margin), NOT `window_w`: the move
  -- expression is evaluated before the size rule applies, so `window_w` would
  -- be the pre-resize width and the bigger window would overhang the edge.
  move  = { "monitor_w - 872", "40" },
})

--------------------------------------------------------------------------------
-- AUTOSTART
--------------------------------------------------------------------------------
hl.on("hyprland.start", function()
  -- Bring up the systemd user graphical session FIRST. We log in on a plain
  -- getty (no display manager), so nothing else starts `graphical-session.target`
  -- — and every unit bound to it (xremap, the polkit agent, the gvfs/portal
  -- services) would silently never run. A display manager used to do this for
  -- us. Import the Wayland env before starting the target so those services
  -- inherit WAYLAND_DISPLAY / the Hyprland instance. See SETUP.md Step 4.
  hl.exec_cmd(
    "systemctl --user import-environment WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP "
    .. "&& dbus-update-activation-environment --systemd WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP "
    .. "&& systemctl --user start hyprland-session.target"
  )
  -- Polkit auth agent (GUI privilege prompts)
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  -- Bar + notifications
  hl.exec_cmd("waybar")
  hl.exec_cmd("dunst")
  -- Idle / lock daemon
  hl.exec_cmd("hypridle")
  -- Clipboard history (text + images)
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
end)

-- Tear the graphical session back down on exit (SUPER + M) so the next launch
-- starts a clean session instead of leaving xremap/portals bound to a stale
-- WAYLAND_DISPLAY from the previous run.
hl.on("hyprland.shutdown", function()
  hl.exec_cmd("systemctl --user stop hyprland-session.target")
end)

--------------------------------------------------------------------------------
-- KEYBINDS  (mod = SUPER / Windows key)
--------------------------------------------------------------------------------
local mod = "SUPER"

-- Core
hl.bind(mod .. " + C", hl.dsp.exec_cmd("foot"))                          -- terminal (console)
hl.bind(mod .. " + R", hl.dsp.exec_cmd("tofi-drun --drun-launch=true"))      -- launcher
hl.bind(mod .. " + Space", hl.dsp.exec_cmd("tofi-drun --drun-launch=true"))  -- launcher (macOS Cmd+Space muscle memory)
hl.bind(mod .. " + Q", hl.dsp.window.close())                            -- close window (macOS Cmd+Q quit)
hl.bind(mod .. " + M", hl.dsp.exit())                                    -- exit Hyprland
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
hl.bind(mod .. " + L", hl.dsp.exec_cmd("hyprlock"))                      -- lock now
hl.bind(mod .. " + CTRL + Q", hl.dsp.exec_cmd("hyprlock"))               -- lock now (macOS-style Ctrl+Cmd+Q)
hl.bind(mod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))        -- reload config
hl.bind(mod .. " + E", hl.dsp.exec_cmd("hyprpicker -a"))                 -- pick color -> clipboard

-- Clipboard history picker (via tofi)
hl.bind(mod .. " + period", hl.dsp.exec_cmd("cliphist list | tofi | cliphist decode | wl-copy"))

-- Move focus
hl.bind(mod .. " + Left",  hl.dsp.focus({ direction = "l" }))
hl.bind(mod .. " + Right", hl.dsp.focus({ direction = "r" }))
hl.bind(mod .. " + Up",    hl.dsp.focus({ direction = "u" }))
hl.bind(mod .. " + Down",  hl.dsp.focus({ direction = "d" }))

-- Move window
hl.bind(mod .. " + SHIFT + Left",  hl.dsp.window.move({ direction = "l" }))
hl.bind(mod .. " + SHIFT + Right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mod .. " + SHIFT + Up",    hl.dsp.window.move({ direction = "u" }))
hl.bind(mod .. " + SHIFT + Down",  hl.dsp.window.move({ direction = "d" }))

-- Workspaces 1..10
for i = 1, 9 do
  hl.bind(mod .. " + " .. i, hl.dsp.focus({ workspace = i }))
  hl.bind(mod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end
hl.bind(mod .. " + 0", hl.dsp.focus({ workspace = 10 }))
hl.bind(mod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))

-- Scratchpad (special workspace)
hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- Mouse: drag = move, drag = resize
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag())
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize())

-- Screenshots (grim + slurp -> clipboard)
hl.bind("Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))     -- region
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("grim - | wl-copy"))            -- full screen

-- Media / brightness keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+"))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%-"))
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))
