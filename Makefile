JOBS ?= 16
linux_version := $(shell cat ./config/linux_version.txt)
KERNEL_SRC_DIR := linux/linux-$(linux_version)

KERNEL_BZIMAGE := $(CURDIR)/linux/linux-$(shell cat config/linux_version.txt)-build/arch/x86/boot/bzImage
KERNEL_VMLINUX := $(CURDIR)/linux/linux-$(shell cat config/linux_version.txt)-build/vmlinux
INITRAMFS_IMAGE := $(CURDIR)/busybox/initramfs.cpio.gz

RUN_QEMU_TEMPLATE := $(CURDIR)/template/run_qemu.sh.in
RUN_QEMU_DEBUG_TEMPLATE := $(CURDIR)/template/run_qemu_debug.sh.in
VSCODE_LAUNCH_JSON_TEMPLATE := $(CURDIR)/template/vscode_launch.json.in

.PHONY: all
all: initramfs bzImage run_qemu run_qemu_debug vscode_launch

# filesystem
.PHONY: initramfs
initramfs:
	$(MAKE) -C busybox initramfs JOBS=$(JOBS) SUDO_PASSWD=$(SUDO_PASSWD)

.PHONY: bzImage
bzImage:
	$(MAKE) -C linux linux-build JOBS=$(JOBS)

define generate_qemu_script
	@sed -e 's|{kernel_image}|$(KERNEL_BZIMAGE)|g' \
	     -e 's|{initramfs}|$(INITRAMFS_IMAGE)|g' \
	     $1 > $2
	@chmod +x $2
endef

# start qemu
.PHONY: run_qemu
run_qemu:
	@echo "Generating QEMU run script..."
	$(call generate_qemu_script,$(RUN_QEMU_TEMPLATE),run_qemu.sh)
	@echo "Run './run_qemu.sh' to start QEMU."

# start qemu in gdb mode
.PHONY: run_qemu_debug
run_qemu_debug:
	@echo "Generating QEMU debug run script..."
	$(call generate_qemu_script,$(RUN_QEMU_DEBUG_TEMPLATE),run_qemu_debug.sh)
	@echo "Run './run_qemu_debug.sh' to start QEMU in debug mode."

# generate vscode launch.json for debugging
.PHONY: vscode_launch
vscode_launch:
	@echo "Generating VSCode launch.json..."
	@if [ ! -d .vscode ]; then mkdir .vscode; fi
	@mkdir -p $(KERNEL_SRC_DIR)/.vscode
	@sed 's|"program": "{initramfs}"|"program": "$(KERNEL_VMLINUX)"|g' $(VSCODE_LAUNCH_JSON_TEMPLATE) > $(KERNEL_SRC_DIR)/.vscode/launch.json
	@echo "You can debug with VSCode after QEMU GDB server running."

.PHONY: clean
clean:
	$(MAKE) -C busybox clean
	$(MAKE) -C linux clean

.PHONY: distclean
distclean:
	$(MAKE) -C busybox distclean
	$(MAKE) -C linux distclean

