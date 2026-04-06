#!/bin/bash
# author: Gustaw Lizak
# simple browser sandbox template

USER_ID=69
GROUP_ID=69
SANDBOX_PROFILE="$HOME/.local/share/chromium-sandbox"
PUBLIC_DATA="$HOME/public"
mkdir -p "$SANDBOX_PROFILE" "$PUBLIC_DATA"
bwrap \
  --unshare-all \
  --share-net \
  --unshare-pid \
  --uid "$USER_ID" \
  --gid "$GROUP_ID" \
  --new-session \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp/test \
  --dir "$XDG_RUNTIME_DIR" \
  --ro-bind /bin /bin \
  --ro-bind /lib /lib \
  --ro-bind /usr /usr \
  --ro-bind /lib64 /lib64 \
  --ro-bind /usr/lib/gcc /usr/lib/gcc \
  --ro-bind /etc/ssl /etc/ssl \
  --ro-bind /etc/resolv.conf /etc/resolv.conf \
  --ro-bind /etc/ld.so.cache /etc/ld.so.cache \
  --ro-bind /usr/share/zoneinfo /usr/share/zoneinfo \
  --ro-bind-try /usr/share/glvnd /usr/share/glvnd \
  \
  --dev-bind /dev/dri/renderD128 /dev/dri/renderD128 \
  --dev-bind /dev/shm /dev/shm \
  \
  --ro-bind /sys /sys \
  --ro-bind-try /run/udev /run/udev \
  $(for hid in /dev/hidraw*; do [ -e "$hid" ] && echo "--dev-bind $hid $hid"; done) \
  \
  --dev-bind-try /dev/snd /dev/snd \
  --ro-bind-try /etc/alsa /etc/alsa \
  --ro-bind-try /etc/asound.conf /etc/asound.conf \
  --ro-bind-try /usr/share/alsa /usr/share/alsa \
  --ro-bind-try "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0" \
  --ro-bind-try "$XDG_RUNTIME_DIR/bus" "$XDG_RUNTIME_DIR/bus" \
  \
  --ro-bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" \
  \
  --bind "$SANDBOX_PROFILE" "$HOME" \
  --bind "$PUBLIC_DATA" "$HOME/public" \
  \
  /usr/bin/chromium-browser-beta \
    --ozone-platform=wayland \
    --force-dark-mode \
    --enable-features=WebUIDarkMode,WebRTCPipeWireCapturer \
    --alsa-output-device=default \
    --ignore-gpu-blocklist \
    --disable-gpu-memory-buffer-video-frames \
    --no-pings
