#include <zephyr/kernel.h>
#include <zephyr/shell/shell.h>
#include <zephyr/logging/log.h>
#include <zephyr/drivers/gpio.h>

LOG_MODULE_REGISTER(main, LOG_LEVEL_DBG);

static const struct gpio_dt_spec orange_led = GPIO_DT_SPEC_GET(DT_NODELABEL(orange_led_3), gpios);
static const struct gpio_dt_spec green_led = GPIO_DT_SPEC_GET(DT_NODELABEL(green_led_4), gpios);
static const struct gpio_dt_spec red_led = GPIO_DT_SPEC_GET(DT_NODELABEL(red_led_5), gpios);
static const struct gpio_dt_spec blue_led = GPIO_DT_SPEC_GET(DT_NODELABEL(blue_led_6), gpios);

static struct k_timer led_timer;

static bool is_running = false;

static int leds_state = 8;

static void initialize_gpio(void) {
    gpio_pin_configure_dt(&green_led, GPIO_OUTPUT_INACTIVE);
    gpio_pin_configure_dt(&orange_led, GPIO_OUTPUT_INACTIVE);
    gpio_pin_configure_dt(&red_led, GPIO_OUTPUT_INACTIVE);
    gpio_pin_configure_dt(&blue_led, GPIO_OUTPUT_INACTIVE);
}

void set_states_of_leds() {
    gpio_pin_set_dt(&red_led, leds_state & 8);
    gpio_pin_set_dt(&orange_led, leds_state & 4);
    gpio_pin_set_dt(&green_led, leds_state & 2);
    gpio_pin_set_dt(&blue_led, leds_state & 1);
}

void shift_leds() {
    // if bit 1 is 1, add 16
    if (leds_state & 1){
        leds_state += 16;
        leds_state -= 1;
    }
    leds_state = leds_state >> 1;
}

static void led_timer_handler(struct k_timer *timer) {
    // shift bits
    shift_leds();
    set_states_of_leds();
}

static int led_on(const struct shell *shell, size_t argc, char **argv)
{
    switch(*argv[1]){
        case '1':
            shell_print(shell, "Led on green");
            gpio_pin_set_dt(&green_led, 1);
            break;
        case '2':
            shell_print(shell, "Led on orange");
            gpio_pin_set_dt(&orange_led, 1);
            break;
        case '3':
            shell_print(shell, "Led on red");
            gpio_pin_set_dt(&red_led, 1);
            break;
        case '4':
            shell_print(shell, "Led on blue");
            gpio_pin_set_dt(&blue_led, 1);
            break;
        default:
            break;
   }
    return 0;
}

static int led_off(const struct shell *shell, size_t argc, char **argv)
{
    switch(*argv[1]){
        case '1':
            shell_print(shell, "Led off green");
            gpio_pin_set_dt(&green_led, 0);
            break;
        case '2':
            shell_print(shell, "Led off orange");
            gpio_pin_set_dt(&orange_led, 0);
            break;
        case '3':
            shell_print(shell, "Led off red");
            gpio_pin_set_dt(&red_led, 0);
            break;
        case '4':
            shell_print(shell, "Led off blue");
            gpio_pin_set_dt(&blue_led, 0);
            break;
        default:
            break;
   }
    return 0;
}

static int run_diode(void){
    k_timer_start(&led_timer, K_MSEC(100), K_SECONDS(1));
}

SHELL_STATIC_SUBCMD_SET_CREATE(sub_led,
    SHELL_CMD_ARG(on, NULL, "Led on", led_on, 2, 0),
    SHELL_CMD_ARG(off, NULL, "Led off", led_off, 2, 0),
    SHELL_SUBCMD_SET_END /* Array terminated. */
);

SHELL_CMD_REGISTER(led, &sub_led, "Led control", NULL);
SHELL_CMD_REGISTER(blink, NULL, "Set running diode", &run_diode);

int main(void) {
    initialize_gpio();
    k_timer_init(&led_timer, led_timer_handler, NULL);

    return 0;
}