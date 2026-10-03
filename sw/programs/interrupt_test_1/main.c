#include "ShmerV.h"

static volatile uint8_t interrupt_count;
static volatile uint8_t button_waiting_for_release;
static volatile uint8_t uart_pending_buttons;
static uint8_t next_character;

static void uart_send_next_character(void)
{
    UART_DATA = next_character;
    UART_CTRL = 0x01u;
    /* UART has no readable busy flag. Conservative wait at the current
       843.75 kHz clock and 9600 baud; recalibrate if either changes. */
    for (volatile uint32_t remaining = 256u; remaining > 0u; --remaining) {
    }
    next_character = next_character == 'Z' ? 'A' : next_character + 1u;
}

static void delay_between_button_samples(void)
{
    /* Volatile preserves the delay loop; its duration depends on compilation. */
    for (volatile uint32_t remaining = 211u; remaining > 0u; --remaining) {
    }
}

SHMERV_INTERRUPT("GPIO_A", button_handler)
void button_handler(void)
{
    uint8_t pending_buttons = PORTA_IFG & 0x03u;
    PORTA_IE = 0x00u;
    button_waiting_for_release = 1u;
    uart_pending_buttons = pending_buttons;
    if (pending_buttons & 0x01u)
        ++interrupt_count;
    if (pending_buttons & 0x02u)
        interrupt_count += 2u;
    /* C.0 is UART TX; display the low seven count bits on C.1-C.7. */
    PORTC_OUT = (uint8_t)(interrupt_count << 1);
    PORTA_IFG_CLR = 0x03u;
}

int main(void)
{
    next_character = 'A';
    PORTC_SEL = 0x01u;
    PORTC_OUT = 0x00u;
    PORTC_DIR = 0xFFu;

    PORTA_IE = 0x00u;
    PORTA_SEL = 0x00u;
    PORTA_DIR = 0x00u;
    PORTA_IES = 0x03u; /* A.0/A.1: falling edge on a press with pull-up. */
    PORTA_IFG_CLR = 0xFFu;
    PORTA_IE = 0x03u;

    shmerv_interrupt_enable();

    while (1) {
        if (button_waiting_for_release) {
            uint8_t pending_buttons = uart_pending_buttons;
            uart_pending_buttons = 0u;
            if (pending_buttons & 0x01u)
                uart_send_next_character();
            if (pending_buttons & 0x02u)
                uart_send_next_character();
            uint8_t stable_release_samples = 0;
            /* Re-arm only after 20 consecutive samples of both buttons released. */
            while (stable_release_samples < 20u) {
                delay_between_button_samples();
                if ((PORTA_IN & 0x03u) == 0x03u)
                    ++stable_release_samples;
                else
                    stable_release_samples = 0;
            }
            /* GPIO records edges even while its interrupt is masked. */
            PORTA_IFG_CLR = 0x03u;
            button_waiting_for_release = 0u;
            PORTA_IE = 0x03u;
        }
    }
}
