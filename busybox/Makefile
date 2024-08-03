# busybox/Makefile

busybox_version := $(shell cat ../config/busybox_version.txt)
src_dir := busybox-$(busybox_version)
install_dir := busybox-$(busybox_version)-install
overwrite_config := ../config/busybox_config.txt
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

.PHONY: clean
clean:
	cd $(src_dir) && make clean
	rm -rf $(src_dir) $(install_dir) busybox-$(busybox_version).tar.bz2
