# Minimal QEMU virt + U-Boot `bootxnu` bring-up

QEMU's `-M vmapple` is a macOS-host Virtualization.framework clone and is
not available on this Linux box. XNU's `TARGET_CONFIGS="RELEASE ARM64
VMAPPLE"` still matches qemu `virt` well enough for early bring-up: PL011
UART at `0x09000000` and GICv3.

Until a real XNU Mach-O exists, this directory boots:

1. tinted-software U-Boot (`qemu_arm64_defconfig`, `CONFIG_CMD_BOOTXNU`)
2. a freestanding mock kernel (prints `boot_args`, finds the AFDT RAMDisk)
3. PID 1 from that RAMDisk (UART hello; no Darwin syscalls yet)

Memory map used by `run.py`:

| image            | qemu loader address |
| ---------------- | ------------------- |
| mock kernel      | `0x44000000`        |
| Apple FDT        | `0x46000000`        |
| PID 1 Mach-O     | `0x48000000`        |

`bootxnu` then relocates the kernel to `CONFIG_SYS_LOAD_ADDR+0x4000`
(`0x40204000`) and jumps to EL1.

```sh
cd ~/src/opendarwin-work/dev/qemu
make
python3 run.py
# or drop into the U-Boot prompt:
python3 run.py --interactive
# then:
#   setenv bootargs 'rd=md0 -v serial=3'
#   bootxnu 0x44000000 0x46000000
```

U-Boot binary defaults to `~/src/u-boot/u-boot.bin`. Rebuild that tree with
`make qemu_arm64_defconfig && make LLVM=1` (needs `CONFIG_CMD_BOOTXNU`, which
is default-y in tinted-software U-Boot).
