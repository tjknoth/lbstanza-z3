all: build

tests: z3-tests
	./z3-tests

test-%: z3-tests
	./z3-tests -tagged $(@:test-%=%)

build:
	stanza build

z3-tests: src/*.stanza tests/*.stanza
	stanza build z3-tests

# Conan Library Generator

export CONAN_HOME = $(shell pwd)/.conan2
CONAN_DIR = ./build
BUILD_TYPE = Release
OPTS = -s build_type=$(BUILD_TYPE) --build=missing
Z3_SHARED = -o 'z3/*:shared=True'
SHARED_DIR = $(CONAN_DIR)/shared
Z3_STATIC = -o 'z3/*:shared=False'
STATIC_DIR = $(CONAN_DIR)/static

CONTENT_DIR = $(CONAN_DIR)/content

conan-setup:
	mkdir -p $(CONAN_DIR)
	mkdir -p $(CONTENT_DIR)

conan-z3-shared: conan-setup
	conan install . --deployer=full_deploy $(Z3_SHARED) $(OPTS) --output-folder $(SHARED_DIR)
	find $(SHARED_DIR) | grep -sE "libz3.*\.(so|dll|dylib)" | xargs -I% cp -a % $(CONTENT_DIR)

conan-z3-static: conan-setup
	conan install . --deployer=full_deploy $(Z3_STATIC) $(OPTS) --output-folder $(STATIC_DIR)
	find $(STATIC_DIR) | grep -sE "libz3\.a" | xargs -I% cp % $(CONTENT_DIR)
	find $(STATIC_DIR) -name "z3.h" | xargs -I% dirname %  | xargs | xargs -I% cp -r % $(CONTENT_DIR)

.PHONY: conan-z3-shared conan-setup conan-z3-static

# Wrapper Generator Targets
LIBC_PKG=pycparser_fake_libc
PKG_BASE_DIR = $(shell python -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")
PKG_DIR = $(PKG_BASE_DIR)/$(LIBC_PKG)

Z3_HEADERS = $(CONTENT_DIR)/include
PPFLAGS=-std=c99 -I$(PKG_DIR) -I$(Z3_HEADERS)  # -include ./headers/ulong.h

HDRS= $(Z3_HEADERS)/z3.h

z3-headers: $(CONTENT_DIR)/include/z3.h   # $(HDRS)
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