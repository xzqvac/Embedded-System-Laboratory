#define DT_DRV_COMPAT uwr_magicdevice // inform Zephyr that this is a driver for a device with the uwr_magicdevice compatible string

#include <zephyr/kernel.h>
#include <zephyr/device.h>
#include <zephyr/drivers/gpio.h>
#include <zephyr/drivers/sensor.h>
#include <zephyr/logging/log.h>
LOG_MODULE_REGISTER(uwr_driver, LOG_LEVEL_DBG);

struct uwr_driver_data {
	const struct device *dev;
};

static int uwr_driver_init(const struct device *dev)
{
	LOG_INF("uwr driver init");

	return 0;
}
