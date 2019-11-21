graphs:
	mkdir -p graphs

graphs/%-majority-vote-threshold.png: graphs interpretation/majority-vote-threshold.py csvs/%-performance.csv
	@python3 interpretation/majority-vote-threshold.py --benchmark $*

graphs/%-weighted-vote-convergence.png: graphs interpretation/weighted-vote-convergence.py csvs/%-performance.csv
	@python3 interpretation/weighted-vote-convergence.py --benchmark $*

.PRECIOUS: csvs/%-performance.csv
csvs/%-performance.csv: logs/%-performance.log
	@python3 ../scripts/jsonl_to_csv.py --inputs logs/$*-performance.log --output $@