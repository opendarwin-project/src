# Host clang + ld64.lld: static arm64 Mach-O images for bootxnu.
SYSROOT ?= $(CURDIR)/../../sysroot/arm64-apple-darwin
CLANG ?= clang
LFLAGS = -fuse-ld=lld -nostdlib -Wl,-e,_start
CFLAGS = -target arm64-apple-macos14.0 -ffreestanding -fno-builtin \
	-mstrict-align -mgeneral-regs-only -fno-stack-protector \
	-fno-PIC -O2 -Wall

OUT := out
KERNEL := $(OUT)/mock_kernel.macho
INIT := $(OUT)/od_init.macho
AFDT := $(OUT)/afdt.bin

.PHONY: all clean

all: $(KERNEL) $(INIT) $(AFDT)

$(OUT):
	mkdir -p $(OUT)

$(KERNEL): mock_kernel.c | $(OUT)
	$(CLANG) $(CFLAGS) $(LFLAGS) $< -o $@
	@file $@

$(INIT): od_init.c | $(OUT)
	$(CLANG) $(CFLAGS) $(LFLAGS) $< -o $@
	@file $@

$(AFDT): $(INIT) mkafdt.py
	python3 mkafdt.py -o $@ --ramdisk $(INIT) --ramdisk-phys 0x48000000

clean:
	rm -rf $(OUT)
