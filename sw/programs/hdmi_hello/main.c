#include "ShmerV.h"

/* Match the current board top: 27 MHz / 4. */
#ifndef HDMI_HELLO_CPU_HZ
#define HDMI_HELLO_CPU_HZ 6750000u
#endif

/* Ten ~100 ms timer periods, divided by 16, make one second. */
#define TIMER_TICKS ((HDMI_HELLO_CPU_HZ + 80u) / 160u)
_Static_assert(TIMER_TICKS >= 1u && TIMER_TICKS <= 65536u,
               "100 ms period must fit Timer A");

static void write_cell(uint32_t index, uint8_t character)
{
    /* White foreground (15), black background (0). */
    SHMERV_MMIO16(HDMI_CHAR_BASE + HDMI_CHAR_STRIDE * index) =
        (uint16_t)(((uint16_t)character << 8) | 0xF0u);
}

static void wait_one_second(void)
{
    TA_CTRL = 0u;
    TA_COUNTER = 0u;
    TA_PERIOD = (uint16_t)(TIMER_TICKS - 1u);
    TA_CTRL = TA_MODE_UP | TA_DIV_16;
    for (uint32_t tick = 0; tick < 10u; ++tick) {
        while ((TA_CTRL & TA_OVERFLOW_PENDING) == 0u) {}
        /* Clear pending while keeping the timer running; interrupts are off. */
        TA_CTRL = TA_MODE_UP | TA_DIV_16;
    }
    TA_CTRL = 0u;
}

int main(void)
{
    static const char message[] = "hello world!";

    /* Replace the initialized font demo with a blank black screen. */
    for (uint32_t index = 0; index < HDMI_CHAR_COUNT; ++index)
        write_cell(index, ' ');

    for (uint32_t index = 0; index < sizeof(message) - 1u; ++index) {
        if (index != 0u) wait_one_second();
        write_cell(index, (uint8_t)message[index]);
    }

    while (1) {}
}
