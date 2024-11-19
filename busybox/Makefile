busybox_version := $(shell cat ../config/busybox_version.txt)
src_dir := busybox-$(busybox_version)
install_dir := busybox-$(busybox_version)-install
overwrite_config := ../config/busybox_config.txt
initramfs := initramfs.cpio.gz
mount_dir := initramfs_mount_dir

state_dir = .state
tar_downed = $(state_dir)/tar_downed
src_unziped = $(state_dir)/src_unziped
src_configed = $(state_dir)/src_configed
src_built = $(state_dir)/src_built
src_installed = $(state_dir)/src_installed


.PHONY: all
all: initramfs

$(tar_downed):
	@test -d $(state_dir) || mkdir -p $(state_dir)

	@echo -e "$(GREEN)Downloading BusyBox version $(busybox_version)...$(NC)"
	@wget https://busybox.net/downloads/busybox-$(busybox_version).tar.bz2 -O busybox-$(busybox_version).tar.bz2
	@touch $@


$(src_unziped): $(tar_downed)
	@rm -rf $(src_dir)
	@echo -e "$(GREEN)Extracting BusyBox source...$(NC)"
	@mkdir -p $(src_dir)
	@tar -xjf busybox-$(busybox_version).tar.bz2 -C $(src_dir) --strip-components=1
	@touch $@


$(src_configed): $(src_unziped)
	@echo -e "$(GREEN)Applying custom config options...$(NC)"
	@cd $(src_dir) && make defconfig > /dev/null
	@python3 ./overwrite_config.py $(overwrite_config) $(src_dir)/.config
	@cd $(src_dir) && make oldconfig > /dev/null
	@touch $@


$(src_built): $(src_configed)
	@echo -e "$(GREEN)Building BusyBox...$(NC)"
	@cd $(src_dir) && make > /dev/null
	@touch $@


$(src_installed): $(src_built)
	@echo -e "$(GREEN)Installing BusyBox...$(NC)"
	@mkdir -p $(install_dir)
	@cd $(src_dir) && make CONFIG_PREFIX=../$(install_dir) install > /dev/null
	@touch $@

.PHONY: initramfs
initramfs: $(initramfs)

# bundle busybox build in an ext4 format file
$(initramfs): $(src_installed)
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

	@echo 'echo "Configuring network interface eth0..."' >> $(mount_dir)/etc/init.d/rcS
	@echo 'ifconfig eth0 up' >> $(mount_dir)/etc/init.d/rcS
	@echo 'ifconfig eth0 10.0.2.15 netmask 255.255.255.0' >> $(mount_dir)/etc/init.d/rcS
	@echo 'route add default gw 10.0.2.2' >> $(mount_dir)/etc/init.d/rcS

	@echo 'echo "nameserver 223.5.5.5" > /etc/resolv.conf' >> $(mount_dir)/etc/init.d/rcS

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
	@rm -rf $(src_dir)
	@rm -rf $(src_unziped) $(src_configed) $(src_built) $(src_installed)
	@rm -rf ./initramfs*

.PHONY: distclean
distclean:
	@echo -e "$(GREEN)Performing complete cleanup...$(NC)"
	@rm -rf $(src_dir) $(install_dir) busybox-$(busybox_version).tar.bz2 $(state_dir)
	@rm -rf ./initramfs*
