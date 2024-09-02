linux_version := $(shell cat ./config/linux_version.txt)
KERNEL_SRC_DIR := linux/linux-$(linux_version)

KERNEL_BZIMAGE := $(CURDIR)/linux/linux-$(shell cat config/linux_version.txt)-build/arch/x86/boot/bzImage
KERNEL_VMLINUX := $(CURDIR)/linux/linux-$(shell cat config/linux_version.txt)-build/vmlinux
INITRAMFS_IMAGE := $(CURDIR)/busybox/initramfs.cpio.gz

RUN_QEMU_TEMPLATE := $(CURDIR)/template/run_qemu.sh.in
RUN_QEMU_DEBUG_TEMPLATE := $(CURDIR)/template/run_qemu_debug.sh.in
VSCODE_LAUNCH_JSON_TEMPLATE := $(CURDIR)/template/vscode_launch.json.in

# Color codes
GREEN := \033[0;32m
BLUE := \033[0;34m
NC := \033[0m # No Color

.PHONY: all
all: initramfs bzImage run_qemu run_qemu_debug vscode_launch

# filesystem
.PHONY: initramfs
initramfs:
	$(MAKE) -C busybox initramfs

.PHONY: bzImage
bzImage:
	tree .
	$(MAKE) -C linux linux-build

define generate_qemu_script
	@sed -e 's|{kernel_image}|$(KERNEL_BZIMAGE)|g' \
	     -e 's|{initramfs}|$(INITRAMFS_IMAGE)|g' \
	     $1 > $2
	@chmod +x $2
endef

# start qemu
.PHONY: run_qemu
run_qemu:
	@echo -e "${GREEN}Generating QEMU run script...${NC}"
	$(call generate_qemu_script,$(RUN_QEMU_TEMPLATE),run_qemu.sh)
	@echo -e "${GREEN}Run './run_qemu.sh' to start QEMU.${NC}"

# start qemu in gdb mode
.PHONY: run_qemu_debug
run_qemu_debug:
	@echo -e "${GREEN}Generating QEMU debug run script...${NC}"
	$(call generate_qemu_script,$(RUN_QEMU_DEBUG_TEMPLATE),run_qemu_debug.sh)
	@echo -e "${GREEN}Run './run_qemu_debug.sh' to start QEMU in debug mode.${NC}"

# generate vscode launch.json for debugging
.PHONY: vscode_launch
vscode_launch: bzImage
	@echo -e "${GREEN}Generating VSCode launch.json...${NC}"
	@if [ ! -d .vscode ]; then mkdir .vscode; fi
	@mkdir -p $(KERNEL_SRC_DIR)/.vscode
	@sed 's|"program": "{initramfs}"|"program": "$(KERNEL_VMLINUX)"|g' $(VSCODE_LAUNCH_JSON_TEMPLATE) > $(KERNEL_SRC_DIR)/.vscode/launch.json
	@echo -e "${GREEN}You can debug with VSCode after QEMU GDB server running.${NC}"

.PHONY: clean
clean:
	$(MAKE) -C busybox clean
	$(MAKE) -C linux clean

.PHONY: distclean
distclean:
	$(MAKE) -C busybox distclean
	$(MAKE) -C linux distclean

