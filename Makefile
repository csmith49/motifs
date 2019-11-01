src=bin
build=_build/default/bin
data=data

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

# pattern for generatic prc stats for disjunctive ensemble
.PRECIOUS: $(data)/results/%-disjunction.csv $(data)/results/%-disjunction-prc.csv
$(data)/results/%-disjunction.csv $(data)/results/%-disjunction-prc.csv: $(data)/gt/%.json $(data)/image/%.json scripts/evaluate_disjunction.py
	@echo "Getting stats for the disjunctive ensemble for experiment $*..."
	@python3 scripts/evaluate_disjunction.py\
		--ground-truth $(data)/gt/$*.json\
		--image $(data)/image/$*.json\
		--threshold-output $(data)/results/$*-disjunction.csv\
		--threshold-steps 100\
		--prc-output $(data)/results/$*-disjunction-prc.csv

# pattern for generating prc stats for confidence-based ensemble
.PRECIOUS: $(data)/results/%-confidence-big-prc.csv $(data)/results/%-confidence-small-prc.csv $(data)/results/%-confidence-scaled-prc.csv
$(data)/results/%-confidence-big-prc.csv $(data)/results/%-confidence-small-prc.csv $(data)/results/%-confidence-scaled-prc.csv: $(data)/gt/%.json $(data)/image/%.json scripts/evaluate_confidence.py
	@echo "Getting stats for the confidence ensemble for experiment $*..."
	@python3 scripts/evaluate_confidence.py\
		--ground-truth $(data)/gt/$*.json\
		--image $(data)/image/$*.json\
		--accuracy big\
		--output $(data)/results/$*-confidence-big-prc.csv
	@python3 scripts/evaluate_confidence.py\
		--ground-truth $(data)/gt/$*.json\
		--image $(data)/image/$*.json\
		--accuracy small\
		--output $(data)/results/$*-confidence-small-prc.csv
	@python3 scripts/evaluate_confidence.py\
		--ground-truth $(data)/gt/$*.json\
		--image $(data)/image/$*.json\
		--accuracy scaled\
		--output $(data)/results/$*-confidence-scaled-prc.csv

# pattern for constructing ground truth of a particular kind
.PRECIOUS: $(data)/gt/%.json
$(data)/gt/%.json: scripts/make_ground_truth.py $(data)/sql/%.sql
	@echo "Constructing ground truth for $*..."
	@python3 scripts/make_ground_truth.py\
		--input-directory $(data)/db\
		--output $@\
		--sql-path $(data)/sql/$*.sql

# pattern for making a problem file from the metadata and ground truth
.PRECIOUS: $(data)/problem/%.json
$(data)/problem/%.json: scripts/make_problem_file.py $(data)/metadata/%.json $(data)/gt/%.json
	@echo "Constructing a problem file for $*..."
	@python3 scripts/make_problem_file.py\
		--ground-truth $(data)/gt/$*.json\
		--output $@\
		--metadata $(data)/metadata/$*.json\
		--number-of-examples 1

# pattern for making an image file from a problem file and the synthesizer
.PRECIOUS: $(data)/image/%.json
$(data)/image/%.json: $(data)/problem/%.json synthesize
	@echo "Constructing image for $*..."
	@./synthesize -p $(data)/problem/$*.json -o $@

# graph construction
.PRECIOUS: $(data)/graphs/%-disjunction-performance.png
$(data)/graphs/%-disjunction-performance.png: $(data)/results/%-disjunction.csv scripts/plot_disjunction_performance.py
	@python3 scripts/plot_disjunction_performance.py\
		--threshold-csv $(data)/results/$*-disjunction.csv\
		--output $@

.PRECIOUS: $(data)/graphs/%-prc.png
$(data)/graphs/%-prc.png: $(data)/results/%-disjunction-prc.csv $(data)/results/%-confidence-big-prc.csv $(data)/results/%-confidence-small-prc.csv $(data)/results/%-confidence-scaled-prc.csv scripts/plot_prc.py
	@python3 scripts/plot_prc.py\
		--prc-csv $(data)/results/$*-disjunction-prc.csv\
			$(data)/results/$*-confidence-big-prc.csv\
			$(data)/results/$*-confidence-small-prc.csv\
			$(data)/results/$*-confidence-scaled-prc.csv\
		--output $@

# various forms of cleaning for experiments
.phony: clean-results
clean-results:
	@echo "Removing results..."
	@rm -rf $(data)/results/*
.phony: clean-graphs
clean-graphs:
	@echo "Removing graphs..."
	@rm -rf $(data)/graphs/*
.phony: clean-data
clean-data:
	@echo "Removing all data..."
	@rm -rf $(data)/gt/*
	@rm -rf $(data)/problem/*
	@rm -rf $(data)/image/*
.phony: clean-experiments
clean-experiments: clean-results clean-graphs

# for cleaning the bulid
.phony: clean-build
clean-build:
	dune clean
	rm -rf _build synthesize
