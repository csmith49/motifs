#!/bin/bash

ensembles='disjunction majority-vote most-specific'
benchmarks='pob-cell'
examples={1..2}

touch performance.log

for benchmark in $benchmarks
do
    for ensemble in $ensembles
    do
        for examples in $examples
        do
            python3 run.py --use-cache --max-al-steps 10 --data data/db --tron \
                --benchmark data/experiment/$benchmark.json --ensemble $ensemble \
            >> performance.log
        done
    done
done

python3 scripts/tron/jsonl_to_csv.py --input performance.log --output performance.csv