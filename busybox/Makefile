busybox_version := $(shell cat ../config/busybox_version.txt)
src_dir := busybox-$(busybox_version)
install_dir := busybox-$(busybox_version)-install
overwrite_config := ../config/busybox_config.txt
initramfs := initramfs.cpio.gz
mount_dir := initramfs_mount_dir

# Color codes for output
GREEN := \033[0;32m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: all
all: initramfs

busybox-source: $(src_dir)

$(src_dir): busybox-$(busybox_version).tar.bz2
	@echo -e "$(GREEN)Extracting BusyBox source...$(NC)"

	@mkdir -p $(src_dir)
	@tar -xjf busybox-$(busybox_version).tar.bz2 -C $(src_dir) --strip-components=1

# download busybox-${version}.tar.bz2
busybox-$(busybox_version).tar.bz2:
	@echo -e "$(GREEN)Downloading BusyBox version $(busybox_version)...$(NC)"
	@wget https://busybox.net/downloads/busybox-$(busybox_version).tar.bz2 -O busybox-$(busybox_version).tar.bz2

# apply custom config options
.PHONY: busybox-config
busybox-config: busybox-source
	@echo -e "$(GREEN)Applying custom config options...$(NC)"
	@cd $(src_dir) && make defconfig > /dev/null
	@python3 ./overwrite_config.py $(overwrite_config) $(src_dir)/.config
	@cd $(src_dir) && make oldconfig > /dev/null

.PHONY: busybox-build
busybox-build: busybox-config
	@echo -e "$(GREEN)Building BusyBox...$(NC)"
	@cd $(src_dir) && make > /dev/null

.PHONY: busybox-install
busybox-install: busybox-build
	@echo -e "$(GREEN)Installing BusyBox...$(NC)"
	@mkdir -p $(install_dir)
	@cd $(src_dir) && make CONFIG_PREFIX=../$(install_dir) install > /dev/null

# bundle busybox build in an ext4 format file
.PHONY: initramfs
initramfs: busybox-install
	@echo -e "$(GREEN)Creating initramfs...$(NC)"
	@mkdir -p $(mount_dir)/{etc/init.d,dev,mnt,proc,sys,tmp}
	@cp -arf $(install_dir)/. $(mount_dir)
	
	@echo -e "$(BLUE)Setting up fstab...$(NC)"
	@echo 'proc /proc proc defaults 0 0' 		> $(mount_dir)/etc/fstab
	@echo 'tmpfs /tmp tmpfs defaults 0 0' 		>> $(mount_dir)/etc/fstab
	@echo 'sysfs /sys sysfs defaults 0 0' 		>> $(mount_dir)/etc/fstab

	@echo -e "$(BLUE)Setting up init script...$(NC)"
	@echo '#!/bin/sh' 														> $(mount_dir)/etc/init.d/rcS
	@echo 'mount -a' 														>> $(mount_dir)/etc/init.d/rcS
	@echo 'mount -o remount,rw /' 											>> $(mount_dir)/etc/init.d/rcS
	@echo 'echo -e "Welcome to Linux"' 										>> $(mount_dir)/etc/init.d/rcS
	@echo 'echo "Boot took $$(cut -d'\'' '\'' -f1 /proc/uptime) seconds"' 	>> $(mount_dir)/etc/init.d/rcS
	@chmod 755 $(mount_dir)/etc/init.d/rcS

	@echo -e "$(BLUE)Setting up inittab...$(NC)"
	@echo '::sysinit:/etc/init.d/rcS' 				> $(mount_dir)/etc/inittab
	@echo '::respawn:-/bin/sh' 						>> $(mount_dir)/etc/inittab
	@echo '::askfirst:-/bin/sh' 					>> $(mount_dir)/etc/inittab
	@chmod 755 $(mount_dir)/etc/inittab

	@echo -e "$(BLUE)Creating device nodes and packing initramfs...$(NC)"
	@fakeroot bash -c '\
		mknod $(mount_dir)/dev/console c 5 1 && \
		mknod $(mount_dir)/dev/null c 1 3 && \
		mknod $(mount_dir)/dev/tty1 c 4 1 && \
		cd ${mount_dir} && \
		find . -print0 | cpio --null -ov --format=newc 2>/dev/null | gzip -9 > ../${initramfs} \
	' > /dev/null

	@rm -rf $(mount_dir)
	@echo -e "$(GREEN)${initramfs} created successfully.$(NC)"


.PHONY: clean
clean:
	@echo -e "$(GREEN)Cleaning...$(NC)"
	@if [ -d $(src_dir) ]; then \
		cd $(src_dir) && make uninstall > /dev/null && make clean > /dev/null; \
	fi
	@rm -rf ./initramfs*

.PHONY: distclean
distclean:
	@echo -e "$(GREEN)Performing complete cleanup...$(NC)"
	@rm -rf $(src_dir) $(install_dir) busybox-$(busybox_version).tar.bz2
	@rm -rf ./initramfs*
