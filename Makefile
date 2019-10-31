src=bin
build=_build/default/bin
data=data

# entrypoint just uses dune to build the synthesis tool
.phony: all
all: synthesize $(data)/results/disjunction/pob-cell.csv
synthesize: lib
	dune build $(src)/synthesize.exe
	mv $(build)/synthesize.exe synthesize

# takes us into an interactive prompt with
.phony: live
live: lib
	dune utop lib

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

# pattern for generatic prc stats for disjunctive ensemble
.PRECIOUS: $(data)/results/disjunction/%.csv
$(data)/results/disjunction/%.csv: $(data)/gt/%.json $(data)/image/$.json scripts/evaluate_disjunction.py
	@echo "Getting stats for the disjunctive ensemble for experiment $*..."
	@python3 scripts/evaluate_disjunction.py\
		--ground-truth $(data)/gt/$*.json\
		--image $(data)/image/$*.json\
		--output $@\
		--prc-steps 100

# various forms of cleaning
.phony: clean-experiments
clean-experiments:
	rm -rf $(data)/gt/*
	rm -rf $(data)/problem/*
	rm -rf $(data)/image/*

.phony: clean
clean:
	dune clean
	rm -rf _build synthesize
