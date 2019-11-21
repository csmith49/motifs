# BUILD VARIABLES =======================
build=_build/default/bin

# DATA LOCATIONS ========================
data=data
results=results

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

# directories
$(data):
	mkdir -p $@
$(results):
	mkdir -p $@

# general performance
.PRECIOUS: $(results)/%-performance.log
$(results)/%-performance.log: $(results) $(data)/benchmark/%.json $(data)/split/%.json
	@./performance.sh $*

$(results)/%.csv: $(results) $(results)/%.log
	@python3 scripts/jsonl_to_csv.py --output $@ --inputs $(results)/$*.log

# noise performance
.PRECIOUS: $(results)/noise-%-performance.log
$(results)/noise-%-performance.log: $(results)/noise-%-2-performance.log $(results)/noise-%-4-performance.log $(results)/noise-%-10-performance.log $(results)/noise-%-20-performance.log
	@cat $(results)/noise-$*-2-performance.log >> $@
	@cat $(results)/noise-$*-4-performance.log >> $@
	@cat $(results)/noise-$*-10-performance.log >> $@
	@cat $(results)/noise-$*-20-performance.log >> $@

# for cleaning the bulid
.phony: clean
clean-build:
	dune clean
	rm -rf _build synthesize evaluate
