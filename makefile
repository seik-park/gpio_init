# Standalone GNU Make build for Nuvoton M2351 GPIO_INT
#
# Place this file in the GPIO_INT repository root:
#   GPIO_INT/
#     Makefile
#     main.c
#     GCC/GPIO_INT.ld
#
# The Nuvoton BSP location is supplied at build time so the project does not
# depend on NuEclipse-generated Release/*.mk files.
#
# Git Bash example:
#   make BSP_ROOT="/c/project/samsung_hello_encrypt/EZF Series/M2351Series_BSP_CMSIS_V3.00.004" -j4
#
# Docker/Linux example:
#   make BSP_ROOT=/opt/M2351Series_BSP_CMSIS_V3.00.004 -j4

PROJECT      := GPIO_INT
BUILD_DIR    ?= build
GCC_DIR      := GCC
LINKER_SCRIPT := $(GCC_DIR)/GPIO_INT.ld

CROSS_COMPILE ?= arm-none-eabi-
CC       := $(CROSS_COMPILE)gcc
OBJCOPY  := $(CROSS_COMPILE)objcopy
SIZE     := $(CROSS_COMPILE)size

# BSP_ROOT must point to the directory which contains Library/.
ifndef BSP_ROOT
$(error BSP_ROOT is not set. Example: make BSP_ROOT="/c/project/.../M2351Series_BSP_CMSIS_V3.00.004" -j4)
endif

CMSIS_INC      := $(BSP_ROOT)/Library/CMSIS/Include
DEVICE_INC     := $(BSP_ROOT)/Library/Device/Nuvoton/M2351/Include
STDDRIVER_INC  := $(BSP_ROOT)/Library/StdDriver/inc
DEVICE_SRC     := $(BSP_ROOT)/Library/Device/Nuvoton/M2351/Source
GCC_SRC        := $(DEVICE_SRC)/GCC
STDDRIVER_SRC  := $(BSP_ROOT)/Library/StdDriver/src

# Match the options observed in the NuEclipse-generated build.
CPUFLAGS := -mcpu=cortex-m23 -march=armv8-m.base -mthumb -mlittle-endian
COMMONFLAGS := $(CPUFLAGS) -Os -fmessage-length=0 -fsigned-char \
               -ffunction-sections -fdata-sections -g

INCLUDES := -I"$(CMSIS_INC)" \
            -I"$(STDDRIVER_INC)" \
            -I"$(DEVICE_INC)"

CFLAGS   := $(COMMONFLAGS) $(INCLUDES) -std=gnu11 -MMD -MP
ASFLAGS  := $(COMMONFLAGS) -x assembler-with-cpp -MMD -MP
LDFLAGS  := $(CPUFLAGS) -Os -fmessage-length=0 -fsigned-char \
            -ffunction-sections -fdata-sections -g \
            -T "$(LINKER_SCRIPT)" -Xlinker --gc-sections \
            -Wl,-Map,"$(BUILD_DIR)/$(PROJECT).map" --specs=nano.specs

ELF := $(BUILD_DIR)/$(PROJECT).elf
HEX := $(BUILD_DIR)/$(PROJECT).hex
BIN := $(BUILD_DIR)/$(PROJECT).bin
MAP := $(BUILD_DIR)/$(PROJECT).map

# Source files required by the GPIO_INT sample, inferred from the successful
# NuEclipse build and undefined symbols in main.o.
MAIN_SRC       := main.c
SYSTEM_SRC     := $(DEVICE_SRC)/system_M2351.c
SYSCALLS_SRC   := $(GCC_SRC)/_syscalls.c
STARTUP_SRC    := $(GCC_SRC)/startup_M2351.S
CLK_SRC        := $(STDDRIVER_SRC)/clk.c
GPIO_SRC       := $(STDDRIVER_SRC)/gpio.c
SYS_SRC        := $(STDDRIVER_SRC)/sys.c
UART_SRC       := $(STDDRIVER_SRC)/uart.c
RETARGET_SRC   := $(STDDRIVER_SRC)/retarget.c

OBJS := \
  $(BUILD_DIR)/main.o \
  $(BUILD_DIR)/system_M2351.o \
  $(BUILD_DIR)/_syscalls.o \
  $(BUILD_DIR)/startup_M2351.o \
  $(BUILD_DIR)/clk.o \
  $(BUILD_DIR)/gpio.o \
  $(BUILD_DIR)/sys.o \
  $(BUILD_DIR)/uart.o \
  $(BUILD_DIR)/retarget.o

DEPS := $(OBJS:.o=.d)

# Escape spaces only where a source path is parsed by make as a prerequisite.
empty :=
space := $(empty) $(empty)
escape_spaces = $(subst $(space),\ ,$(1))

.PHONY: all clean size check print-config

all: check $(ELF) $(HEX) $(BIN) size
	@echo
	@echo "[OK] Build complete"
	@echo "  ELF: $(ELF)"
	@echo "  BIN: $(BIN)"
	@echo "  HEX: $(HEX)"
	@echo "  MAP: $(MAP)"

check:
	@command -v "$(CC)" >/dev/null 2>&1 || { echo "[ERROR] $(CC) not found in PATH"; exit 1; }
	@command -v "$(OBJCOPY)" >/dev/null 2>&1 || { echo "[ERROR] $(OBJCOPY) not found in PATH"; exit 1; }
	@command -v "$(SIZE)" >/dev/null 2>&1 || { echo "[ERROR] $(SIZE) not found in PATH"; exit 1; }
	@test -f "$(LINKER_SCRIPT)" || { echo "[ERROR] Missing linker script: $(LINKER_SCRIPT)"; exit 1; }
	@test -f "$(SYSTEM_SRC)" || { echo "[ERROR] Invalid BSP_ROOT; missing: $(SYSTEM_SRC)"; exit 1; }
	@test -f "$(STARTUP_SRC)" || { echo "[ERROR] Missing startup file: $(STARTUP_SRC)"; exit 1; }
	@test -f "$(CLK_SRC)" || { echo "[ERROR] Missing StdDriver source: $(CLK_SRC)"; exit 1; }
	@test -f "$(RETARGET_SRC)" || { echo "[ERROR] Missing retarget source: $(RETARGET_SRC)"; exit 1; }
	@mkdir -p "$(BUILD_DIR)"

$(ELF): $(OBJS) $(LINKER_SCRIPT) | check
	@echo "[LD] $@"
	$(CC) $(LDFLAGS) -o "$@" $(OBJS)

$(HEX): $(ELF)
	@echo "[HEX] $@"
	$(OBJCOPY) -O ihex "$<" "$@"

$(BIN): $(ELF)
	@echo "[BIN] $@"
	$(OBJCOPY) -O binary "$<" "$@"

size: $(ELF)
	@echo "[SIZE] $(ELF)"
	$(SIZE) --format=berkeley "$(ELF)"

$(BUILD_DIR)/main.o: $(MAIN_SRC) | check
	@echo "[CC] $<"
	$(CC) $(CFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$<"

$(BUILD_DIR)/system_M2351.o: $(call escape_spaces,$(SYSTEM_SRC)) | check
	@echo "[CC] $(SYSTEM_SRC)"
	$(CC) $(CFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$(SYSTEM_SRC)"

$(BUILD_DIR)/_syscalls.o: $(call escape_spaces,$(SYSCALLS_SRC)) | check
	@echo "[CC] $(SYSCALLS_SRC)"
	$(CC) $(CFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$(SYSCALLS_SRC)"

$(BUILD_DIR)/startup_M2351.o: $(call escape_spaces,$(STARTUP_SRC)) | check
	@echo "[AS] $(STARTUP_SRC)"
	$(CC) $(ASFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$(STARTUP_SRC)"

$(BUILD_DIR)/clk.o: $(call escape_spaces,$(CLK_SRC)) | check
	@echo "[CC] $(CLK_SRC)"
	$(CC) $(CFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$(CLK_SRC)"

$(BUILD_DIR)/gpio.o: $(call escape_spaces,$(GPIO_SRC)) | check
	@echo "[CC] $(GPIO_SRC)"
	$(CC) $(CFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$(GPIO_SRC)"

$(BUILD_DIR)/sys.o: $(call escape_spaces,$(SYS_SRC)) | check
	@echo "[CC] $(SYS_SRC)"
	$(CC) $(CFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$(SYS_SRC)"

$(BUILD_DIR)/uart.o: $(call escape_spaces,$(UART_SRC)) | check
	@echo "[CC] $(UART_SRC)"
	$(CC) $(CFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$(UART_SRC)"

$(BUILD_DIR)/retarget.o: $(call escape_spaces,$(RETARGET_SRC)) | check
	@echo "[CC] $(RETARGET_SRC)"
	$(CC) $(CFLAGS) -MF"$(@:.o=.d)" -MT"$@" -c -o "$@" "$(RETARGET_SRC)"

clean:
	rm -rf "$(BUILD_DIR)"
	@echo "[OK] Clean complete"

print-config:
	@echo "PROJECT=$(PROJECT)"
	@echo "BSP_ROOT=$(BSP_ROOT)"
	@echo "BUILD_DIR=$(BUILD_DIR)"
	@echo "CC=$(CC)"
	@echo "LINKER_SCRIPT=$(LINKER_SCRIPT)"

-include $(DEPS)
