ifndef SUDO_PASSWD
$(error SUDO_PASSWD is not set. Please set it and rerun the make command.)
endif

JOBS ?= 16
linux_version := $(shell cat ./config/linux_version.txt)
KERNEL_SRC_DIR := linux/linux-$(linux_version)

KERNEL_IMAGE := linux/linux-$(shell cat config/linux_version.txt)/arch/x86/boot/bzImage
INITRD_IMAGE := busybox/initrd.ext4

RUN_QEMU_TEMPLATE := template/run_qemu.sh.in
RUN_QEMU_DEBUG_TEMPLATE := template/run_qemu_debug.sh.in
VSCODE_LAUNCH_JSON_TEMPLATE := template/vscode_launch.json.in

.PHONY: all
all: initrd bzImage run_qemu run_qemu_debug vscode_launch

.PHONY: initrd
initrd:
	$(MAKE) -C busybox initrd JOBS=$(JOBS) SUDO_PASSWD=$(SUDO_PASSWD)

.PHONY: bzImage
bzImage:
	$(MAKE) -C linux linux-build JOBS=$(JOBS)

define generate_qemu_script
	@sed -e 's|{kernel_image}|$(KERNEL_IMAGE)|g' \
	     -e 's|{initrd_image}|$(INITRD_IMAGE)|g' \
	     $1 > $2
	@chmod +x $2
endef

.PHONY: run_qemu
run_qemu: initrd bzImage
	@echo "Generating QEMU run script..."
	$(call generate_qemu_script,$(RUN_QEMU_TEMPLATE),run_qemu.sh)
	@echo "Run 'sudo ./run_qemu.sh' to start QEMU."

.PHONY: run_qemu_debug
run_qemu_debug: initrd bzImage
	@echo "Generating QEMU debug run script..."
	$(call generate_qemu_script,$(RUN_QEMU_DEBUG_TEMPLATE),run_qemu_debug.sh)
	@echo "Run 'sudo ./run_qemu_debug.sh' to start QEMU in debug mode."

.PHONY: vscode_launch
vscode_launch: initrd bzImage
	@echo "Generating VSCode launch.json..."
	@if [ ! -d .vscode ]; then mkdir .vscode; fi
	@mkdir -p $(KERNEL_SRC_DIR)/.vscode
	@cp $(VSCODE_LAUNCH_JSON_TEMPLATE) $(KERNEL_SRC_DIR)/.vscode/launch.json
	@echo "You can debug with VSCode after QEMU GDB server running."

.PHONY: clean
clean:
	$(MAKE) -C busybox clean
	$(MAKE) -C linux clean

.PHONY: distclean
distclean:
	$(MAKE) -C busybox distclean
	$(MAKE) -C linux distclean

