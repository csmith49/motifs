# BUILD VARIABLES =======================
build=_build/default/bin

# DATA LOCATIONS ========================
data=data

# BENCHMARKS
benchmarks=cdr-chemical cdr-disease hardware-cell hardware-text politician wiki-cell wiki-text

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
$(data)/results: $(data)
	mkdir -p $@

$(data)/results/%-performance.log: $(data)/results $(data)/benchmark/%.json $(data)/split/%.json
	@performance.sh $*

$(dat)/results/performance.csv: $(foreach bm, $(bencmharks), $(data)/results/$(bm)-performance.log)
	@python3 scripts/jsonl_to_csv.py --output $@ --inputs $^

# for cleaning the bulid
.phony: clean
clean-build:
	dune clean
	rm -rf _build synthesize evaluate
