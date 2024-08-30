busybox_version := $(shell cat ../config/busybox_version.txt)
src_dir := busybox-$(busybox_version)
install_dir := busybox-$(busybox_version)-install
overwrite_config := ../config/busybox_config.txt
initramfs := initramfs.cpio.gz
mount_dir := initramfs_mount_dir
JOBS := $(shell expr $$(nproc) \* 2)

.PHONY: all
all: initramfs

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

# bundle busybox build in an ext4 format file
.PHONY: initramfs
initramfs: busybox-install
	@mkdir -p $(mount_dir)/{etc/init.d,dev,mnt,proc,sys,tmp}
	@cp -arf $(install_dir)/. $(mount_dir)
	
	@echo 'proc /proc proc defaults 0 0' 		> $(mount_dir)/etc/fstab
	@echo 'tmpfs /tmp tmpfs defaults 0 0' 		>> $(mount_dir)/etc/fstab
	@echo 'sysfs /sys sysfs defaults 0 0' 		>> $(mount_dir)/etc/fstab

	@echo '#!/bin/sh' 														> $(mount_dir)/etc/init.d/rcS
	@echo 'mount -a' 														>> $(mount_dir)/etc/init.d/rcS
	@echo 'mount -o remount,rw /' 											>> $(mount_dir)/etc/init.d/rcS
	@echo 'echo -e "Welcome to Linux"' 										>> $(mount_dir)/etc/init.d/rcS
	@echo 'echo "Boot took $$(cut -d'\'' '\'' -f1 /proc/uptime) seconds"' 	>> $(mount_dir)/etc/init.d/rcS
	@chmod 755 $(mount_dir)/etc/init.d/rcS

	@echo '::sysinit:/etc/init.d/rcS' 				> $(mount_dir)/etc/inittab
	@echo '::respawn:-/bin/sh' 						>> $(mount_dir)/etc/inittab
	@echo '::askfirst:-/bin/sh' 					>> $(mount_dir)/etc/inittab
	@chmod 755 $(mount_dir)/etc/inittab

	
	@fakeroot bash -c '\
		mknod $(mount_dir)/dev/console c 5 1 && \
		mknod $(mount_dir)/dev/null c 1 3 && \
		mknod $(mount_dir)/dev/tty1 c 4 1 && \
		cd ${mount_dir} && \
		find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../${initramfs} \
	'

	@rm -rf $(mount_dir)
	@echo "${initramfs} created successfully."


.PHONY: clean
clean:
	@if [ -d $(src_dir) ]; then \
		cd $(src_dir) && make uninstall && make clean; \
	fi
	rm -rf ./initramfs*

.PHONY: distclean
distclean:
	rm -rf $(src_dir) $(install_dir) busybox-$(busybox_version).tar.bz2
	rm -rf ./initramfs*