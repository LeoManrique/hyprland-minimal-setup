[Configuring](../../index.html)

[Layouts](../index.html)

Monocle Layout

# Monocle Layout

Note

Looking for the old hyprlang syntax? Check the [0.54 wiki pages](https://wiki.hypr.land/0.54.0/).
Since Hyprland 0.55, hyprlang is deprecated in favor of lua.

Monocle is a layout where windows are always taking up the entire available space.

[
](https://dl.hypr.land/wiki/demo_monocle.mp4)

## Quirks

Due to how layouts work, `hl.dsp.window.cycle_next()` will not work with Monocle. For cycling monocle
windows, either use `hl.dsp.layout("cyclenext")` or `hl.dsp.window.cycle_next({ tiled = true })`.

## Layout messages

Dispatcher `hl.dsp.layout(msg)` params:

| name | description | params |
| --- | --- | --- |
| cyclenext | cycle to the next window | none |
| cycleprev | cycle to the previous window | none |

Last updated on June 12, 2026

[Scrolling Layout](../Scrolling-Layout/index.html "Scrolling Layout")[Custom Layouts](../Custom-Layouts/index.html "Custom Layouts")