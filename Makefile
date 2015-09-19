CFLAGS  := -std=c99 -Wall -O2 -D_REENTRANT
LIBS    := -lpthread -lm -lcrypto -lssl

CMOCKA_DIR := $(CURDIR)/deps/cmocka
CMOCKA_LIB_DIR := $(CMOCKA_DIR)/build/src
CMOCKA_LIB := $(CMOCKA_LIB_DIR)/libcmocka.so

TARGET  := $(shell uname -s | tr '[A-Z]' '[a-z]' 2>/dev/null || echo unknown)

ifeq ($(TARGET), sunos)
	CFLAGS += -D_PTHREADS -D_POSIX_C_SOURCE=200112L
	LIBS   += -lsocket
else ifeq ($(TARGET), darwin)
	LDFLAGS += -pagezero_size 10000 -image_base 100000000
else ifeq ($(TARGET), linux)
	CFLAGS  += -D_POSIX_C_SOURCE=200112L -D_BSD_SOURCE
	LIBS    += -ldl
	LDFLAGS += -Wl,-E
else ifeq ($(TARGET), freebsd)
	CFLAGS  += -D_DECLARE_C99_LDBL_MATH
	LDFLAGS += -Wl,-E
endif

SRC  := wrk.c net.c ssl.c aprintf.c stats.c script.c units.c \
		ae.c zmalloc.c http_parser.c
src_files = $(addprefix src/, $(filter-out wrk.c, $(SRC)) )
BIN  := wrk

ODIR := obj
OBJ  := $(patsubst %.c,$(ODIR)/%.o,$(SRC)) $(ODIR)/bytecode.o

LDIR     = deps/luajit/src
LIBS    := -lluajit $(LIBS)
CFLAGS  += -I$(LDIR)
LDFLAGS += -L$(LDIR)

all: $(BIN)

clean:
	$(RM) $(BIN) obj/*
	@$(MAKE) -C deps/luajit clean

test: $(CMOCKA_LIB)
	mkdir -p build/tests
	$(CC) $(CFLAGS) -I $(CMOCKA_DIR)/include -L$(CMOCKA_LIB_DIR) -lcmocka \
		tests/test_options.c $(src_files) $(LIBS) $(LDFLAGS) \
		-o build/tests/test_options
	LD_LIBRARY_PATH=$(CMOCKA_LIB_DIR) build/tests/test_options
.PHONY: test

$(CMOCKA_LIB):
	cd $(CMOCKA_DIR) && mkdir -p build && cd build && cmake .. && make

$(BIN): $(OBJ)
	@echo LINK $(BIN)
	@$(CC) $(LDFLAGS) -o $@ $^ $(LIBS)

$(OBJ): config.h Makefile $(LDIR)/libluajit.a | $(ODIR)

$(ODIR):
	@mkdir -p $@

$(ODIR)/bytecode.o: src/wrk.lua
	@echo LUAJIT $<
	@$(SHELL) -c 'cd $(LDIR) && ./luajit -b $(CURDIR)/$< $(CURDIR)/$@'

$(ODIR)/%.o : %.c
	@echo CC $<
	@$(CC) $(CFLAGS) -c -o $@ $<

$(LDIR)/libluajit.a:
	@echo Building LuaJIT...
	@$(MAKE) -C $(LDIR) BUILDMODE=static

.PHONY: all clean
.SUFFIXES:
.SUFFIXES: .c .o .lua

vpath %.c   src
vpath %.h   src
vpath %.lua scripts
