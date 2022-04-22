lima_community_edge_pkgs() {
	apk fetch --root "$APKROOT" --recursive \
	  --no-cache \
    --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
    cni-plugins \
    $@
}

build_lima_packages() {
	local _apksdir="$DESTDIR/lima-packages"
	local _archdir="$_apksdir/$ARCH"
	mkdir -p "$_archdir"

  lima_community_edge_pkgs --link --output "$_archdir"

	if ! ls "$_archdir"/*.apk >& /dev/null; then
		return 1
	fi

	apk index \
		--description "$RELEASE" \
		--rewrite-arch "$ARCH" \
		--index "$_archdir"/APKINDEX.tar.gz \
		--output "$_archdir"/APKINDEX.tar.gz \
		"$_archdir"/*.apk
	abuild-sign "$_archdir"/APKINDEX.tar.gz
	touch "$_apksdir/.boot_repository"
}

section_lima_packages() {
	build_section lima_packages $ARCH $( lima_community_edge_pkgs --simulate | sort | checksum)
}

profile_lima() {
	profile_standard
	profile_abbrev="lima"
	title="Linux Virtual Machines"
	desc="Similar to standard.
		Slimmed down kernel.
		Optimized for virtual systems.
		Configured for lima."
	arch="aarch64 x86 x86_64"
	initfs_cmdline="modules=loop,squashfs,sd-mod,usb-storage"
	kernel_addons=
	kernel_flavors="virt"
	kernel_cmdline="console=tty0 console=ttyS0,115200"
	syslinux_serial="0 115200"
	apkovl="genapkovl-lima.sh"
	apks="$apks openssh-server-pam"
        if [ "${LIMA_INSTALL_CA_CERTIFICATES}" == "true" ]; then
            apks="$apks ca-certificates"
        fi
        if [ "${LIMA_INSTALL_CLOUD_INIT}" == "true" ]; then
            apks="$apks cloud-init"
        fi
        if [ "${LIMA_INSTALL_CNI_PLUGINS}" == "true" ]; then
            apks="$apks cni-plugins"
        fi
        if [ "${LIMA_INSTALL_DOCKER}" == "true" ]; then
            apks="$apks libseccomp runc containerd tini-static device-mapper-libs"
            apks="$apks docker-engine docker-openrc docker-cli docker"
            apks="$apks socat xz"
        fi
        if [ "${LIMA_INSTALL_LIMA_INIT}" == "true" ]; then
            apks="$apks e2fsprogs lsblk sfdisk shadow sudo udev"
        fi
        if [ "${LIMA_INSTALL_K3S}" == "true" ]; then
            apks="$apks k3s"
        fi
        if [ "${LIMA_INSTALL_LOGROTATE}" == "true" ]; then
            apks="$apks logrotate"
        fi
        if [ "${LIMA_INSTALL_SSHFS}" == "true" ]; then
            apks="$apks sshfs"
        fi
        if [ "${LIMA_INSTALL_IPTABLES}" == "true" ] || [ "${LIMA_INSTALL_NERDCTL}" == "true" ]; then
            apks="$apks iptables ip6tables"
        fi
}
