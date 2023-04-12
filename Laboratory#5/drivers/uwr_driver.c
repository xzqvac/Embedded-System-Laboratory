#define DT_DRV_COMPAT uwr_magicdevice // inform Zephyr that this is a driver for a device with the uwr_magicdevice compatible string

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/drivers/sensor.h>
#include <zephyr/logging/log.h>
LOG_MODULE_REGISTER(uwr_driver, LOG_LEVEL_DBG);

struct uwr_driver_config {
	struct gpio_dt_spec ledUp;
	struct gpio_dt_spec ledLeft;
	struct gpio_dt_spec ledRight;
	struct gpio_dt_spec ledDown;

	const struct device *acc;
};

struct uwr_driver_data {
	const struct device *dev;
	struct k_work work;
	struct k_timer timer;
};

static void work_handler(struct k_work *work) {
	struct uwr_driver_data *data = CONTAINER_OF(work, struct uwr_driver_data, work);
	const struct uwr_driver_config *config = data->dev->config;
	sensor_sample_fetch(config->acc);
	struct sensor_value values[3];
	
	sensor_channel_get(config->acc ,SENSOR_CHAN_ACCEL_XYZ, values);

	LOG_INF("( x y z ) = ( %f  %f  %f )\n", sensor_value_to_double(&values[0]),
						sensor_value_to_double(&values[1]),
						sensor_value_to_double(&values[2]));
}

static void timer_handler(struct k_timer *timer)
{
	struct uwr_driver_data *data = CONTAINER_OF(timer, struct uwr_driver_data, timer);
	k_work_submit(&data->work);
}

static int uwr_driver_init(const struct device *dev)
{
	LOG_INF("uwr driver init");

	const struct uwr_driver_config *config = dev->config;
	struct uwr_driver_data *data = dev->data;

	data->dev = dev;
	
	if (!gpio_is_ready_dt(&config->ledUp)) {
		return -ENOENT;
	}

	gpio_pin_configure_dt(&config->ledUp, GPIO_OUTPUT_INACTIVE);
	gpio_pin_configure_dt(&config->ledLeft, GPIO_OUTPUT_INACTIVE);
	gpio_pin_configure_dt(&config->ledDown, GPIO_OUTPUT_INACTIVE);
	gpio_pin_configure_dt(&config->ledRight, GPIO_OUTPUT_INACTIVE);

	k_work_init(&data->work, work_handler);
	
	k_timer_init(&data->timer, timer_handler, NULL);
	k_timer_start(&data->timer, K_MSEC(1000), K_MSEC(100));


	return 0;
}

const static struct uwr_driver_config uwr_driver_config = { 
	.ledUp = GPIO_DT_SPEC_INST_GET(0, up_gpios),	
	.ledLeft = GPIO_DT_SPEC_INST_GET(0, left_gpios),	
	.ledDown = GPIO_DT_SPEC_INST_GET(0, down_gpios),	
	.ledRight = GPIO_DT_SPEC_INST_GET(0, right_gpios),	
	.acc = DEVICE_DT_GET(DT_INST_PHANDLE(0, accelerometer)),

}; 
static struct uwr_driver_data uwr_driver_data; 
DEVICE_DT_INST_DEFINE(0, uwr_driver_init, 
				NULL, &uwr_driver_data, &uwr_driver_config, 
				APPLICATION, 
				CONFIG_GPIO_INIT_PRIORITY, 
				NULL);
