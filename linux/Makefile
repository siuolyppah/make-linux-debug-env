linux_version := $(shell cat ../config/linux_version.txt)
src_dir := $(CURDIR)/linux-$(linux_version)
build_dir := $(CURDIR)/linux-$(linux_version)-build
config_file := ../config/linux_config.txt
scripts_config := $(src_dir)/scripts/config
KBUILD_CFLAGS := "-fno-inline -fno-inline-functions -fno-inline-small-functions"
MAKE = make -C $(src_dir) O=$(build_dir)

LINUX_GIT_REPO := https://mirrors.ustc.edu.cn/linux.git

# Color codes
GREEN := \033[0;32m
BLUE := \033[0;34m
NC := \033[0m # No Color


.PHONY: debug
debug:
	@echo -e "$(BLUE)Debugging Makefile variables:$(NC)"
	@echo -e "$(BLUE)linux_version               = $(linux_version)$(NC)"
	@echo -e "$(BLUE)src_dir                     = $(src_dir)$(NC)"
	@echo -e "$(BLUE)build_dir                   = $(build_dir)$(NC)"
	@echo -e "$(BLUE)config_file                 = $(config_file)$(NC)"
	@echo -e "$(BLUE)scripts_config              = $(scripts_config)$(NC)"
	@echo -e "$(BLUE)MAKE                        = $(MAKE)$(NC)"
	@echo -e "$(BLUE)CURDIR                      = $(CURDIR)$(NC)"


.PHONY: all
all: linux-build

$(src_dir):
	@echo -e "$(GREEN)Cloning Linux source...$(NC)"
	@git clone --depth 1 --branch v$(linux_version) $(LINUX_GIT_REPO) $(src_dir)

$(build_dir):
	@mkdir -p $@

# apply custom config options
.PHONY: linux-config
linux-config: $(src_dir) $(build_dir)
	@echo -e "$(GREEN)Applying custom config options...$(NC)"
	$(MAKE) defconfig > /dev/null
	@echo -e "$(BLUE)Default configuration applied.$(NC)"

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
		echo -e "$(BLUE)Applied config: $$option = $$value$(NC)"; \
	done < $(config_file)
	$(MAKE) oldconfig > /dev/null

	@echo -e "$(BLUE)Configuration updated.$(NC)"

.PHONY: linux-build
linux-build: debug linux-config
	@echo -e "$(GREEN)Building Linux kernel...$(NC)"
	@KBUILD_CFLAGS=${KBUILD_CFLAGS} bear --append --output $(src_dir)/compile_commands.json -- $(MAKE) > /dev/null

.PHONY: clean
clean:
	@if [ -d $(src_dir) ]; then \
		echo -e "$(GREEN)Cleaning build directory...$(NC)"; \
		$(MAKE) clean > /dev/null; \
	fi

.PHONY: distclean
distclean:
	@echo -e "$(GREEN)Performing complete cleanup...$(NC)"
	@rm -rf $(src_dir) $(build_dir) linux-$(linux_version).tar.xz
