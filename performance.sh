#!/bin/bash

ensembles='disjunction majority-vote weighted-vote'
benchmark=$1

for ensemble in $ensembles
do
    for examples in {1..5}
    do
        python3 run.py --use-cache --max-al-steps 10 --data data/db --jsonl \
            --benchmark data/benchmark/$benchmark.json --ensemble $ensemble \
            --split data/split/$benchmark.json >> data/results/$1-performance.log
    done
done