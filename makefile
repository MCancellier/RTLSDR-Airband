# Install prefix
PREFIX = /usr/local

SYSCONFDIR = $(PREFIX)/etc
DEFCONFIG = config/basic_multichannel.conf
CFG = rtl_airband.conf
BINDIR = $(PREFIX)/bin
export DEBUG ?= 0
export CC = g++
export CFLAGS = -O3 -g -Wall -DSYSCONFDIR=\"$(SYSCONFDIR)\" -DDEBUG=$(DEBUG)
export CXXFLAGS = $(CFLAGS)
LDLIBS = -lrt -lm -lvorbisenc -lmp3lame -lshout -lpthread -lrtlsdr -lconfig++

SUBDIRS = hello_fft
CLEANDIRS = $(SUBDIRS:%=clean-%)

BIN = rtl_airband
OBJ = rtl_airband.o output.o config.o util.o mixer.o
FFT = hello_fft/hello_fft.a

.PHONY: all clean install $(SUBDIRS) $(CLEANDIRS)

ifeq ($(PLATFORM), rpiv1)
  CFLAGS += -DUSE_BCM_VC
  CFLAGS += -I/opt/vc/include  -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux
  CFLAGS += -mcpu=arm1176jzf-s -mtune=arm1176jzf-s -march=armv6zk -mfpu=vfp -ffast-math 
  LDLIBS += -lbcm_host -ldl
  export LDFLAGS = -L/opt/vc/lib
  DEPS = $(OBJ) $(FFT) rtl_airband_vfp.o
else ifeq ($(PLATFORM), rpiv2)
  CFLAGS += -DUSE_BCM_VC
  CFLAGS += -I/opt/vc/include  -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux
  CFLAGS += -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -ffast-math 
  LDLIBS += -lbcm_host -ldl
  export LDFLAGS = -L/opt/vc/lib
  DEPS = $(OBJ) $(FFT) rtl_airband_neon.o
else ifeq ($(PLATFORM), rpiv3)
  CFLAGS += -DUSE_BCM_VC
  CFLAGS += -I/opt/vc/include  -I/opt/vc/include/interface/vcos/pthreads -I/opt/vc/include/interface/vmcs_host/linux
  CFLAGS += -march=armv8-a+crc -mtune=cortex-a53 -ffast-math
  LDLIBS += -lbcm_host -ldl
  export LDFLAGS = -L/opt/vc/lib
  DEPS = $(OBJ) $(FFT) rtl_airband_neon.o
else ifeq ($(PLATFORM), armv7-generic)
  CFLAGS += -march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard -ffast-math 
  LDLIBS += -lfftw3f
  DEPS = $(OBJ)
else ifeq ($(PLATFORM), armv8-generic)
  CFLAGS += -march=armv8-a+crc -mtune=cortex-a53 -ffast-math
  LDLIBS += -lfftw3f
  DEPS = $(OBJ)
else ifeq ($(PLATFORM), x86)
  CFLAGS += -march=native
  LDLIBS += -lfftw3f
  DEPS = $(OBJ)
else
  DEPS =
endif
ifeq ($(NFM), 1)
  CFLAGS += -DNFM
endif

$(BIN): $(DEPS)
ifndef DEPS
	@printf "\nPlease set PLATFORM variable to one of available platforms:\n \
	\tPLATFORM=rpiv1 make\t\tRaspberry Pi V1 (ARMv6, VFP FPU, use BCM VideoCore for FFT)\n \
	\tPLATFORM=rpiv2 make\t\tRaspberry Pi V2 (ARMv7, NEON FPU, use BCM VideoCore for FFT)\n \
	\tPLATFORM=rpiv3 make\t\tRaspberry Pi V3 (ARMv8, NEON FPU, use BCM VideoCore for FFT)\n \
	\tPLATFORM=armv7-generic make\tARMv7 platforms without BCM VideoCore, like Cubieboard (NEON FPU, use main CPU for FFT)\n \
	\tPLATFORM=armv8-generic make\tARMv8 platforms without BCM VideoCore, like Odroid C2 (use main CPU for FFT)\n \
	\tPLATFORM=x86 make\t\tbuild binary for x86\n\n \
	Additional options:\n \
	\tNFM=1\t\t\t\tInclude support for Narrow FM demodulation\n \
	\t\t\t\t\tWarning: this incurs noticeable performance penalty both for AM and FM\n \
	\t\t\t\t\tDo not enable NFM, if you only use AM (especially on low-power platforms, like RPi)\n\n"
	@false
endif

$(FFT):	hello_fft ;

config.o: rtl_airband.h

mixer.o: rtl_airband.h

rtl_airband.o: rtl_airband.h

output.o: rtl_airband.h

util.o: rtl_airband.h

$(SUBDIRS):
	$(MAKE) -C $@

clean: $(CLEANDIRS)
	rm -f *.o rtl_airband

install: $(BIN)
	install -d -o root -g root $(BINDIR)
	install -o root -g root -m 755 $(BIN) $(BINDIR)
	install -d -o root -g root $(SYSCONFDIR)
	test -f $(SYSCONFDIR)/$(CFG) || install -o root -g root -m 600 $(DEFCONFIG) $(SYSCONFDIR)/$(CFG)
	@printf "\n *** Done. If this is a new install, edit $(SYSCONFDIR)/$(CFG) to suit your needs.\n\n"

$(CLEANDIRS):
	$(MAKE) -C $(@:clean-%=%) clean

