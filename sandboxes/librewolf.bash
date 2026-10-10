#!/bin/bash
# author: Gustaw Lizak
# simple browser sandbox template

set -euo pipefail

XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

mkdir -p /tmp/Downloads
HOST_DOWNLOADS="/tmp/Downloads"

exec bwrap \
  --unshare-all \
  --share-net \
  --unshare-pid \
  --new-session \
  --die-with-parent \
  --clearenv \
  --proc /proc \
  --dev /dev \
  --tmpfs /tmp \
  --tmpfs /dev/shm \
  --tmpfs /run \
  --dir /run/user \
  --dir "$XDG_RUNTIME_DIR" \
  --dir /sys \
  --dir /sys/dev \
  --dir /sys/devices \
  --dir /sys/bus \
  --dir /sys/class \
  --tmpfs "$HOME" \
  --dir "$HOME/Downloads" \
  --ro-bind /bin /bin \
  --ro-bind /lib /lib \
  --ro-bind /usr /usr \
  --ro-bind /lib64 /lib64 \
  --ro-bind /etc/ld.so.cache /etc/ld.so.cache \
  --ro-bind-try /sys/dev /sys/dev \
  --ro-bind-try /sys/devices /sys/devices \
  --ro-bind-try /sys/bus /sys/bus \
  --ro-bind-try /sys/class /sys/class \
  --ro-bind-try /etc/ssl /etc/ssl \
  --ro-bind-try /etc/resolv.conf /etc/resolv.conf \
  --ro-bind-try /etc/fonts /etc/fonts \
  --ro-bind-try /var/cache/fontconfig /var/cache/fontconfig \
  --dev-bind /dev/hidraw7 /dev/hidraw7 \
  --dev-bind /dev/hidraw8 /dev/hidraw8 \
  --ro-bind-try /etc/alsa /etc/alsa \
  --ro-bind-try /etc/asound.conf /etc/asound.conf \
  --ro-bind-try /usr/share/alsa /usr/share/alsa \
  --ro-bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" \
  --ro-bind-try "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0" \
  --bind "$HOST_DOWNLOADS" "$HOME/Downloads" \
  --setenv MOZ_ENABLE_WAYLAND 1 \
  --setenv LIBGL_ALWAYS_SOFTWARE 1 \
  --setenv MOZ_WEBRENDER 0 \
  --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR" \
  --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
  --setenv HOME "$HOME" \
  /usr/bin/librewolf "$@"
