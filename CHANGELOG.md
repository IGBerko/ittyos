# Changelog

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
