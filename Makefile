# build locations
src=bin
build=_build/default/bin

# data locations
data=data
gt=$(data)/gt
image=$(data)/image
results=$(data)/results
graphs=$(data)/graphs
problem=$(data)/problem

# entrypoint just uses dune to build the synthesis tool
.phony: all
all: synthesize
synthesize: lib
	dune build $(src)/synthesize.exe
	mv $(build)/synthesize.exe synthesize

# takes us into an interactive prompt with
.phony: live
live: lib
	dune utop lib

# the desired graphs to build (for now)
.phony: graphs
graphs: $(graphs)/pob-cell-active.png $(graphs)/pob-cell-disjunction-performance.png $(graphs)/pob-cell-prc.png

# pattern for generating prc stats for disjunctive ensemble
.PRECIOUS: $(results)/%-disjunction.csv $(results)/%-disjunction-prc.csv
$(results)/%-disjunction.csv $(results)/%-disjunction-prc.csv: $(gt)/%.json $(image)/%.json scripts/evaluate_disjunction.py
	@echo "Getting stats for the disjunctive ensemble for experiment $*..."
	@python3 scripts/evaluate_disjunction.py\
		--ground-truth $(gt)/$*.json\
		--image $(image)/$*.json\
		--threshold-output $(results)/$*-disjunction.csv\
		--threshold-steps 100\
		--prc-output $(results)/$*-disjunction-prc.csv

# pattern for generating performance curves for faked active learning
.PRECIOUS: $(results)/%-active.csv
$(results)/%-active.csv: $(gt)/%.json $(image)/%.json scripts/evaluate_active.py
	@echo "Getting stats for the active ensemble for experiment $*..."
	@python3 scripts/evaluate_active.py\
		--ground-truth $(gt)/$*.json\
		--image $(image)/$*.json\
		--output $@\
		--learning-steps 10

# pattern for generating prc stats for confidence-based ensemble
.PRECIOUS: $(results)/%-confidence-big-prc.csv $(results)/%-confidence-small-prc.csv $(results)/%-confidence-scaled-prc.csv
$(results)/%-confidence-big-prc.csv $(results)/%-confidence-small-prc.csv $(results)/%-confidence-scaled-prc.csv: $(gt)/%.json $(image)/%.json scripts/evaluate_confidence.py
	@echo "Getting stats for the confidence ensemble for experiment $*..."
	@python3 scripts/evaluate_confidence.py\
		--ground-truth $(gt)/$*.json\
		--image $(image)/$*.json\
		--accuracy big\
		--output $(results)/$*-confidence-big-prc.csv
	@python3 scripts/evaluate_confidence.py\
		--ground-truth $(gt)/$*.json\
		--image $(image)/$*.json\
		--accuracy small\
		--output $(results)/$*-confidence-small-prc.csv
	@python3 scripts/evaluate_confidence.py\
		--ground-truth $(gt)/$*.json\
		--image $(image)/$*.json\
		--accuracy scaled\
		--output $(results)/$*-confidence-scaled-prc.csv

# pattern for constructing ground truth of a particular kind
.PRECIOUS: $(gt)/%.json
$(gt)/%.json: scripts/make_ground_truth.py $(data)/sql/%.sql
	@echo "Constructing ground truth for $*..."
	@python3 scripts/make_ground_truth.py\
		--input-directory $(data)/db\
		--output $@\
		--sql-path $(data)/sql/$*.sql

# pattern for making a problem file from the metadata and ground truth
.PRECIOUS: $(problem)/%.json
$(problem)/%.json: scripts/make_problem_file.py $(data)/metadata/%.json $(gt)/%.json
	@echo "Constructing a problem file for $*..."
	@python3 scripts/make_problem_file.py\
		--ground-truth $(gt)/$*.json\
		--output $@\
		--metadata $(data)/metadata/$*.json\
		--number-of-examples 1

# pattern for making an image file from a problem file and the synthesizer
.PRECIOUS: $(image)/%.json
$(image)/%.json: $(data)/problem/%.json synthesize
	@echo "Constructing image for $*..."
	@./synthesize -p $(problem)/$*.json -o $@

# graph construction
.PRECIOUS: $(graphs)/%-disjunction-performance.png
$(graphs)/%-disjunction-performance.png: $(results)/%-disjunction.csv scripts/plot_disjunction_performance.py
	@python3 scripts/plot_disjunction_performance.py\
		--threshold-csv $(results)/$*-disjunction.csv\
		--output $@

.PRECIOUS: $(graphs)/%-prc.png
$(graphs)/%-prc.png: $(results)/%-disjunction-prc.csv $(results)/%-confidence-big-prc.csv $(results)/%-confidence-small-prc.csv $(results)/%-confidence-scaled-prc.csv scripts/plot_prc.py
	@python3 scripts/plot_prc.py\
		--prc-csv $(results)/$*-disjunction-prc.csv\
			$(results)/$*-confidence-big-prc.csv\
			$(results)/$*-confidence-small-prc.csv\
			$(results)/$*-confidence-scaled-prc.csv\
		--output $@

.PRECIOUS: $(graphs)/%-active.png
$(graphs)/%-active.png: $(results)/%-active.csv scripts/plot_active_performance.py
	@python3 scripts/plot_active_performance.py\
		--active-csv $(results)/$*-active.csv\
		--output $@

# various forms of cleaning for experiments
.phony: clean-results
clean-results:
	@echo "Removing results..."
	@rm -rf $(results)/*
.phony: clean-graphs
clean-graphs:
	@echo "Removing graphs..."
	@rm -rf $(graphs)/*
.phony: clean-data
clean-data:
	@echo "Removing all data..."
	@rm -rf $(gt)/*
	@rm -rf $(problem)/*
	@rm -rf $(image)/*
.phony: clean-experiments
clean-experiments: clean-results clean-graphs

# for cleaning the bulid
.phony: clean-build
clean-build:
	dune clean
	rm -rf _build synthesize
