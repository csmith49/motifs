#!/bin/bash

ensembles='disjunction majority-vote weighted-vote'
benchmark=$1

for ensemble in $ensembles
do
    for run in {1..5}
    do  
        for example in {1..3}
        do
            python3 run.py --use-cache --max-al-steps 10 --databases data/db --jsonl \
                --benchmark data/benchmark/$benchmark.json --ensemble $ensemble \
                --split data/split/$benchmark.json >> results/$benchmark-performance.log
        done
    done
done
