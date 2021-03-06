PKGS = harfbuzz

CFLAGS = -O2 -fpic -std=c99 `pkg-config --cflags $(PKGS)` `pkg-config --cflags lua`
LDFLAGS = -O2 -fpic `pkg-config --libs $(PKGS)`

# Guide to building Lua Modules: http://lua-users.org/wiki/BuildingModules
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
    LIBFLAGS = -shared
endif
ifeq ($(UNAME_S),Darwin)
    LIBFLAGS = -bundle -undefined dynamic_lookup -all_load
endif

# For compatibility with Luarocks
INST_PREFIX = /usr/local
INST_LIBDIR = $(INST_PREFIX)/lib/lua/5.2
INST_LUADIR = $(INST_PREFIX)/share/lua/5.2

BUILD_DIR := build
C_SRC_ROOT := harfbuzz
SOURCES := core_wrap.cxx
OBJECTS := $(SOURCES:%.c=$(BUILD_DIR)/%.o)

all: dirs swiglib-harfbuzz.so

swiglib-harfbuzz.so: $(OBJECTS)
	$(CC) $(LDFLAGS) $(LIBFLAGS) $(OBJECTS) -o $@

$(BUILD_DIR)/%.o: $(C_SRC_ROOT)/%.c
	$(CC) $(CFLAGS) -o $@ -c $<

dirs: ${BUILD_DIR}

${BUILD_DIR}:
	mkdir -p ${BUILD_DIR}

spec: all
	busted .

clean:
	rm -rf build *.so

lint:
	luacheck src spec examples

# For use with Luarocks
# install: swiglib-harfbuzz.so src/harfbuzz.lua
# 	cp swiglib-harfbuzz.so $(INST_LIBDIR)
# 	cp src/harfbuzz.lua $(INST_LUADIR)

.PHONY: all clean test dirs install lint spec
