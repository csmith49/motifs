# BUILD VARIABLES =======================

# build locations
build=_build/default/bin

# DATA LOCATIONS ========================

# data locations
data=data
gt=$(data)/gt
image=$(data)/image
results=$(data)/results
graphs=$(data)/graphs
problem=$(data)/problem
motifs=$(data)/motifs
experiment=$(data)/experiment

# script locations
eval=scripts/evaluate
mk=scripts/make
plt=scripts/plot

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
performance.csv: scripts/jsonl_to_csv.py run.py performance.sh synthesize evaluate
	@performance.sh

# for cleaning the bulid
.phony: clean
clean-build:
	dune clean
	rm -rf _build synthesize evaluate
