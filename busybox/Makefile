# busybox/Makefile

busybox_version := $(shell cat ../config/busybox_version.txt)
src_dir := busybox-$(busybox_version)
install_dir := busybox-$(busybox_version)-install
overwrite_config := ../config/busybox_config.txt
initrd_file := initrd.ext4
mount_dir := initrd_mount_dir
JOBS ?= 16
SUDO := sudo -S <<<$(SUDO_PASSWD)

busybox-source: $(src_dir)

$(src_dir): busybox-$(busybox_version).tar.bz2
	mkdir -p $(src_dir)
	tar -xjf busybox-$(busybox_version).tar.bz2 -C $(src_dir) --strip-components=1

# download busybox-${version}.tar.bz2
busybox-$(busybox_version).tar.bz2:
	@echo "Downloading BusyBox version $(busybox_version)..."
	wget https://busybox.net/downloads/busybox-$(busybox_version).tar.bz2 -O busybox-$(busybox_version).tar.bz2

# apply custom config options
.PHONY: busybox-config
busybox-config: busybox-source
	@echo "Applying custom config options..."
	cd $(src_dir) && make defconfig
	python3 ./overwrite_config.py $(overwrite_config) $(src_dir)/.config
	cd $(src_dir) && make oldconfig

.PHONY: busybox-build
busybox-build: busybox-config
	cd $(src_dir) && make -j$(JOBS)

.PHONY: busybox-install
busybox-install: busybox-build
	mkdir -p $(install_dir)
	cd $(src_dir) && make CONFIG_PREFIX=../$(install_dir) install

.PHONY: initrd
initrd: busybox-install
	dd if=/dev/zero of=$(initrd_file) bs=1M count=32
	mkfs.ext4 $(initrd_file)
	mkdir -p $(mount_dir)
	@echo "Generating rootfs..."
	@$(SUDO) mount $(initrd_file) $(mount_dir)
	@$(SUDO) cp -arf $(install_dir)/. $(mount_dir)

	@$(SUDO) mkdir -p $(mount_dir)/etc/init.d
	@$(SUDO) mkdir -p $(mount_dir)/dev
	@$(SUDO) mkdir -p $(mount_dir)/mnt
	@$(SUDO) mkdir -p $(mount_dir)/proc
	@$(SUDO) mkdir -p $(mount_dir)/sys
	@$(SUDO) mkdir -p $(mount_dir)/tmp

	@$(SUDO) bash -c "echo 'proc /proc proc defaults 0 0' > $(mount_dir)/etc/fstab"
	@$(SUDO) bash -c "echo 'tmpfs /tmp tmpfs defaults 0 0' >> $(mount_dir)/etc/fstab"
	@$(SUDO) bash -c "echo 'sysfs /sys sysfs defaults 0 0' >> $(mount_dir)/etc/fstab"

	@$(SUDO) bash -c "echo '#!/bin/sh' > $(mount_dir)/etc/init.d/rcS"
	@$(SUDO) bash -c "echo 'mount -a' >> $(mount_dir)/etc/init.d/rcS"
	@$(SUDO) bash -c "echo 'mount -o remount,rw /' >> $(mount_dir)/etc/init.d/rcS"
	@$(SUDO) bash -c "echo 'echo -e \"Welcome to YOUR Linux\"' >> $(mount_dir)/etc/init.d/rcS"
	@$(SUDO) chmod 755 $(mount_dir)/etc/init.d/rcS

	@$(SUDO) bash -c "echo '::sysinit:/etc/init.d/rcS' > $(mount_dir)/etc/inittab"
	@$(SUDO) bash -c "echo '::respawn:-/bin/sh' >> $(mount_dir)/etc/inittab"
	@$(SUDO) bash -c "echo '::askfirst:-/bin/sh' >> $(mount_dir)/etc/inittab"
	@$(SUDO) chmod 755 $(mount_dir)/etc/inittab

	@$(SUDO) mknod $(mount_dir)/dev/console c 5 1
	@$(SUDO) mknod $(mount_dir)/dev/null c 1 3
	@$(SUDO) mknod $(mount_dir)/dev/tty1 c 4 1

	@$(SUDO) umount $(mount_dir)
	rm -rf $(mount_dir)


.PHONY: clean
clean:
	@if [ -d $(src_dir) ]; then \
		cd $(src_dir) && make uninstall && make clean; \
	fi
	rm -f $(initrd_file)
	rm -rf $(mount_dir)

.PHONY: distclean
distclean:
	rm -rf $(src_dir) $(install_dir) busybox-$(busybox_version).tar.bz2
	rm -f $(initrd_file)
	rm -rf $(mount_dir)