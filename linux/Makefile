# linux/Makefile

linux_version := $(shell cat ../config/linux_version.txt)
src_dir := linux-$(linux_version)
build_dir := linux-$(linux_version)-build
install_dir := linux-$(linux_version)-install
config_file := ../config/linux_config.txt
scripts_config := $(src_dir)/scripts/config
JOBS ?= 16
MAKE = make -f ../$(src_dir)/Makefile

.PHONY: all
all: linux-install

linux-source: $(src_dir)

$(src_dir): linux-$(linux_version).tar.xz
	mkdir -p $(src_dir)
	tar -xJf linux-$(linux_version).tar.xz

# download linux-${version}.tar.xz
linux-$(linux_version).tar.xz:
	@echo "Downloading Linux version $(linux_version)..."
	wget https://cdn.kernel.org/pub/linux/kernel/v$(firstword $(subst ., ,$(linux_version))).x/linux-$(linux_version).tar.xz -O linux-$(linux_version).tar.xz

$(build_dir):
	mkdir $@

# apply custom config options
.PHONY: linux-config
linux-config: linux-source $(build_dir)
	@echo "Applying custom config options..."
	cd $(build_dir) && $(MAKE) defconfig 
	@while IFS= read -r line; do \
		line=$$(echo $$line | xargs); \
		if [ -z "$$line" ] || [ $${line:0:1} == "#" ]; then \
			continue; \
		fi; \
		option=$$(echo $$line | cut -d'=' -f1); \
		value=$$(echo $$line | cut -d'=' -f2); \
		if [ "$$value" == "y" ]; then \
			$(scripts_config) --file $(build_dir)/.config --enable $$option; \
		elif [ "$$value" == "m" ]; then \
			$(scripts_config) --file $(build_dir)/.config --module $$option; \
		elif [ "$$value" == "n" ]; then \
			$(scripts_config) --file $(build_dir)/.config --disable $$option; \
		elif [[ "$$value" =~ ^[0-9]+$$ ]]; then \
			$(scripts_config) --file $(build_dir)/.config --set-val $$option $$value; \
		elif [[ "$$value" =~ ^\".*\"$$ ]]; then \
			$(scripts_config) --file $(build_dir)/.config --set-str $$option $${value//\"/}; \
		fi; \
	done < $(config_file)
	cd $(build_dir) && $(MAKE) oldconfig

.PHONY: linux-build
linux-build: linux-config
	cd $(build_dir) && bear --output ../$(src_dir)/compile_commands.json -- $(MAKE) -j$(JOBS)

.PHONY: linux-install
linux-install: linux-build
	mkdir -p $(install_dir)
	cd $(build_dir) && $(MAKE) INSTALL_PATH=../$(install_dir) install

.PHONY: clean
clean:
	@if [ -d $(src_dir) ]; then \
		cd $(build_dir) && $(MAKE) uninstall && $(MAKE) clean; \
	fi

.PHONY: distclean
distclean:
	rm -rf $(src_dir) $(build_dir) $(install_dir) linux-$(linux_version).tar.xz
