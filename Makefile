ocb_flags = -r -use-ocamlfind -pkgs 'yojson, containers, containers.data, sqlite3'
ocb = ocamlbuild $(ocb_flags)

.phony: all
all: gr

gr: $(shell find src -type f)
	$(ocb) gr.native
	mv gr.native gr

scripts:
	mkdir -p scripts

scripts/dot_of_example: $(shell find src -type f) scripts
	$(ocb) dot_of_example.native
	mv dot_of_example.native scripts/dot_of_example

.phony: clean
clean:
	rm -rf _build gr
