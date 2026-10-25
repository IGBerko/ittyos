profile_ittyos() {
	profile_standard
	title="ittyOS"
	desc="ittyOS live system"
	hostname="ittyos"
	apks="$apks linux-lts bash nano htop curl git sudo dialog tzdata clamav freshclam
		e2fsprogs dosfstools sfdisk syslinux util-linux"
	apkovl="genapkovl-ittyos.sh"
}
