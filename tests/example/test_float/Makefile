RISCV_ARCH := rv32imf
RISCV_ABI := ilp32f
RISCV_MCMODEL := medlow


TARGET = test_float


CFLAGS += -DSIMULATION
#CFLAGS += -O2
#ASM_SRCS +=
#LDFLAGS +=
#INCLUDES += -I.

C_SRCS := \
	main.c \


COMMON_DIR = ..
TOOLCHAIN_DIR = ../../..
include ../common.mk
