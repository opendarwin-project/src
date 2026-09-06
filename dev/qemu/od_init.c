/*
 * Minimal PID 1 for the mock-kernel RAMDisk.
 *
 * Writes the QEMU virt PL011 UART directly. A real XNU kernel would
 * intercept svc #0x80; this binary is only for the bootxnu bring-up
 * path (see od_init_darwin.c once XNU actually runs).
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

void start(void)
{
	uart_puts("\n=======================================================\n");
	uart_puts("  Hello from OpenDarwin PID 1 (mockfs RAMDisk)\n");
	uart_puts("  bootxnu -> mock kernel -> md0 Mach-O\n");
	uart_puts("=======================================================\n");
	uart_puts("# sitting in wfi (no syscall layer yet)\n");
	for (;;)
		__asm__ volatile("wfi");
}
