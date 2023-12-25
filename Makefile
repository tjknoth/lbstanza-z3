all: build

tests: z3-tests
	./z3-tests

test-%: z3-tests
	./z3-tests -tagged $(@:test-%=%)

build:
	stanza build

z3-tests: src/*.stanza tests/*.stanza conan-z3-static
	stanza build z3-tests


conan-z3-shared:
	SLM_BUILD_SHARED=1 ./build_conan.sh

conan-z3-static:
	SLM_BUILD_STATIC=1 ./build_conan.sh

.PHONY: conan-z3-shared conan-z3-static

# Wrapper Generator Targets
CONTENT_DIR=./build/content
LIBC_PKG=pycparser_fake_libc
PKG_BASE_DIR = $(shell python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
PKG_DIR = $(PKG_BASE_DIR)/$(LIBC_PKG)

Z3_HEADERS = $(CONTENT_DIR)/include
PPFLAGS=-std=c99 -I$(PKG_DIR) -I$(Z3_HEADERS)  # -include ./headers/ulong.h

HDRS= $(Z3_HEADERS)/z3.h

z3-headers: conan-z3-static
	gcc -E $(PPFLAGS) -D Z3_API="" $(HDRS) > ./z3full.h

wrapper: z3-headers
	convert2stanza.py --input z3full.h func-decl --pkg-prefix z3 --output src/Wrapper.stanza --func-form both
	convert2stanza.py --input z3full.h enums --pkg-prefix z3/Enums --use-defenum --skip memory_order --out-dir src/Enums

clean:
	rm -f ./pkgs/*.pkg
	rm -f ./test-pkgs/*.pkg
	rm ./z3-tests
	rm -rf ./build

.phony: clean