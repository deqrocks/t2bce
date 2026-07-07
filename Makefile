KVERSION ?= $(shell uname -r)
KDIR ?= /lib/modules/$(KVERSION)/build
PWD := $(shell pwd)
MODDEST ?= /lib/modules/$(KVERSION)/extra/t2bce

MODULE_DIRS := t2bce_dma t2bce_core t2bce_vhci t2bce_audio
MODULES := \
	t2bce_dma/t2bce_dma.ko \
	t2bce_core/t2bce_core.ko \
	t2bce_vhci/t2bce_vhci.ko \
	t2bce_audio/t2bce_audio.ko

.PHONY: all clean install install-modules install-ucm uninstall uninstall-modules uninstall-ucm modules_prepare

all: modules_prepare
	$(MAKE) -C t2bce_dma KVERSION=$(KVERSION)
	$(MAKE) -C t2bce_core KVERSION=$(KVERSION) T2BCE_DMA_SRC=../t2bce_dma
	$(MAKE) -C t2bce_vhci KVERSION=$(KVERSION) T2BCE_CORE_SRC=../t2bce_core
	$(MAKE) -C t2bce_audio KVERSION=$(KVERSION) T2BCE_CORE_SRC=../t2bce_core

modules_prepare:
	@test -d "$(KDIR)" || { echo "Kernel build directory not found: $(KDIR)"; exit 1; }

clean:
	for dir in $(MODULE_DIRS); do $(MAKE) -C $$dir KVERSION=$(KVERSION) clean; done

install: install-modules install-ucm

install-modules: all
	install -d -m 0755 "$(MODDEST)"
	for ko in $(MODULES); do install -m 0644 "$$ko" "$(MODDEST)/"; done
	depmod -a "$(KVERSION)"

install-ucm:
	install -d -m 0755 /usr/share/alsa/ucm2
	cp -a t2bce_audio-alsa-ucm-conf/ucm2/. /usr/share/alsa/ucm2/

uninstall: uninstall-modules uninstall-ucm

uninstall-modules:
	for ko in $(notdir $(MODULES)); do rm -f "$(MODDEST)/$$ko"; done
	depmod -a "$(KVERSION)"

uninstall-ucm:
	rm -f /usr/share/alsa/ucm2/AppleT2/HiFi.conf
	rm -f /usr/share/alsa/ucm2/conf.d/AppleT2x2/AppleT2x2.conf
	rm -f /usr/share/alsa/ucm2/conf.d/AppleT2x4/AppleT2x4.conf
	rm -f /usr/share/alsa/ucm2/conf.d/AppleT2x6/AppleT2x6.conf
	rmdir /usr/share/alsa/ucm2/AppleT2 2>/dev/null || true
	rmdir /usr/share/alsa/ucm2/conf.d/AppleT2x2 2>/dev/null || true
	rmdir /usr/share/alsa/ucm2/conf.d/AppleT2x4 2>/dev/null || true
	rmdir /usr/share/alsa/ucm2/conf.d/AppleT2x6 2>/dev/null || true
