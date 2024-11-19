linux_version := $(shell cat ../config/linux_version.txt)
src_dir := $(CURDIR)/linux-$(linux_version)
build_dir := $(CURDIR)/linux-$(linux_version)-build
config_file := ../config/linux_config.txt
scripts_config := $(src_dir)/scripts/config
KBUILD_CFLAGS := "-fno-inline -fno-inline-functions -fno-inline-small-functions"
MAKE = make -C $(src_dir) O=$(build_dir)

LINUX_GIT_REPO := https://mirrors.ustc.edu.cn/linux.git

state_dir = .state
src_cloned = $(state_dir)/src_cloned
src_configed = $(state_dir)/src_configed
src_built = $(state_dir)/src_built
src_installed = $(state_dir)/src_installed


.PHONY: all
all: bzImage

$(src_cloned):
	@test -d $(state_dir) || mkdir -p $(state_dir)
	@echo -e "$(GREEN)Cloning Linux source...$(NC)"
# git clone --depth 1 --branch v$(linux_version) $(LINUX_GIT_REPO) $(src_dir)
	@test -d $(src_dir) || ( \
		git init $(src_dir) && \
		cd $(src_dir) && \
		git remote add origin $(LINUX_GIT_REPO) \
	)
	@cd $(src_dir) && \
		git fetch --depth 1 origin v$(linux_version) && \
		git checkout FETCH_HEAD
	@touch $@

$(src_configed): $(src_cloned)
	@echo -e "$(GREEN)Applying custom config options...$(NC)"
	@$(MAKE) defconfig > /dev/null
	@echo -e "$(BLUE)Default configuration applied.$(NC)"

	@test -d $(build_dir) || mkdir -p $(build_dir)

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
	@touch $@

# we want to rebuild kernel every time
.PHONY: bzImage
bzImage: $(src_configed)
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
	@rm -rf $(src_dir) $(build_dir) linux-$(linux_version).tar.xz $(state_dir)
