/*
 * Stand-in kernel for exercising U-Boot bootxnu on qemu virt until a
 * real XNU VMAPPLE image exists. Runs at EL1 with U-Boot's 1:1 map.
 *
 * Built as a static arm64 Mach-O; bootxnu loads it via LC_MAIN.
 */
#include <stdint.h>

#define UART_BASE 0x09000000u

static void uart_putc(char c)
{
	volatile uint32_t *uart = (volatile uint32_t *)(uintptr_t)UART_BASE;
	if (c == '\n')
		*uart = '\r';
	*uart = (uint32_t)(unsigned char)c;
}

static void uart_puts(const char *s)
{
	while (*s)
		uart_putc(*s++);
}

static void uart_puthex(uint64_t val)
{
	uart_puts("0x");
	for (int i = 60; i >= 0; i -= 4) {
		unsigned nibble = (unsigned)((val >> i) & 0xf);
		uart_putc((char)(nibble < 10 ? '0' + nibble : 'a' + (nibble - 10)));
	}
}

static int str_eq(const char *a, const char *b)
{
	while (*a && *a == *b) {
		a++;
		b++;
	}
	return *a == *b;
}

static uint32_t read_u32(const uint8_t *p)
{
	return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
	       ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static uint64_t read_u64(const uint8_t *p)
{
	return (uint64_t)read_u32(p) | ((uint64_t)read_u32(p + 4) << 32);
}

#define XNU_CMDLINE_LEN 608

struct xnu_boot_arguments {
	uint16_t revision;
	uint16_t version;
	uint64_t virt_base;
	uint64_t phys_base;
	uint64_t mem_size;
	uint64_t phys_end;
	struct {
		uint64_t base_addr;
		uint64_t display;
		uint64_t bytes_per_row;
		uint64_t width;
		uint64_t height;
		uint64_t depth;
	} video_information;
	uint32_t machine_type;
	uint64_t afdt;
	uint32_t afdt_length;
	char command_line[XNU_CMDLINE_LEN];
	uint64_t boot_flags;
	uint64_t mem_size_actual;
};

/* Clang Darwin: C start -> Mach-O _start; bootxnu jumps here with x0 = boot_args. */
void start(struct xnu_boot_arguments *ba)
{
	uart_puts("\n=======================================================\n");
	uart_puts("  OpenDarwin mock kernel (bootxnu / qemu virt)\n");
	uart_puts("=======================================================\n");
	uart_puts("phys_base  ");
	uart_puthex(ba->phys_base);
	uart_puts("\nmem_size   ");
	uart_puthex(ba->mem_size);
	uart_puts("\ncmdline    ");
	uart_puts(ba->command_line);
	uart_puts("\nafdt       ");
	uart_puthex(ba->afdt);
	uart_puts(" len ");
	uart_puthex(ba->afdt_length);
	uart_puts("\n");

	uint64_t rd_base = 0;
	uint64_t rd_size = 0;
	const uint8_t *p = (const uint8_t *)(uintptr_t)ba->afdt;
	const uint8_t *end = p + ba->afdt_length;
	while (p + 36 <= end) {
		char name[33];
		int i;
		for (i = 0; i < 32; i++)
			name[i] = (char)p[i];
		name[32] = 0;
		uint32_t len = read_u32(p + 32);
		if (str_eq(name, "RAMDisk") && len == 16) {
			rd_base = read_u64(p + 36);
			rd_size = read_u64(p + 44);
			break;
		}
		p++;
	}

	if (!rd_base || !rd_size) {
		uart_puts("[mockfs] no RAMDisk in AFDT; halting\n");
		for (;;)
			__asm__ volatile("wfi");
	}

	uart_puts("[mockfs] RAMDisk ");
	uart_puthex(rd_base);
	uart_puts(" size ");
	uart_puthex(rd_size);
	uart_puts("\n");

	uint32_t magic = read_u32((const uint8_t *)(uintptr_t)rd_base);
	if (magic != 0xfeedfacf) {
		uart_puts("[mockfs] RAMDisk is not a Mach-O 64 image\n");
		for (;;)
			__asm__ volatile("wfi");
	}

	/* LC_MAIN entryoff is at offset 8 of the load command. Walk cmds. */
	uint32_t ncmds = read_u32((const uint8_t *)(uintptr_t)(rd_base + 16));
	uint64_t off = rd_base + 32;
	uint64_t entry = 0;
	uint32_t c;
	for (c = 0; c < ncmds; c++) {
		uint32_t cmd = read_u32((const uint8_t *)(uintptr_t)off);
		uint32_t cmdsize = read_u32((const uint8_t *)(uintptr_t)(off + 4));
		if (cmd == 0x80000028) { /* LC_MAIN */
			entry = rd_base + read_u64((const uint8_t *)(uintptr_t)(off + 8));
			break;
		}
		if (cmdsize < 8)
			break;
		off += cmdsize;
	}

	if (!entry) {
		uart_puts("[mockfs] no LC_MAIN on PID 1\n");
		for (;;)
			__asm__ volatile("wfi");
	}

	uart_puts("[mockfs] jumping to PID 1 at ");
	uart_puthex(entry);
	uart_puts("\n======================= USERSWITCH ====================\n");

	((void (*)(void))entry)();

	for (;;)
		__asm__ volatile("wfi");
}
