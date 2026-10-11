#include "ShmerV.h"

#define BUTTON_MASK (GPIO_PIN0 | GPIO_PIN1)

static volatile uint8_t interrupt_count;
static volatile uint8_t button_waiting_for_release;
static volatile uint8_t uart_pending_buttons;
static uint8_t next_character;

static void uart_send_next_character(void)
{
    /* START also covers the request and completion cycles when BUSY is zero. */
    while (UART_CTRL & (UART_START_TX | UART_BUSY_TX)) {
    }
    UART_TX_DATA = next_character;
    UART_CTRL |= UART_START_TX;
    while (UART_CTRL & (UART_START_TX | UART_BUSY_TX)) {
    }
    next_character = next_character == 'Z' ? 'A' : next_character + 1u;
}

static void delay_between_button_samples(void)
{
    /* Volatile preserves the delay loop; its duration depends on compilation. */
    for (volatile uint32_t remaining = 211u; remaining > 0u; --remaining) {
    }
}

SHMERV_INTERRUPT(SHMERV_IRQ_GPIO_A, button_handler)
void button_handler(void)
{
    uint8_t pending_buttons = PORTA_IFG & BUTTON_MASK;
    PORTA_IE = 0x00u;
    button_waiting_for_release = 1u;
    uart_pending_buttons = pending_buttons;
    if (pending_buttons & GPIO_PIN0)
        ++interrupt_count;
    if (pending_buttons & GPIO_PIN1)
        interrupt_count += 2u;
    /* C.0 is UART TX; display the low seven count bits on C.1-C.7. */
    PORTC_OUT = (uint8_t)(interrupt_count << 1);
    PORTA_IFG_CLR = BUTTON_MASK;
}

int main(void)
{
    next_character = 'A';
    PORTC_SEL = PORTC_UART_TX_PIN;
    PORTC_OUT = 0x00u;
    PORTC_DIR = 0xFFu;
    UART_CTRL = 0u;
    UART_CTRL = UART_SPEED_9600 | UART_LSB_FIRST | UART_ENABLE;

    PORTA_IE = 0x00u;
    PORTA_SEL = 0x00u;
    PORTA_DIR = 0x00u;
    PORTA_IES = BUTTON_MASK; /* A.0/A.1: falling edge on a press with pull-up. */
    PORTA_IFG_CLR = 0xFFu;
    PORTA_IE = BUTTON_MASK;

    shmerv_interrupt_enable();

    while (1) {
        if (button_waiting_for_release) {
            uint8_t pending_buttons = uart_pending_buttons;
            uart_pending_buttons = 0u;
            if (pending_buttons & GPIO_PIN0)
                uart_send_next_character();
            if (pending_buttons & GPIO_PIN1)
                uart_send_next_character();
            uint8_t stable_release_samples = 0;
            /* Re-arm only after 20 consecutive samples of both buttons released. */
            while (stable_release_samples < 20u) {
                delay_between_button_samples();
                if ((PORTA_IN & BUTTON_MASK) == BUTTON_MASK)
                    ++stable_release_samples;
                else
                    stable_release_samples = 0;
            }
            /* GPIO records edges even while its interrupt is masked. */
            PORTA_IFG_CLR = BUTTON_MASK;
            button_waiting_for_release = 0u;
            PORTA_IE = BUTTON_MASK;
        }
    }
}
