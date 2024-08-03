# busybox/Makefile

busybox_version := $(shell cat ../config/busybox_version.txt)
src_dir := busybox-$(busybox_version)
install_dir := busybox-$(busybox_version)-install
overwrite_config := ../config/busybox_config.txt
initrd_file := initrd.ext4
mount_dir := initrd_mount_dir
JOBS ?= 16

.PHONY: busybox-source
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
busybox-config: $(src_dir)
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
	cd $(src_dir) && make CONFIG_PREFIX=$(PWD)/$(install_dir) install

.PHONY: initrd
initrd: busybox-install
	dd if=/dev/zero of=$(initrd_file) bs=1M count=32
	mkfs.ext4 $(initrd_file)
	mkdir -p $(mount_dir)
	sudo mount $(initrd_file) $(mount_dir)
	sudo cp -arf $(install_dir)/. $(mount_dir)

	sudo mkdir -p $(mount_dir)/etc/init.d
	sudo mkdir -p $(mount_dir)/dev
	sudo mkdir -p $(mount_dir)/mnt
	sudo mkdir -p $(mount_dir)/proc
	sudo mkdir -p $(mount_dir)/sys
	sudo mkdir -p $(mount_dir)/tmp

	echo "proc /proc proc defaults 0 0" | sudo tee $(mount_dir)/etc/fstab
	echo "tmpfs /tmp tmpfs defaults 0 0" | sudo tee -a $(mount_dir)/etc/fstab
	echo "sysfs /sys sysfs defaults 0 0" | sudo tee -a $(mount_dir)/etc/fstab

	echo "#!/bin/sh" | sudo tee $(mount_dir)/etc/init.d/rcS
	echo "mount -a" | sudo tee -a $(mount_dir)/etc/init.d/rcS
	echo "mount -o remount,rw /" | sudo tee -a $(mount_dir)/etc/init.d/rcS
	echo 'echo -e "Welcome to YOUR Linux"' | sudo tee -a $(mount_dir)/etc/init.d/rcS
	sudo chmod 755 $(mount_dir)/etc/init.d/rcS

	echo "::sysinit:/etc/init.d/rcS" | sudo tee $(mount_dir)/etc/inittab
	echo "::respawn:-/bin/sh" | sudo tee -a $(mount_dir)/etc/inittab
	echo "::askfirst:-/bin/sh" | sudo tee -a $(mount_dir)/etc/inittab
	sudo chmod 755 $(mount_dir)/etc/inittab

	sudo mknod $(mount_dir)/dev/console c 5 1
	sudo mknod $(mount_dir)/dev/null c 1 3
	sudo mknod $(mount_dir)/dev/tty1 c 4 1

	sudo umount $(mount_dir)
	rm -rf $(mount_dir)


.PHONY: clean
clean:
	rm -rf $(src_dir) $(install_dir) busybox-$(busybox_version).tar.bz2
	(cd $(src_dir) && make clean) || true
	rm -f $(initrd_file)
	rm -rf $(mount_dir)
