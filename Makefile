all: build

tests: z3-tests
	./z3-tests

test-%: z3-tests
	./z3-tests -tagged $(@:test-%=%)

build:
	stanza build

z3-tests: src/*.stanza tests/*.stanza
	stanza build z3-tests

PYPARSE_HEADERS=/mnt/c/Users/callendorph/Documents/AFT/Jitx/lbstanza-wrappers/venv/lib/python3.5/site-packages/pycparser_fake_libc
Z3_HEADERS=./archive/z3-4.11.2-x64-win/z3-4.11.2-x64-win/include
PPFLAGS=-std=c99 -I$(PYPARSE_HEADERS) -I$(Z3_HEADERS)  # -include ./headers/ulong.h

HDRS= $(Z3_HEADERS)/z3.h

z3-headers:   # $(HDRS)
	gcc -E $(PPFLAGS) -D Z3_API="" $(HDRS) > ./z3full.h

wrapper: z3-headers
	python convert.py --input z3full.h func-decl --pkg-prefix z3 --output src/Wrapper.stanza --func-form both
	python convert.py --input z3full.h enums --pkg-prefix z3/Enums --use-defenum --skip memory_order --out-dir src/Enums

clean:
	rm -f ./pkgs/*.pkg
	rm -f ./test-pkgs/*.pkg
	rm ./z3-tests

.phony: clean