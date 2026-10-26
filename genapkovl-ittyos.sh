#!/bin/sh -e
# Собирает apkovl (наложение конфигурации) для live-образа ittyOS.
# Файлы берутся из подготовленной папки (её делает build.sh).

HOSTNAME="$1"
[ -n "$HOSTNAME" ] || { echo "usage: $0 hostname"; exit 1; }

OVERLAY="${ITTY_OVERLAY:-$HOME/aports/scripts/ittyos-overlay}"
[ -d "$OVERLAY" ] || { echo "нет папки оверлея: $OVERLAY"; exit 1; }

cleanup() { rm -rf "$tmp"; }
rc_add() { mkdir -p "$tmp"/etc/runlevels/"$2"; ln -sf /etc/init.d/"$1" "$tmp"/etc/runlevels/"$2"/"$1"; }

tmp="$(mktemp -d)"
trap cleanup EXIT

cp -a "$OVERLAY"/. "$tmp"/
mkdir -p "$tmp"/etc/apk

echo "$HOSTNAME" > "$tmp"/etc/hostname

cat > "$tmp"/etc/apk/world <<EOT
alpine-base
bash
nano
htop
curl
git
sudo
dialog
tzdata
chrony
chrony-openrc
clamav
freshclam
yara
e2fsprogs
dosfstools
sfdisk
syslinux
util-linux
EOT

for s in devfs dmesg mdev hwdrivers modloop; do rc_add $s sysinit; done
for s in modules sysctl hostname bootmisc swclock syslog networking; do rc_add $s boot; done
for s in chronyd; do rc_add $s default; done
for s in mount-ro killprocs savecache; do rc_add $s shutdown; done

chown -R root:root "$tmp"
tar -c -C "$tmp" . | gzip -9n > "$HOSTNAME.apkovl.tar.gz"
