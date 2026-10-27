#!/bin/sh
# build.sh - автоматическая сборка ittyOS (ISO и rootfs для WSL)
#
#   ./build.sh setup   (root)       поставить зависимости, создать пользователя builder
#   ./build.sh iso     (builder)    собрать ISO
#   ./build.sh wsl     (root)       собрать rootfs-архив для wsl --import
#   ./build.sh stage                только подготовить оверлей (для проверки)
#   ./build.sh apply   (root)       применить оверлей к РАБОТАЮЩЕЙ системе (обновить установленную ittyOS)
#
# Переменные: OUT (куда класть результат, по умолчанию ~/iso или ~/out),
#             COPY_TO (доп. папка, по умолчанию /mnt/c/WSL если существует),
#             ALPINE (версия, по умолчанию 3.24)

set -e

HERE=$(cd "$(dirname "$0")" && pwd)
ALPINE="${ALPINE:-3.24}"
WORK="${WORK:-$HOME/ittyos-work}"
STAGE="$WORK/stage"

say() { printf '\033[36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[31mошибка:\033[0m %s\n' "$*" >&2; exit 1; }

# Готовит оверлей: копирует файлы, красит motd, ставит права
stage() {
	say "preparing the overlay"
	rm -rf "$STAGE"
	mkdir -p "$STAGE"
	cp -a "$HERE/overlay/." "$STAGE/"
	E=$(printf '\033')
	sed -e "s/{CY}/${E}[36m/g" -e "s/{R}/${E}[0m/g" \
	    -e "s/{B}/${E}[1m/g" -e "s/{D}/${E}[2m/g" \
	    "$STAGE/etc/motd.in" > "$STAGE/etc/motd"
	rm -f "$STAGE/etc/motd.in"
	VER=$(cat "$HERE/VERSION" | tr -d '[:space:]')
	# Единый файл версии для проверки обновлений и скриптов
	printf '%s\n' "$VER" > "$STAGE/etc/ittyos-version"
	for f in etc/os-release etc/issue etc/motd usr/bin/flowkit usr/bin/install-ittyos; do
		sed -i "s/@VERSION@/$VER/g" "$STAGE/$f"
	done
	chmod 755 "$STAGE"/usr/bin/*
	chmod 644 "$STAGE"/usr/share/backgrounds/ittyos/* "$STAGE"/usr/share/pixmaps/* "$STAGE"/usr/share/ittyos/yara/*
	chmod 644 "$STAGE"/etc/os-release "$STAGE"/etc/issue "$STAGE"/etc/motd \
	          "$STAGE"/etc/profile.d/flowkit.sh "$STAGE"/etc/ittyos/dialogrc \
	          "$STAGE"/etc/ittyos-version
	if [ -d "$STAGE/etc/xdg/autostart" ]; then
		chmod 644 "$STAGE"/etc/xdg/autostart/*.desktop 2>/dev/null || true
	fi
}

cmd_setup() {
	[ "$(id -u)" = 0 ] || die "setup запускается от root"
	say "установка зависимостей"
	apk update
	apk add alpine-sdk alpine-conf xorriso squashfs-tools mtools syslinux \
	        grub grub-efi git sudo dialog
	if ! id builder >/dev/null 2>&1; then
		mkdir -p /home
		adduser -D builder
	fi
	mkdir -p /home/builder
	chown builder:builder /home/builder
	addgroup builder abuild 2>/dev/null || true
	addgroup builder wheel 2>/dev/null || true
	mkdir -p /etc/sudoers.d
	echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel
	# Папка со сборкой должна быть доступна builder
	say "готово. Дальше: su - builder, затем ./build.sh iso"
}

cmd_iso() {
	[ "$(id -u)" != 0 ] || die "iso запускается от обычного пользователя (su - builder), не от root"
	OUT="${OUT:-$HOME/iso}"
	stage

	[ -f "$HOME"/.abuild/abuild.conf ] || [ -n "$(ls "$HOME"/.abuild/*.rsa 2>/dev/null)" ] || {
		say "создание ключа подписи"
		abuild-keygen -i -a -n
	}

	if [ -d "$HOME/aports/.git" ]; then
		say "aports уже есть"
	else
		say "загрузка aports ($ALPINE-stable)"
		git clone --depth=1 -b "$ALPINE-stable" https://gitlab.alpinelinux.org/alpine/aports.git "$HOME/aports"
	fi

	SC="$HOME/aports/scripts"
	say "копирование профиля ittyOS"
	cp "$HERE/mkimg.ittyos.sh" "$SC/"
	cp "$HERE/genapkovl-ittyos.sh" "$SC/"
	chmod +x "$SC/genapkovl-ittyos.sh"
	rm -rf "$SC/ittyos-overlay"
	cp -a "$STAGE" "$SC/ittyos-overlay"

	mkdir -p "$OUT"
	say "сборка ISO (5-15 минут)"
	cd "$SC"
	ITTY_OVERLAY="$SC/ittyos-overlay" sh mkimage.sh --tag "$ALPINE" --outdir "$OUT" --arch x86_64 \
		--repository "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE/main" \
		--repository "https://dl-cdn.alpinelinux.org/alpine/v$ALPINE/community" \
		--profile ittyos

	ISO=$(ls -t "$OUT"/*ittyos*.iso | head -n 1)
	say "готово: $ISO"
	COPY_TO="${COPY_TO:-/mnt/c/WSL}"
	if [ -d "$COPY_TO" ]; then
		cp "$ISO" "$COPY_TO/ittyOS-$(cat "$HERE/VERSION" | tr -d '[:space:]').iso"
		say "скопировано: $COPY_TO/ittyOS-$(cat "$HERE/VERSION" | tr -d '[:space:]').iso"
	fi
}

cmd_apply() {
	[ "$(id -u)" = 0 ] || die "apply запускается от root"
	stage
	say "applying the overlay to the system"
	cp -a "$STAGE/." /
	say "done: ittyOS $(cat "$HERE/VERSION" | tr -d '[:space:]'). Wallpaper: ittyos-wallpaper (inside the desktop)"
	command -v zenity >/dev/null 2>&1 || say "for the update notice as a window: flowkit -i zenity (tray notices: flowkit -i xfce4-notifyd)"
}

cmd_wsl() {
	[ "$(id -u)" = 0 ] || die "wsl запускается от root"
	OUT="${OUT:-$HOME/out}"
	stage
	mkdir -p "$OUT" "$WORK"

	if [ ! -d "$WORK/alpine-make-rootfs" ]; then
		say "загрузка alpine-make-rootfs"
		git clone --depth=1 https://github.com/alpinelinux/alpine-make-rootfs "$WORK/alpine-make-rootfs"
	fi

	say "сборка базового rootfs"
	BASE="$WORK/base.tar.gz"
	"$WORK/alpine-make-rootfs/alpine-make-rootfs" \
		--branch "v$ALPINE" \
		--packages 'alpine-base openrc bash sudo nano htop curl git shadow tzdata dialog clamav freshclam yara' \
		--timezone 'UTC' \
		"$BASE"

	say "наложение ittyOS"
	ROOT="$WORK/rootfs"
	rm -rf "$ROOT"
	mkdir -p "$ROOT"
	tar -xzf "$BASE" -C "$ROOT"
	mkdir -p "$ROOT/home" "$ROOT/usr/local/bin"
	cp -a "$STAGE/." "$ROOT/"
	rm -f "$ROOT/usr/bin/install-ittyos"
	echo ittyos > "$ROOT/etc/hostname"
	cat > "$ROOT/etc/wsl.conf" <<EOF
[network]
hostname = ittyos

[interop]
enabled = true
appendWindowsPath = true
EOF
	chown -R root:root "$ROOT/usr/bin/flowkit" "$ROOT/usr/bin/neofetch" "$ROOT/etc/motd" "$ROOT/etc/os-release"

	tar -czf "$OUT/ittyos-wsl.tar.gz" -C "$ROOT" .
	say "готово: $OUT/ittyos-wsl.tar.gz"
	COPY_TO="${COPY_TO:-/mnt/c/WSL}"
	if [ -d "$COPY_TO" ]; then
		cp "$OUT/ittyos-wsl.tar.gz" "$COPY_TO/"
		say "скопировано: $COPY_TO/ittyos-wsl.tar.gz"
	fi
	say "в PowerShell: wsl --import ittyOS C:\\WSL\\ittyOS C:\\WSL\\ittyos-wsl.tar.gz"
}

case "${1:-}" in
	setup) cmd_setup ;;
	iso) cmd_iso ;;
	wsl) cmd_wsl ;;
	stage) stage; say "оверлей: $STAGE" ;;
	apply) cmd_apply ;;
	*) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//' ;;
esac
