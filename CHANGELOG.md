# Changelog

## 1.0.5
- **New installer flow**: after the system is written to the disk, the installer asks which
  desktop to add (none, XFCE, LXQt, MATE, KDE Plasma, GNOME, Sway). The choice is installed at
  the first boot of the new system (`ittyos-firstboot`, needs the network, restarts once when
  done, retries up to 3 boots, log in `/var/log/ittyos-firstboot.log`). Only XFCE has ittyOS
  branding; the others are plain `setup-desktop` installs and are not tested by ittyOS.
- **Plymouth boot splash** with an ittyOS theme: `ittyos-splash enable|disable|status`, a new
  "Boot splash" component in the installer (on by default, experimental). It is started from
  OpenRC, not from the initramfs, because Alpine has no initramfs support for Plymouth; the
  boot never depends on it. To skip it once: create `/etc/ittyos/no-splash`.
- `ittyos-desktop [xfce|lxqt|mate|plasma|gnome|sway]` takes the desktop name.

## 1.0.4
- **`ittyos-update`**: update a running ittyOS with one command (`sudo ittyos-update`).
  It keeps its own copy of the repository in `/var/lib/ittyos/src`, shows the installed and
  the available version, asks for confirmation (`-y` to skip, `-f` to re-apply the same version)
  and runs `build.sh apply`. No manual `git clone` needed.
- **`ittyos-desktop`**: installs XFCE on a running system (`setup-desktop xfce`), plus
  `xfce4-notifyd` and `zenity` so that update notices can be shown, plus VirtualBox guest
  additions when run inside VirtualBox (best effort).
- Update checker: falls back correctly when `notify-send` has no notification daemon
  (the version is no longer marked as "already shown" in that case), stays quiet without a
  graphical session, and the dialog now says `sudo ittyos-update`.
- The installer copies `ittyos-update`, `ittyos-desktop` and the update checker to the disk.
- `build.sh apply` messages are in English (readable on a plain console).

## 1.0.3
- `help` now shows a readable overview of ittyOS commands (`help all` still lists every
  busybox command, `help flowkit` shows the package manager help).
- XFCE terminal runs a login shell, so the `apk` and `help` aliases work there too.
- **Update check**: `ittyos-check-update` compares `/etc/ittyos-version` with the
  `VERSION` file on GitHub and shows a dialog (zenity/kdialog/yad) or a tray
  notification, once per new version. Enabled via XDG autostart after desktop login;
  opt out with a `no-update-check` file (see README). The installer copies it to the disk.

## 1.0.2
- Protection in layers instead of a single engine:
  - `flowkit scan` uses YARA (works offline, basic rules in `/usr/share/ittyos/yara`,
    add your own to `/etc/ittyos/yara`) and ClamAV when its databases are available.
  - `flowkit audit` compares installed files with their packages (`apk audit`, offline).
  - `flowkit av status` shows the state of every layer.
- `flowkit av update`: a clear message when the ClamAV server answers 403 ("Blocked by CDN"),
  instead of a wall of text. `--verbose` shows the raw output.
- neofetch shows which protection engines are really working.
- `yara` is now part of the ISO, the installer and the WSL rootfs.

## 1.0.1
- Desktop branding for XFCE: ittyOS wallpaper (topographic lines; the dark variant is `ittyos-dark.png`; QHD versions `*_qhd.png`), LightDM greeter background and logo,
  terminal colors, `ittyos-wallpaper [dark]` helper (picks the QHD image on wide screens).
- Time sync at boot (chrony): a wrong clock broke TLS and ClamAV database updates.
- `flowkit av update`: refuses to run when the clock is wrong or less than an hour
  after the previous attempt (the ClamAV CDN rate-limits and blocks frequent requests).
- Single `VERSION` file; the version is substituted into os-release, motd, issue,
  flowkit and the installer. ISO is copied as `ittyOS-<version>.iso`.
- `./build.sh apply` updates a running ittyOS from the repository.
- Fix: live ISO did not mount the kernel modules (`modloop` service was missing),
  so the installer could not mount ext4.
- `os-release` now has `LOGO`, `ANSI_COLOR` and the GitHub URLs.
- flowkit now reports its version as the ittyOS version (`flowkit 1.0.1, cmp86_64`).

## 1.0
- First working release, built on Alpine Linux 3.24 (mkimage).
- `flowkit` package manager (apk frontend): `-i`, `-r`, `-s`, `-l`, `-v`, `-h`.
- ClamAV antivirus: `flowkit scan`, `flowkit av install|update|status`;
  packages are virus-checked before installation.
- `install-ittyos`: dialog-based text-mode installer.
- Custom `neofetch`, colored motd, automatic DHCP networking.
