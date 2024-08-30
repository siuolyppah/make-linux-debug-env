linux_version := $(shell cat ../config/linux_version.txt)
src_dir := $(CURDIR)/linux-$(linux_version)
build_dir := $(CURDIR)/linux-$(linux_version)-build
config_file := ../config/linux_config.txt
scripts_config := $(src_dir)/scripts/config
JOBS ?= 16
KBUILD_CFLAGS := "-fno-inline -fno-inline-functions -fno-inline-small-functions"
MAKE = make -C $(src_dir) O=$(build_dir)

LINUX_GIT_REPO := https://github.com/torvalds/linux.git

.PHONY: debug
debug:
	@echo "Debugging Makefile variables:"
	@echo "linux_version				= $(linux_version)"
	@echo "src_dir       				= $(src_dir)"
	@echo "build_dir     				= $(build_dir)"
	@echo "config_file   				= $(config_file)"
	@echo "scripts_config 				= $(scripts_config)"
	@echo "JOBS          				= $(JOBS)"
	@echo "MAKE          				= $(MAKE)"
	@echo "CURDIR        				= $(CURDIR)"
	@echo "Current working directory: 	= $(PWD)"


.PHONY: all
all: linux-install

$(src_dir):
	git clone --depth 1 --branch v$(linux_version) $(LINUX_GIT_REPO) $(src_dir)

.PHONY: linux-source
linux-source: $(src_dir)

$(build_dir):
	mkdir -p $@

# apply custom config options
.PHONY: linux-config
linux-config: linux-source $(build_dir)
	@echo "Applying custom config options..."
	$(MAKE) defconfig 
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
	$(MAKE) oldconfig

.PHONY: linux-build
linux-build: debug linux-config
	KBUILD_CFLAGS=${KBUILD_CFLAGS} bear --output $(src_dir)/compile_commands.json -- $(MAKE) -j$(JOBS)

.PHONY: clean
clean:
	@if [ -d $(src_dir) ]; then \
		$(MAKE) clean; \
	fi

.PHONY: distclean
distclean:
	rm -rf $(src_dir) $(build_dir) linux-$(linux_version).tar.xz