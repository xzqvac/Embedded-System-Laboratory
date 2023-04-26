#include <zephyr/kernel.h>
#include <zephyr/logging/log.h>
#include <zephyr/fs/fs.h>
#include <stdint.h>

LOG_MODULE_REGISTER(main);

K_FIFO_DEFINE(data_fifo);

struct data {
	uint8_t a;
	uint8_t b;
};

static void test0_func(void *, void *, void *) {
	while (true) {
		struct data some_data = { .a = 1, .b = 2 };
		k_fifo_put(&data_fifo, &some_data);
		k_sleep(K_MSEC(1000));
	}
}

static void test1_func(void *, void *, void *) {
	while (true) {
		struct data *pointer = k_fifo_get(&data_fifo, K_FOREVER);
		LOG_INF("Data: %d %d", pointer->a, pointer->b);
	}
}

K_THREAD_DEFINE(test0, 1024, test0_func, NULL, NULL, NULL, 7, 0, 0);
K_THREAD_DEFINE(test1, 1024, test1_func, NULL, NULL, NULL, 7, 0, 0);

void main(void) {
	LOG_INF("main");
	int ret = 0;
	struct fs_file_t my_file;

	fs_file_t_init(&my_file);
	ret = fs_open(&my_file, "/lfs/test1", FS_O_RDWR | FS_O_CREATE);
	LOG_INF("Open %d", ret);
	ret = fs_write(&my_file, "HEHEHE", 6);
	LOG_INF("Write %d", ret);
	ret = fs_close(&my_file);
	LOG_INF("Close %d", ret);
	ret = fs_mkdir("/lfs/test2");
	LOG_INF("Mkdir %d", ret);
}
