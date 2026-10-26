# ittyOS

A small Linux distribution built on [Alpine Linux](https://alpinelinux.org/)
(musl, OpenRC, apk), with its own package manager frontend and a built-in antivirus.

- **flowkit** - package manager (`flowkit -i <pkg>`, `-v`, `-h`), a frontend over apk
- **Protection layers** - `flowkit scan` (YARA + ClamAV), `flowkit audit` (apk audit);
  packages are scanned with ClamAV before they are installed, when its databases are available
- **install-ittyos** - text-mode graphical installer (dialog)
- **neofetch** and a colored motd
- XFCE desktop branding (wallpaper, login screen, terminal colors)
- **ittyos-check-update** - notifies on desktop login when a newer version is on GitHub

## Build

Everything is built on ittyOS / Alpine itself (a WSL2 distro works fine):

    ./build.sh setup   # as root: dependencies and the "builder" user
    ./build.sh iso     # as builder: build the live ISO (about 5 minutes)
    ./build.sh wsl     # as root: build a rootfs tarball for `wsl --import`
    ./build.sh apply   # as root: update a running ittyOS from this repository

All files that end up in the system live in `overlay/`.

## Test

Create a VirtualBox VM (Linux, 64-bit, 2 GB RAM or more, NAT network), attach the ISO,
boot and log in as `root` (empty password). Run `install-ittyos` to install to a disk.

## Credits and licenses

ittyOS is based on Alpine Linux and includes software under its own licenses
(GPL, MIT and others, including ClamAV under GPL-2.0). The scripts in this
repository are released under the MIT license (see `LICENSE`).
Do not publish your abuild private key (`*.rsa`); only the public `.pub` key is needed.

## Desktop

On an installed system (as root, with network access):

    setup-desktop xfce
    ./build.sh apply          # branding: wallpaper, login screen, terminal colors
    ittyos-wallpaper          # inside the XFCE session, for an already existing profile

For a new user the wallpaper is applied automatically on first login.

After a desktop login, `ittyos-check-update` runs once (XDG autostart). If
`/etc/ittyos-version` is older than the `VERSION` file on GitHub, it shows a
warning dialog (zenity / kdialog / yad) or a critical notification.
