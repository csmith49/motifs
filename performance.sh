#!/bin/bash

ensembles='disjunction majority-vote weighted-vote'
examples={1..5}

benchmark=$1

for ensemble in $ensembles
do
    for examples in $examples
    do
        python3 run.py --use-cache --max-al-steps 10 --data data/db --jsonl \
            --benchmark data/benchmark/$benchmark.json --ensemble $ensemble \
            --split data/split/$benchmark.json >> $1-performance.log
    done
done