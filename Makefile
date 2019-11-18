# BUILD VARIABLES =======================
build=_build/default/bin

# DATA LOCATIONS ========================
data=data

# BUILDING THE TOOL =====================

# entrypoint just uses dune to build the synth/eval tools
.phony: all
all: synthesize evaluate
synthesize: lib bin/synthesize.ml
	dune build bin/synthesize.exe
	mv $(build)/synthesize.exe synthesize
evaluate: lib bin/evaluate.ml
	dune build bin/evaluate.exe
	mv $(build)/evaluate.exe evaluate

# takes us into an interactive prompt with
.phony: live
live: lib
	dune utop lib

# experiments
performance.csv: $(data) scripts/jsonl_to_csv.py run.py performance.sh synthesize evaluate
	@performance.sh

# directories
$(data):
	mkdir -p $@

# for cleaning the bulid
.phony: clean
clean-build:
	dune clean
	rm -rf _build synthesize evaluate
