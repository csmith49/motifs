src=bin
build=_build/default/bin

.phony: all
all: synthesize
synthesize: lib
	dune build $(src)/synthesize.exe
	mv $(build)/synthesize.exe synthesize

scripts:
	mkdir -p scripts

.phony: live
live: lib
	dune utop lib

.phony: clean
clean:
	dune clean
	rm -rf _build synthesize scripts
