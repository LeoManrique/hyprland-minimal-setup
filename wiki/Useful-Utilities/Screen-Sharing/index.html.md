[Useful Utilities](../index.html)

Screen sharing

# Screen sharing

Screensharing is done through PipeWire on Wayland.

## Prerequisites

Make sure you have `pipewire`, `wireplumber` and
[`xdg-desktop-portal-hyprland`](https://wiki.hypr.land/Hypr-Ecosystem/xdg-desktop-portal-hyprland)
installed, enabled and running if you don’t have them yet.

Ensure that the `bitdepth` set in your configuration
matches that of your physical monitor.
See [Monitors](https://wiki.hypr.land/Configuring/Basics/Monitors).

## Screensharing

Read
[this amazing gist by Bruno Ancona Sala](https://gist.github.com/brunoanc/2dea6ddf6974ba4e5d26c3139ffb7580)
for a great tutorial.

## XWayland

If your screensharing application is running under XWayland (like Discord or
Skype), it can only see other XWayland windows and cannot share an entire
screen or a Wayland window.

The KDE team has implemented a workaround for this called
[xwaylandvideobridge](https://invent.kde.org/system/xwaylandvideobridge). You
can use
[this AUR package](https://aur.archlinux.org/packages/xwaylandvideobridge-git)
on Arch Linux. Note that Hyprland currently doesn’t support the way it tries to
hide the main window, so you will have to create some window rules to achieve
the same effect. See
[this issue](https://invent.kde.org/system/xwaylandvideobridge/-/issues/1) for
more information. For example:

```
windowrule {
    name = xwayland-video-bridge-fixes
    match:class = xwaylandvideobridge

    no_initial_focus = true
    no_focus = true
    no_anim = true
    no_blur = true
    max_size = 1 1
    opacity = 0.0
}
```

Last updated on June 12, 2026

[Wallpapers](../Wallpapers/index.html "Wallpapers")[Screenshots & Recording](../Screenshots-and-Recording/index.html "Screenshots & Recording")