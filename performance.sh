#!/bin/bash

ensembles='majority-vote most-specific'
benchmarks='politician wiki-cell hardware-cell'
examples={1..1}

touch performance.log

for benchmark in $benchmarks
do
    for ensemble in $ensembles
    do
        for examples in $examples
        do
            python3 run.py --use-cache --max-al-steps 10 --data data/db --jsonl \
                --benchmark data/benchmark/$benchmark.json --ensemble $ensemble \
                --split data/split/$benchmark.json \
            >> performance.log
        done
    done
done

python3 scripts/jsonl_to_csv.py --input performance.log --output performance.csv