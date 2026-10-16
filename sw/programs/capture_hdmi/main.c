#include "ShmerV.h"

/* Default wiring: C.5 is low at rest and high while the button is pressed.
 * Set to 1 for a button that pulls the input low while pressed. */
#ifndef CAPTURE_BUTTON_ACTIVE_LOW
#define CAPTURE_BUTTON_ACTIVE_LOW 1
#endif

#define TEXT_COLOR ((HDMI_COLOR_WHITE << 4) | HDMI_COLOR_BLACK)
#if CAPTURE_BUTTON_ACTIVE_LOW
#define BUTTON_EDGES TA_CAPTURE_FALL_TO_RISE
#else
#define BUTTON_EDGES TA_CAPTURE_RISE_TO_FALL
#endif
#define CAPTURE_CONFIG (TA_CAPTURE_EXTERNAL | BUTTON_EDGES | TA_CAPTURE_IRQ_DONE)

static volatile uint32_t measurement_ready;
static volatile uint16_t measured_ticks, measured_overflow;
static uint8_t cursor_row, cursor_col;

static void write_cell(uint8_t row, uint8_t col, uint8_t character)
{
    uint32_t index = (uint32_t)row * 80u + col;
    SHMERV_MMIO16(HDMI_CHAR_BASE + HDMI_CHAR_STRIDE * index) =
        (uint16_t)(((uint16_t)character << 8) | TEXT_COLOR);
}

static void newline(void)
{
    cursor_col = 0;
    if (++cursor_row == 30u)
        cursor_row = 1u; // Keep the prompt; reuse result rows without scrolling.
    for (uint8_t col = 0; col < 80u; ++col)
        write_cell(cursor_row, col, ' ');
}

static void print_text(const char *text)
{
    while (*text) {
        write_cell(cursor_row, cursor_col, (uint8_t)*text++);
        if (++cursor_col == 80u)
            newline();
    }
}

static void print_ticks(uint16_t value)
{
    // Decimal conversion without division: RV32I has no hardware divide.
    static const uint16_t places[] = {10000u, 1000u, 100u, 10u, 1u};
    uint8_t started = 0;
    for (uint8_t index = 0; index < 5u; ++index) {
        uint8_t digit = 0;
        while (value >= places[index]) {
            value -= places[index];
            ++digit;
        }
        if (digit || started || index == 4u) {
            write_cell(cursor_row, cursor_col++, (uint8_t)('0' + digit));
            started = 1;
        }
    }
}

SHMERV_INTERRUPT(SHMERV_IRQ_TIMER_A_CAPTURE_1, capture_handler)
void capture_handler(void)
{
    measured_overflow = TA_CAPTURE1_CTRL & TA_CAPTURE_OVERFLOW;
    measured_ticks = TA_CAPTURE1_DELTA; // Reading DELTA acknowledges the IRQ.
    measurement_ready = 1;
}

static int button_pressed(void)
{
    int high = (PORTC_IN & PORTC_TA_CAPTURE1_PIN) != 0;
    return CAPTURE_BUTTON_ACTIVE_LOW ? !high : high;
}

int main(void)
{
    TA_CTRL = 0;
    TA_CAPTURE1_CTRL = 0;
    PORTC_DIR &= (uint8_t)~PORTC_TA_CAPTURE1_PIN;
    PORTC_SEL |= PORTC_TA_CAPTURE1_PIN;
    for (uint8_t row = 0; row < 30u; ++row)
        for (uint8_t col = 0; col < 80u; ++col)
            write_cell(row, col, ' ');
    print_text("hello, press the button at C.5");
    newline();

    TA_COUNTER = 0;
    TA_CTRL = TA_MODE_CONTINUOUS | TA_DIV_1024 | TA_INTERRUPT_ENABLE;
    shmerv_interrupt_enable();

    while (1) {
        // Single shot prevents later edges from replacing the displayed result.
        while (button_pressed()) {}
        measurement_ready = 0;
        TA_CAPTURE1_CTRL = CAPTURE_CONFIG;
        TA_CAPTURE1_CTRL = CAPTURE_CONFIG | TA_CAPTURE_ENABLE;
        while (!measurement_ready) {}

        if (measured_overflow) {
            print_text("overflow: held for more than 65535 timer ticks");
        } else {
            print_text("pressed: ");
            print_ticks(measured_ticks);
            print_text(" timer ticks (CPU cycles / 1024)");
        }
        newline();
    }
}
