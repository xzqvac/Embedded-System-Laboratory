#ifndef UWR_DRIVER_API_H_
#define UWR_DRIVER_API_H_

#include <zephyr/device.h>

struct uwr_driver_api {
	int (*on)(const struct device *dev);
	int (*off)(const struct device *dev);
	int (*blink)(const struct device *dev, uint32_t msec);
	int (*stop_blink)(const struct device *dev);
};

static inline int uwr_on(const struct device *dev)
{
	const struct uwr_driver_api *api = (const struct uwr_driver_api *)dev->api;

	if (api->on == NULL) {
		return -ENOSYS;
	}

	return api->on(dev);
}

static inline int uwr_off(const struct device *dev)
{
	const struct uwr_driver_api *api = (const struct uwr_driver_api *)dev->api;

	if (api->off == NULL) {
		return -ENOSYS;
	}

	return api->off(dev);
}

static inline int uwr_blink(const struct device *dev, uint32_t msec)
{
	const struct uwr_driver_api *api = (const struct uwr_driver_api *)dev->api;

	if (api->blink == NULL) {
		return -ENOSYS;
	}

	return api->blink(dev, msec);
}

static inline int uwr_stop_blink(const struct device *dev)
{
	const struct uwr_driver_api *api = (const struct uwr_driver_api *)dev->api;

	if (api->stop_blink == NULL) {
		return -ENOSYS;
	}

	return api->stop_blink(dev);
}

#endif /* UWR_DRIVER_API_H_ */
