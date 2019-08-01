src=bin
build=_build/default/bin

.phony: all
all: gr scripts/dot_of_example scripts/clevr

gr: lib
	dune build $(src)/gr.exe
	mv $(build)/gr.exe gr

scripts:
	mkdir -p scripts

scripts/dot_of_example: lib scripts
	dune build $(src)/dot_of_example.exe
	mv $(build)/dot_of_example.exe scripts/dot_of_example

scripts/clevr: lib scripts
	dune build $(src)/clevr.exe
	mv $(build)/clevr.exe scripts/clevr

.phony: live
live: lib
	dune utop lib

.phony: clean
clean:
	dune clean
	rm -rf _build gr scripts
