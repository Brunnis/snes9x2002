DEBUG=0
TARGET_NAME = pocketsnes

ifeq ($(platform),)
platform = unix
ifeq ($(shell uname -a),)
   platform = win
else ifneq ($(findstring MINGW,$(shell uname -a)),)
   platform = win
else ifneq ($(findstring Darwin,$(shell uname -a)),)
   platform = osx
else ifneq ($(findstring win,$(shell uname -a)),)
   platform = win
endif
endif

ifeq ($(platform), unix)
   TARGET := $(TARGET_NAME)_libretro.so
   fpic := -fPIC
   SHARED := -shared -Wl,--version-script=libretro/link.T -Wl,--no-undefined
   CFLAGS += -fno-builtin \
            -fno-exceptions -ffunction-sections \
             -fomit-frame-pointer -fgcse-sm -fgcse-las -fgcse-after-reload \
             -fweb -fpeel-loops
else ifeq ($(platform), osx)
   TARGET := $(TARGET_NAME)_libretro.dylib
   fpic := -fPIC
   SHARED := -dynamiclib
else ifeq ($(platform), ios)
	TARGET := $(TARGET_NAME)_libretro_ios.dylib
	fpic := -fPIC
	SHARED := -dynamiclib
	ifeq ($(IOSSDK),)
		IOSSDK := $(shell xcodebuild -version -sdk iphoneos Path)
	endif
	CC = clang -arch armv7 -isysroot $(IOSSDK)
	CXX = clang++ -arch armv7 -isysroot $(IOSSDK)
	OSXVER = `sw_vers -productVersion | cut -d. -f 2`
	OSX_LT_MAVERICKS = `(( $(OSXVER) <= 9)) && echo "YES"`
	ifeq ($(OSX_LT_MAVERICKS),"YES")
		CC += -miphoneos-version-min=5.0
		CXX += -miphoneos-version-min=5.0
		PLATFORM_DEFINES := -miphoneos-version-min=5.0
	endif
   ARM_ASM = 1
   ASM_CPU = 0
   ASM_SPC700 = 0
else ifeq ($(platform), ps3)
   TARGET := $(TARGET_NAME)_libretro_ps3.a
   CC = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-gcc.exe
   AR = $(CELL_SDK)/host-win32/ppu/bin/ppu-lv2-ar.exe
   CFLAGS += -DBLARGG_BIG_ENDIAN=1 -D__ppc__
   STATIC_LINKING := 1
else ifeq ($(platform), sncps3)
   TARGET := $(TARGET_NAME)_libretro_ps3.a
   CC = $(CELL_SDK)/host-win32/sn/bin/ps3ppusnc.exe
   AR = $(CELL_SDK)/host-win32/sn/bin/ps3snarl.exe
   CFLAGS += -DBLARGG_BIG_ENDIAN=1 -D__ppc__
   STATIC_LINKING := 1
else ifeq ($(platform), xenon)
   TARGET := $(TARGET_NAME)_libretro_xenon360.a
   CC = xenon-gcc
   AR = xenon-ar
   CFLAGS += -D__LIBXENON__ -m32 -D__ppc__
   STATIC_LINKING := 1
else ifeq ($(platform), wii)
   TARGET := $(TARGET_NAME)_libretro_wii.a
   CC = $(DEVKITPPC)/bin/powerpc-eabi-gcc
   AR = $(DEVKITPPC)/bin/powerpc-eabi-ar
   CFLAGS += -DGEKKO -mrvl -mcpu=750 -meabi -mhard-float -DBLARGG_BIG_ENDIAN=1 -D__ppc__
   STATIC_LINKING := 1
# CTR (3DS)
else ifeq ($(platform), ctr)
   TARGET := $(TARGET_NAME)_libretro_ctr.a
   CC = $(DEVKITARM)/bin/arm-none-eabi-gcc$(EXE_EXT)
   CXX = $(DEVKITARM)/bin/arm-none-eabi-g++$(EXE_EXT)
   AR = $(DEVKITARM)/bin/arm-none-eabi-ar$(EXE_EXT)
   ARM_ASM = 1
   ASM_CPU = 0
   ASM_SPC700 = 0
   CFLAGS += -DARM11 -D_3DS 
   CFLAGS += -march=armv6k -mtune=mpcore -mfloat-abi=hard
   CFLAGS += -Wall -mword-relocations
   CFLAGS += -fomit-frame-pointer -ffast-math
   CFLAGS += -D_3DS
   PLATFORM_DEFINES := -D_3DS
   STATIC_LINKING := 1
else
   TARGET := $(TARGET_NAME)_libretro.dll
   CC = gcc
   fpic := 
   LD_FLAGS := 
   SHARED := -shared -static-libgcc -static-libstdc++ -Wl,--version-script=libretro/link.T
   CFLAGS += -D__WIN32__ -D__WIN32_LIBRETRO__
endif

CORE_DIR     := ./src
LIBRETRO_DIR := ./libretro

include Makefile.common

OBJECTS := $(SOURCES:.c=.o)
OBJECTS := $(OBJECTS:.cpp=.o)
OBJECTS := $(OBJECTS:.S=.o)
OBJECTS := $(OBJECTS:.s=.o)

CFLAGS += $(DEFINES) $(COMMON_DEFINES) $(INCLUDES)

all: $(TARGET)

$(TARGET): $(OBJECTS)
ifeq ($(STATIC_LINKING), 1)
	$(AR) rcs $@ $(OBJECTS)
else
	$(CC) $(fpic) $(SHARED) $(INCLUDES) -o $@ $(OBJECTS) -lm
endif

%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

%.o: %.cpp
	$(CXX) $(CFLAGS) -c -o $@ $<

%.o: %.s
	$(CXX) $(CFLAGS) -Wa,-I./src/ -c -o $@ $<

%.o: %.S
	$(CXX) $(CFLAGS) -Wa,-I./src/ -c -o $@ $<

clean:
	rm -f $(OBJECTS) $(TARGET)

.PHONY: clean

