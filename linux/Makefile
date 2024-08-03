# linux/Makefile

linux_version := $(shell cat ../config/linux_version.txt)
src_dir := linux-$(linux_version)
install_dir := linux-$(linux_version)-install
config_file := ../config/linux_config.txt
scripts_config := $(src_dir)/scripts/config
JOBS ?= 16

.PHONY: all
all: linux-install

.PHONY: linux-source
linux-source: $(src_dir)

$(src_dir): linux-$(linux_version).tar.xz
	mkdir -p $(src_dir)
	tar -xJf linux-$(linux_version).tar.xz

# download linux-${version}.tar.xz
linux-$(linux_version).tar.xz:
	@echo "Downloading Linux version $(linux_version)..."
	wget https://cdn.kernel.org/pub/linux/kernel/v$(firstword $(subst ., ,$(linux_version))).x/linux-$(linux_version).tar.xz -O linux-$(linux_version).tar.xz

# apply custom config options
.PHONY: linux-config
linux-config: $(src_dir)
	@echo "Applying custom config options..."
	cd $(src_dir) && make defconfig
	@while IFS= read -r line; do \
		line=$$(echo $$line | xargs); \
		if [ -z "$$line" ] || [ $${line:0:1} == "#" ]; then \
			continue; \
		fi; \
		option=$$(echo $$line | cut -d'=' -f1); \
		value=$$(echo $$line | cut -d'=' -f2); \
		if [ "$$value" == "y" ]; then \
			$(scripts_config) --file $(src_dir)/.config --enable $$option; \
		elif [ "$$value" == "m" ]; then \
			$(scripts_config) --file $(src_dir)/.config --module $$option; \
		elif [ "$$value" == "n" ]; then \
			$(scripts_config) --file $(src_dir)/.config --disable $$option; \
		elif [[ "$$value" =~ ^[0-9]+$$ ]]; then \
			$(scripts_config) --file $(src_dir)/.config --set-val $$option $$value; \
		elif [[ "$$value" =~ ^\".*\"$$ ]]; then \
			$(scripts_config) --file $(src_dir)/.config --set-str $$option $${value//\"/}; \
		fi; \
	done < $(config_file)
	cd $(src_dir) && make oldconfig

.PHONY: linux-build
linux-build: linux-config
	cd $(src_dir) && make -j$(JOBS)

.PHONY: linux-install
linux-install: linux-build
	mkdir -p $(install_dir)
	cd $(src_dir) && make INSTALL_PATH=$(PWD)/$(install_dir) install

.PHONY: clean
clean:
	cd $(src_dir) && make clean
	rm -rf $(src_dir) $(install_dir) linux-$(linux_version).tar.xz
