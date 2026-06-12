[Configuring](../../index.html)

[Basics](../index.html)

Autostart

# Autostart

Note

Looking for the old hyprlang syntax? Check the [0.54 wiki pages](https://wiki.hypr.land/0.54.0/).
Since Hyprland 0.55, hyprlang is deprecated in favor of lua.

Autostarting apps can be done by executing things on the `hyprland.start` event:

```
hl.on("hyprland.start", function () 
  hl.exec_cmd(terminal)
  hl.exec_cmd("nm-applet")
  hl.exec_cmd("waybar & hyprpaper & firefox") -- Execute waybar, hyprpaper, firefox
end)
```

`hl.exec_cmd()` will spawn an asynchronous process, so there is no need for `& disown` at the end.

In the same vein, you can spawn processes on exit by listening to `hyprland.shutdown`.

See more about `hl.on` over at [Expanding Functionality](https://wiki.hypr.land/Configuring/Advanced-and-Cool/Expanding-functionality)

Last updated on June 12, 2026

[Workspace Rules](../Workspace-Rules/index.html "Workspace Rules")