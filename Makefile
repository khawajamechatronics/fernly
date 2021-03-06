include mkenv.mk
include magic.mk

CFLAGS = -march=armv5te -mfloat-abi=soft -Wall \
	 -Os -ggdb -Iinclude -marm -fno-stack-protector
AFLAGS = 

LDFLAGS = --nostdlib -T fernvale.ld
LIBS = lib/libgcc-armv5.a

SRC_C = \
	bionic.c \
	cmd-hex.c \
	cmd-irq.c \
	cmd-peekpoke.c \
	cmd-reboot.c \
	cmd-sleep.c \
	cmd-spi.c \
	cmd-led.c \
	cmd-load.c \
	cmd-bl.c \
	cmd-lcd.c \
	cmd-keypad.c \
	emi.c \
	irq.c \
	lcd.c \
	main.c \
	scriptic.c \
	serial.c \
	spi.c \
	utils.c \
	vectors.c \
	vsprintf.c

SRC_S = \
	scriptic/set-plls.S \
	scriptic/enable-psram.S \
	scriptic/spi.S \
	scriptic/spi-blockmode.S \
	scriptic/keypad.S \
	start.S

OBJ = $(addprefix $(BUILD)/, $(SRC_S:.S=.o) $(SRC_C:.c=.o))

all: $(BUILD)/firmware.bin \
	$(BUILD)/usb-loader.bin \
	$(BUILD)/fernly-usb-loader
clean:
	$(RM) -rf $(BUILD)

$(BUILD)/fernly-usb-loader: fernly-usb-loader.c sha1.c sha1.h
	$(CC_NATIVE) fernly-usb-loader.c sha1.c -o $@

$(BUILD)/usb-loader.bin: $(BUILD)/usb-loader.o
	$(OBJCOPY) -S -O binary $(BUILD)/usb-loader.o $@

HEADER_BUILD = $(BUILD)/genhdr
$(BUILD)/firmware.bin: $(BUILD)/firmware.elf
	$(OBJCOPY) -S -O binary $(BUILD)/firmware.elf $@

$(BUILD)/firmware.elf: $(OBJ)
	$(LD) $(LDFLAGS) --entry=reset_handler -o $@ $(OBJ) $(LIBS)

$(OBJ): $(HEADER_BUILD)/generated.h | $(OBJ_DIRS)
$(HEADER_BUILD)/generated.h: | $(HEADER_BUILD)
	  touch $@

OBJ_DIRS = $(sort $(dir $(OBJ))) scriptic
$(OBJ_DIRS):
	$(MKDIR) -p $@ $@/scriptic
$(HEADER_BUILD):
	$(MKDIR) -p $@ build/scriptic
-include $(OBJ:.o=.P)

test: all
	novena-usb-hub -d u1 ; sleep 1; novena-usb-hub -e u1 ; sleep 2
	$(BUILD)/fernly-usb-loader /dev/fernvale $(BUILD)/usb-loader.bin $(BUILD)/firmware.bin

shell: all
	novena-usb-hub -d u1 ; sleep 1; novena-usb-hub -e u1 ; sleep 2
	$(BUILD)/fernly-usb-loader -s /dev/fernvale $(BUILD)/usb-loader.bin $(BUILD)/firmware.bin
