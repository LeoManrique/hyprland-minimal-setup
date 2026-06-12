#!/usr/bin/env bash
APPIMAGE="$(dirname "$(readlink -f "$0")")/leogit.AppImage"
if [ -z "${WEBKIT_DISABLE_DMABUF_RENDERER:-}" ] && [ -e /dev/nvidia0 ]; then
  export WEBKIT_DISABLE_DMABUF_RENDERER=1
fi
# Run on XWayland so Hyprland's xwayland:force_zero_scaling renders it 1:1 (sharp
# at scale 1.0) instead of blurry-upscaling this GTK3 webview at the fractional
# desktop scale. Resize the window to taste; it stays crisp.
export GDK_BACKEND=x11
# ~1.5x GTK scale. GDK_SCALE is integer-only, so use the fractional DPI lever to
# size the UI up while XWayland zero-scaling keeps it sharp at the 1.25 desktop.
export GDK_DPI_SCALE=1.5
exec "$APPIMAGE" "$@"
