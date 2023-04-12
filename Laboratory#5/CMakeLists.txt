cmake_minimum_required(VERSION 3.25.1)
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(arm_zephyr_lab2)

zephyr_include_directories(include)

target_sources(app PRIVATE main.c)
add_subdirectory(drivers)
