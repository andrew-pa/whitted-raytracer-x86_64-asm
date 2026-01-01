AS := nasm
ASFLAGS := -f elf64 -g -F dwarf
LD := gcc

PNG_LIBS := $(shell pkg-config --libs libpng 2>/dev/null)
ifeq ($(PNG_LIBS),)
PNG_LIBS := -lpng -lz
endif

LIBS := $(PNG_LIBS) -lm -lpthread

SRC := \
	src/asm/main.asm \
	src/asm/scene.asm \
	src/asm/parser.asm \
	src/asm/math.asm \
	src/asm/texture.asm \
	src/asm/intersect.asm \
	src/asm/shading.asm \
	src/asm/render.asm \
	src/asm/png.asm \
	src/asm/threading.asm

OBJ := $(SRC:src/asm/%.asm=build/%.o)

TARGET := raytrace

all: $(TARGET)

build:
	mkdir -p build

build/%.o: src/asm/%.asm | build
	$(AS) $(ASFLAGS) -o $@ $<

$(TARGET): $(OBJ)
	$(LD) -no-pie -o $@ $^ $(LIBS)

clean:
	rm -rf build $(TARGET)

.PHONY: all clean
