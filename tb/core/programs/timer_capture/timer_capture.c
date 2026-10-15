#include "ShmerV.h"

static volatile uint32_t irq_count, errors, expected_mode;
static volatile uint32_t captured_start, captured_end, captured_delta;
static volatile uint32_t completed_in_main;

SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_CAPTURE_1, capture_handler)
void capture_handler(void)
{
    uint32_t cause;
    uint16_t status = TA_CAPTURE1_CTRL;
    __asm__ volatile (".option push\n.option arch, +zicsr\n"
                      "csrr %0, mcause\n.option pop" : "=r"(cause));
    if (cause != 0x80000017u || !(status & TA_CAPTURE_PENDING) ||
        (status & TA_CAPTURE_IRQ_MASK) != expected_mode)
        ++errors;

    if (expected_mode == TA_CAPTURE_IRQ_DONE) {
        if (status & (TA_CAPTURE_ENABLE | TA_CAPTURE_OVERFLOW))
            ++errors;
        captured_start = TA_CAPTURE1_START;
        captured_end = TA_CAPTURE1_END;
        captured_delta = TA_CAPTURE1_DELTA; // Read acknowledges pending.
    } else {
        if (!(status & TA_CAPTURE_ENABLE))
            ++errors;
        captured_start = TA_CAPTURE1_START;
        TA_CAPTURE1_CTRL = (uint16_t)(status & (uint16_t)~TA_CAPTURE_PENDING);
    }
    if (TA_CAPTURE1_CTRL & TA_CAPTURE_PENDING)
        ++errors;
    ++irq_count;
}

static void arm(uint16_t mode, uint16_t initial_counter)
{
    TA_CTRL = 0;
    TA_CAPTURE1_CTRL = 0;
    expected_mode = mode;
    TA_COUNTER = initial_counter;
    TA_CAPTURE1_CTRL = TA_CAPTURE_MANUAL | TA_CAPTURE_RISE_TO_FALL |
                       TA_CAPTURE_ENABLE | mode;
    TA_CTRL = TA_MODE_CONTINUOUS | TA_DIV_1 | TA_INTERRUPT_ENABLE;
}

static void pulse(void)
{
    TA_CAPTURE1_CTRL |= TA_CAPTURE_IN;
    // Deliberately bounded interval; no timer counter writes during capture.
    __asm__ volatile (".rept 256\nnop\n.endr" ::: "memory");
    TA_CAPTURE1_CTRL &= (uint16_t)~TA_CAPTURE_IN;
}

int main(void)
{
    shmerv_interrupt_enable();

    // DONE IRQ, ordinary interval and a short interval across a real wrap.
    for (uint32_t wrap = 0; wrap < 2u; ++wrap) {
        arm(TA_CAPTURE_IRQ_DONE, wrap ? 0xFFC0u : 0u);
        pulse();
        while (irq_count < wrap + 1u) {}
        if (irq_count != wrap + 1u ||
            captured_delta != (uint16_t)(captured_end - captured_start) ||
            captured_delta < 256u || captured_delta > 512u)
            ++errors;
        if ((wrap && captured_end >= captured_start) ||
            (!wrap && captured_end <= captured_start))
            ++errors;
        ++completed_in_main; // Reached after the interrupt handler's MRET.
    }

    // START IRQ uses the same vector; DONE must not generate another interrupt.
    arm(TA_CAPTURE_IRQ_START, 0u);
    pulse();
    while (TA_CAPTURE1_CTRL & TA_CAPTURE_ENABLE) {}
    if (irq_count != 3u || (TA_CAPTURE1_CTRL & TA_CAPTURE_PENDING) ||
        TA_CAPTURE1_START != captured_start)
        ++errors;
    captured_end = TA_CAPTURE1_END;
    captured_delta = TA_CAPTURE1_DELTA;
    // START handler execution is included in this interval.
    if (captured_end <= captured_start ||
        captured_delta != (uint16_t)(captured_end - captured_start) ||
        captured_delta < 256u)
        ++errors;
    ++completed_in_main;
    TA_CTRL = 0;

    return (errors == 0u && irq_count == 3u && completed_in_main == 3u) ? 1 : 2;
}
