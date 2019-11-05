# BUILD VARIABLES =======================

# build locations
src=bin
build=_build/default/bin

# DATA LOCATIONS ========================

# data locations
data=data
gt=$(data)/gt
dgt=$(data)/default-gt
image=$(data)/image
results=$(data)/results
graphs=$(data)/graphs
problem=$(data)/problem

# script locations
eval=scripts/evaluate
mk=scripts/make
plt=scripts/plot

# BUILDING THE TOOL =====================

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

# MAKING NECESSARY EXPERIMENT DATA ======

# constructing ground truth of a particular kind
.PRECIOUS: $(gt)/%.json
$(gt)/%.json: $(mk)/make_ground_truth.py $(data)/sql/%.sql
	@echo "Constructing ground truth for $*..."
	@python3 $(mk)/make_ground_truth.py\
		--input-directory $(data)/db\
		--output $@\
		--sql-path $(data)/sql/$*.sql
$(gt)/%.json: $(dgt)/%.json
	cp $(dgt)/$*.json $@

# making a problem file from the metadata and ground truth
.PRECIOUS: $(problem)/%.json
$(problem)/%.json: $(mk)/make_problem_file.py $(data)/metadata/%.json $(gt)/%.json
	@echo "Constructing a problem file for $*..."
	@python3 $(mk)/make_problem_file.py\
		--ground-truth $(gt)/$*.json\
		--output $@\
		--metadata $(data)/metadata/$*.json\
		--number-of-examples 1

# making an image file from a problem file and the synthesizer
.PRECIOUS: $(image)/%.json
$(image)/%.json: $(data)/problem/%.json synthesize
	@echo "Constructing image for $*..."
	@./synthesize -p $(problem)/$*.json -o $@

# EXPERIMENTS ===================

# EXPERIMENT VARIABLES ==================
tasks=pob-cell wiki-table
experiments=$(foreach task,$(tasks),$(graphs)/$(task)-disjunction-active.png $(graphs)/$(task)-count-active-prc.png $(graphs)/$(task)-frontier.png $(graphs)/$(task)-active-frontier-prc.png)

.PHONY: experiments
experiments: $(experiments)

# Experiment 1 - how does active learning improve disjunction?

# active-learning data for disjunction
.PRECIOUS: $(results)/%-disjunction-active.csv
$(results)/%-disjunction-active.csv: $(gt)/%.json $(image)/%.json $(eval)/evaluate_active.py
	@python3 $(eval)/evaluate_active.py\
		--image $(image)/$*.json\
		--ground-truth $(gt)/$*.json\
		--output $@\
		--learning-steps 7\
		--ensemble disjunction

# learning graph for disjunction
$(graphs)/%-disjunction-active.png: $(results)/%-disjunction-active.csv $(plt)/plot_active_performance.py
	@python3 $(plt)/plot_active_performance.py\
		--csv $(results)/$*-disjunction-active.csv\
		--output $@

# Experiment 2 - what does active learning do to ranking ensembles?

# prc for active learning for count
.PRECIOUS: $(results)/%-count-active-prc.csv
$(results)/%-count-active-prc.csv: $(gt)/%.json $(image)/%.json $(eval)/evaluate_active_prc.py
	@python3 $(eval)/evaluate_active_prc.py\
		--image $(image)/$*.json\
		--ground-truth $(gt)/$*.json\
		--output $@\
		--learning-steps 7\
		--ensemble count

# plotting prc for active learning over disjunction
$(graphs)/%-count-active-prc.png: $(results)/%-count-active-prc.csv $(plt)/plot_active_prc.py
	@python3 $(plt)/plot_active_prc.py\
		--csv $(results)/$*-count-active-prc.csv\
		--output $@

# Experiment 3 - what if we only count the frontier in a ranking ensemble?
.PRECIOUS: $(results)/%-frontier.csv
$(results)/%-frontier.csv: $(gt)/%.json $(image)/%.json $(eval)/evaluate_frontier.py
	@python3 $(eval)/evaluate_frontier.py\
		--image $(image)/$*.json\
		--ground-truth $(gt)/$*.json\
		--output $@\
		--ensemble count

$(graphs)/%-frontier.png: $(results)/%-frontier.csv $(plt)/plot_frontier.py
	@python3 $(plt)/plot_frontier.py\
		--csv $(results)/$*-frontier.csv\
		--output $@

# Experiment 4 - does the frontier help us with active learning?
.PRECIOUS: $(results)/%-active-frontier-prc.csv
$(results)/%-active-frontier-prc.csv: $(gt)/%.json $(image)/%.json $(eval)/evaluate_active_frontier_prc.py
	@python3 $(eval)/evaluate_active_frontier_prc.py\
		--image $(image)/$*.json\
		--ground-truth $(gt)/$*.json\
		--output $@\
		--learning-steps 7\
		--ensemble count

$(graphs)/%-active-frontier-prc.png: $(results)/%-active-frontier-prc.csv $(plt)/plot_active_frontier_prc.py
	@python3 $(plt)/plot_active_frontier_prc.py\
		--csv $(results)/$*-active-frontier-prc.csv\
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
