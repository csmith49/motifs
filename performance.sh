#!/bin/bash
benchmark=$1

for run in {1..3}
do
    for example in {1..3}
    do
        python3 run.py \
            --use-cache \
            --max-al-steps 10 \
            --databases data/db \
            --jsonl \
            --examples $example \
            --benchmark data/benchmark/$benchmark.json \
            --run $run \
            --learning-rate 4 --learning-rate-decay 0.8 \
            --split data/split/$benchmark.json >> results/$benchmark-performance.log &
    done
done
