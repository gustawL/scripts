#!/bin/bash
# author: Gustaw Lizak
# browser sandbox template

set -euo pipefail

export ORIG_UID="$(id -u)"
export ORIG_GID="$(id -g)"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$ORIG_UID}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

export HOST_DOWNLOADS="$XDG_RUNTIME_DIR/Downloads"
export HOST_LW_PROFILE="$XDG_RUNTIME_DIR/profile"
export HOST_LW_CACHE="$XDG_RUNTIME_DIR/cache"

mkdir -p "$HOST_LW_PROFILE" "$HOST_LW_CACHE"
chmod 700 "$HOST_LW_PROFILE" "$HOST_LW_CACHE"
mkdir -p "$HOST_DOWNLOADS"
chmod 700 "$HOST_DOWNLOADS"

export SANDBOX_RESOLV="$XDG_RUNTIME_DIR/resolv.conf"
echo "nameserver 10.0.2.3" > "$SANDBOX_RESOLV"

HIDRAW_ARGS=(--ro-bind-try /sys/class/hidraw /sys/class/hidraw)

for dev in /dev/hidraw*; do
  if [[ -c "$dev" ]]; then
    if udevadm info --query=property --name="$dev" | grep -q "^ID_VENDOR_ID=1050$"; then
      HIDRAW_ARGS+=(--dev-bind "$dev" "$dev")
      
      SYS_PATH=$(udevadm info --query=path --name="$dev")
      if [[ -n "$SYS_PATH" ]]; then
        HIDRAW_ARGS+=(--ro-bind-try "/sys$SYS_PATH" "/sys$SYS_PATH")
        
        PARENT_PATH=$(dirname "$SYS_PATH")
        HIDRAW_ARGS+=(--ro-bind-try "/sys$PARENT_PATH" "/sys$PARENT_PATH")
      fi
      
      MAJOR=$(udevadm info --query=property --name="$dev" | awk -F= '/^MAJOR=/{print $2}')
      MINOR=$(udevadm info --query=property --name="$dev" | awk -F= '/^MINOR=/{print $2}')
      if [[ -n "$MAJOR" && -n "$MINOR" ]]; then
        HIDRAW_ARGS+=(--ro-bind-try "/run/udev/data/c${MAJOR}:${MINOR}" "/run/udev/data/c${MAJOR}:${MINOR}")
      fi
    fi
  fi
done
export HIDRAW_FLAT="${HIDRAW_ARGS[*]:-}"

PID_FILE="$XDG_RUNTIME_DIR/netns.pid"
rm -f "$PID_FILE"

(
  while [ ! -s "$PID_FILE" ]; do sleep 0.1; done
  NS_PID=$(cat "$PID_FILE")
  exec slirp4netns --configure --disable-host-loopback --mtu=65520 "$NS_PID" tap0 > /dev/null 2>&1
) &
SLIRP_PID=$!

trap 'kill $SLIRP_PID 2>/dev/null || true' EXIT

unshare -U -n -r bash -c '
  echo $$ > "$1"; shift
  
  ip link set lo up
  
  while ! ip link show tap0 >/dev/null 2>&1; do sleep 0.1; done
  
  ip route add blackhole 192.168.0.0/16
  ip route add blackhole 172.16.0.0/12
  ip route add blackhole 10.0.0.0/8
    
  read -r -a HIDRAW_ARRAY <<< "$1"; shift
  UID_ARG="$1"; shift
  GID_ARG="$1"; shift
  RESOLV_ARG="$1"; shift
  
  exec bwrap \
    --seccomp 9 \
    --unshare-all \
    --share-net \
    --uid "$UID_ARG" \
    --gid "$GID_ARG" \
    --new-session \
    --die-with-parent \
    --clearenv \
    --proc /proc \
    --dev /dev \
    --tmpfs /tmp \
    --tmpfs /dev/shm \
    --tmpfs /run \
    --tmpfs /proc/sys \
    --dir /run/user \
    --dir "$XDG_RUNTIME_DIR" \
    --tmpfs "$HOME" \
    --dir "$HOME/Downloads" \
    --dir "$HOME/.config" \
    --dir "$HOME/.cache" \
    --ro-bind /bin /bin \
    --ro-bind /lib /lib \
    --tmpfs /lib/modules \
    --ro-bind /lib64 /lib64 \
    --ro-bind /usr /usr \
    --tmpfs /usr/src \
    --tmpfs /usr/include \
    --tmpfs /usr/share/doc \
    --tmpfs /usr/share/man \
    --tmpfs /usr/share/info \
    --tmpfs /usr/share/vulkan \
    --tmpfs /usr/share/glvnd \
    --tmpfs /usr/share/themes \
    --tmpfs /usr/share/icons \
    --tmpfs /proc/asound \
    --ro-bind /etc/ld.so.cache /etc/ld.so.cache \
    --ro-bind-try /etc/ssl /etc/ssl \
    --ro-bind "$RESOLV_ARG" /etc/resolv.conf \
    --ro-bind "$HOME/scripts/sandboxes/policies.json" /usr/lib64/librewolf/distribution/policies.json \
    --ro-bind /dev/null /proc/cmdline \
    --ro-bind /dev/null /proc/modules \
    --ro-bind /dev/null /proc/kallsyms \
    --ro-bind /dev/null /proc/config.gz \
    --ro-bind /dev/null /proc/interrupts \
    --ro-bind /dev/null /proc/buddyinfo \
    --ro-bind /dev/null /proc/iomem \
    --ro-bind /dev/null /proc/ioports \
    --ro-bind /dev/null /proc/partitions \
    --ro-bind /dev/null /proc/diskstats \
    --ro-bind /dev/null /proc/devices \
    --ro-bind /dev/null /proc/misc \
    --ro-bind /dev/null /proc/version \
    --ro-bind /dev/null /proc/uptime \
    --ro-bind /dev/null /proc/loadavg \
    --ro-bind /dev/null /proc/crypto \
    --ro-bind /dev/null /proc/cpuinfo \
    --ro-bind /dev/null /proc/meminfo \
    --ro-bind /dev/null /proc/stat \
    --ro-bind /dev/null /proc/vmstat \
    --ro-bind /dev/null /proc/zoneinfo \
    --ro-bind /dev/null /proc/swaps \
    --ro-bind /dev/null /proc/locks \
--ro-bind /dev/null /proc/kcore \
    --ro-bind /dev/null /proc/vmallocinfo \
    --ro-bind /dev/null /proc/kpagecount \
    --ro-bind /dev/null /proc/kpageflags \
    --ro-bind /dev/null /proc/kpagecgroup \
    --ro-bind /dev/null /proc/schedstat \
    --ro-bind /dev/null /proc/softirqs \
    --ro-bind /dev/null /proc/timer_list \
    --ro-bind /dev/null /proc/sysrq-trigger \
    --ro-bind /dev/null /proc/kmsg \
    --ro-bind /dev/null /proc/dma \
    --ro-bind /dev/null /proc/mtrr \
    --ro-bind /dev/null /proc/cgroups \
    --ro-bind /dev/null /proc/consoles \
    --ro-bind /dev/null /proc/filesystems \
    --ro-bind-try /dev/null /proc/keys \
    --ro-bind-try /dev/null /proc/key-users \
    --tmpfs /proc/bus \
    --tmpfs /proc/driver \
    --tmpfs /proc/irq \
    --tmpfs /proc/acpi \
    --tmpfs /proc/sysvipc \
    --tmpfs /proc/fs \
    --tmpfs /proc/tty \
    --ro-bind-try /etc/fonts /etc/fonts \
    --ro-bind-try /var/cache/fontconfig /var/cache/fontconfig \
    "${HIDRAW_ARRAY[@]}" \
    --ro-bind-try /etc/alsa /etc/alsa \
    --ro-bind-try /etc/asound.conf /etc/asound.conf \
    --ro-bind-try /usr/share/alsa /usr/share/alsa \
    --ro-bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" \
    --ro-bind-try "$XDG_RUNTIME_DIR/pipewire-0" "$XDG_RUNTIME_DIR/pipewire-0" \
    --bind "$HOST_DOWNLOADS" "$HOME/Downloads" \
    --bind "$HOST_LW_PROFILE" "$HOME/.config/librewolf" \
    --bind "$HOST_LW_CACHE" "$HOME/.cache/librewolf" \
    --setenv MOZ_ENABLE_WAYLAND 1 \
    --setenv MOZ_CUBEB_BACKEND alsa \
    --setenv XDG_RUNTIME_DIR "$XDG_RUNTIME_DIR" \
    --setenv WAYLAND_DISPLAY "$WAYLAND_DISPLAY" \
    --setenv HOME "$HOME" \
    /usr/bin/librewolf "$@" > /dev/null 2>&1 \
    9< "$HOME/scripts/sandboxes/filter.bpf"
' -- "$PID_FILE" "$HIDRAW_FLAT" "$ORIG_UID" "$ORIG_GID" "$SANDBOX_RESOLV" "$@" &

UNSHARE_PID=$!
wait "$UNSHARE_PID"
