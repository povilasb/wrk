CFLAGS  := -std=c99 -Wall -O2 -D_REENTRANT -g
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

SRC  := cli_options.c wrk.c net.c ssl.c aprintf.c stats.c script.c units.c \
		ae.c zmalloc.c http_parser.c config.c base64.c http.c
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

test:
	mkdir -p build/tests
	$(MAKE) test-options
	$(MAKE) test-script
	$(MAKE) test-config
	$(MAKE) test-base64
	$(MAKE) test-http
.PHONY: test

test-options:
	$(CC) $(CFLAGS) tests/test_options.c $(src_files) $(LIBS) $(LDFLAGS) \
		-o build/tests/test_options -g

	build/tests/test_options
.PHONY: test-options

test-script:
	$(CC) $(CFLAGS) tests/test_script.c $(src_files) $(LIBS) $(LDFLAGS) \
		-o build/tests/test_script -g

	build/tests/test_script
.PHONY: test-script

test-config:
	$(CC) $(CFLAGS) tests/test_config.c $(src_files) $(LIBS) $(LDFLAGS) \
		-o build/tests/test_config -g

	build/tests/test_config
.PHONY: test-config

test-base64:
	$(CC) $(CFLAGS) tests/test_base64.c $(src_files) $(LIBS) $(LDFLAGS) \
		-o build/tests/test_base64 -g

	build/tests/test_base64
.PHONY: test-base64

test-http:
	$(CC) $(CFLAGS) tests/test_http.c $(src_files) $(LIBS) $(LDFLAGS) \
		-o build/tests/test_http -g

	build/tests/test_http
.PHONY: test-http

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
