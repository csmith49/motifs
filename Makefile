ocb_flags = -r -use-ocamlfind -pkgs 'yojson, containers, containers.data, ocamlgraph, sqlite3'
ocb = ocamlbuild $(ocb_flags)

.phony: all
all: gr

gr: $(shell find src -type f)
	$(ocb) gr.native
	mv gr.native gr

.phony: clean
clean:
	rm -rf _build gr
