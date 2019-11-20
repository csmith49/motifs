#!/usr/local/bin/python3

import sqlite3, os, random, subprocess, time
from json import load, dump, dumps
from argparse import ArgumentParser
from csv import DictWriter
from analysis import *

parser = ArgumentParser("Run Script")
parser.add_argument("--data", required=True)
parser.add_argument("--benchmark", required=True)
parser.add_argument("--tmp", default="/tmp")
parser.add_argument("--examples", default=1, type=int)
parser.add_argument("--ensemble", default="disjunction")
parser.add_argument("--max-al-steps", default=10, type=int)
parser.add_argument("--num-cores", default=8)
parser.add_argument("--output", default=None)
parser.add_argument("--split", default=None)
parser.add_argument("--use-cache", action="store_true")
parser.add_argument("--jsonl", action="store_true")
parser.add_argument("--learning-rate", type=float, default=0.1)

args = parser.parse_args()

# GOALS - produce performance statistics for given ensemble / num examples across al steps

# SIDE EFFECTS - produce the necesary intermediate products to evaluate hera, including:
# 1. a problem file (necessary for synthesize)
# 2. a set of synthesized motifs (necessary for producing the image)
# 3. an image (to evaluate)

# many of these side effects require writing files out - we use tmp as scratch space

# LOAD THE INPUT
with open(args.benchmark, 'r') as f:
    benchmark = load(f)

benchmark_name = os.path.splitext(os.path.basename(args.benchmark))[0]
experiment_name = f"{benchmark_name}-{args.examples}"

start_time = time.time()

# SIDE EFFECT 0 - load ground truth from benchmark file (kept in memory only)
print("GROUND TRUTH")
gt_json = benchmark['ground-truth']

# if the gt is provided, use it
if gt_json['kind'] == 'provided':
    print(f"Ground truth is provided in {benchmark_name}.")
    ground_truth = gt_json['labels']

# if a sql command is given, build it
elif benchmark['ground-truth']['kind'] == 'sql':
    print("Ground truth is being constructed from SQL queries.")
    # get all db filepaths
    db_filepaths = []
    db_root = os.path.join(args.data, gt_json['dataset'])
    for filepath in os.listdir(db_root):
        if filepath.endswith('.db'):
            db_filepaths.append(os.path.join(db_root, filepath))
    
    print(f"Evaluating {len(db_filepaths)} databases...")

    # construct json output
    ground_truth = []
    sql_cmd = gt_json['sql']

    # apply sql to all dbs found
    for db_filepath in db_filepaths:
        conn = sqlite3.connect(db_filepath)
        cursor = conn.cursor()
        cursor.execute(sql_cmd)
        image = []
        for row in cursor.fetchall():
            image.append( row[0] )
        ground_truth.append(
            {'file': db_filepath, 'example': image}
        )

# once we have ground truth, have to split into train and test
if args.split is not None:
    print("Data split file detected, splitting into train/test...")
    with open(args.split, "r") as f:
        splits = load(f)

    # checking is a bit weird - for each example, see if the basename agrees with something in splits
    train, test = [], []
    for ex in ground_truth:
        if os.path.basename(ex['file']) in splits['train']:
            train.append(ex)
        elif os.path.basename(ex['file']) in splits['test']:
            test.append(ex)

# just use everything if no split provided
else:
    train, test = ground_truth, ground_truth

print(f"Train/test split of {len(train)}/{len(test)}...")

gt_time = time.time()
print("GROUND TRUTH DONE\n")

# SIDE EFFECT 1 - generate problem file
print("PROBLEM FILE")

problem_filepath = os.path.join(args.tmp, f"{experiment_name}-problem.json")

if os.path.isfile(problem_filepath) and args.use_cache:
    print("Problem file detected, skipping generation...")
else: 
    # construct by pulling relevant info from benchmark file
    metadata = benchmark['metadata']
    files = [ex['file'] for ex in test]

    print(f"Sampling {args.examples} instances for ground truth...")

    # and from sampling examples as required
    sampled_docs = random.sample(
        population=set([ex['file'] for ex in train]),
        k=args.examples
    )
    examples = []
    for ex in train:
        if ex['file'] in sampled_docs:
            examples.append(ex)

    print("Writing to file...")
    # write the file out
    problem_json = {'metadata' : metadata, 'files' : files, 'examples' : examples}
    with open(problem_filepath, 'w') as f:
        dump(problem_json, f)

problem_time = time.time()
print("PROBLEM FILE DONE\n")

# SIDE EFFECT 2 - synthesize motifs
print("SYNTHESIS")

motifs_filepath = os.path.join(args.tmp, f"{experiment_name}-motifs.json")
synthesis_args = [
    "./synthesize",
    "--problem", problem_filepath,
    "--output", motifs_filepath,
    "--num-cores", str(args.num_cores)
]

if os.path.isfile(motifs_filepath) and args.use_cache:
    print("Motifs file detected, skipping synthesis...")
else:
    print("Spinning up Hera for synthesis...")
    subprocess.run(synthesis_args,
        universal_newlines=True,
        stdout=subprocess.PIPE
    )

synth_time = time.time()
print("SYNTHESIS DONE\n")

# SIDE EFFECT 3 - generate image
print("EVALUATION")

image_filepath = os.path.join(args.tmp, f"{experiment_name}-image.json")
eval_args = [
    "./evaluate",
    "--problem", problem_filepath,
    "--motifs", motifs_filepath,
    "--output", image_filepath,
    "--num-cores", str(args.num_cores)
]

if os.path.isfile(image_filepath) and args.use_cache:
    print("Image file detected, skipping evaluation...")
else:
    print("Spinning up Hera for evaluation...")
    subprocess.run(eval_args,
        universal_newlines=True,
        stdout=subprocess.PIPE
    )

eval_time = time.time()
print("EVALUATION DONE\n")

# PRIMARY GOAL
print("ANALYSIS")

print(f"Constructing {args.ensemble} ensemble...")
# construct the ensemble
motifs = load_motifs(image_filepath) # the analysis motifs are stored with their evaluation
ensemble = ensemble_from_string(args.ensemble)(motifs)

ensemble_time = time.time()

# we have to extract just the ground truth values - the targets for the motifs
print("Extracting target vertices...")
learnable, target = set(), set()
for ex in train:
    learnable.update(ex['example'])
for ex in test:
    target.update(ex['example'])

# we're outputting csv rows, but if there's no output we'll just print as we go
stat_time = time.time()
rows = []
print("Starting evaluation...")
al_steps = args.max_al_steps if isinstance(ensemble, WeightedVote) else 0
for step in range(al_steps + 1):
    # compute stats
    print("Computing current image...")
    image = ensemble.classified()
    print(f"Computing statistics for step {step}...")
    precision, recall, f1 = performance_statistics(image, target)
    row = {
        "benchmark" : benchmark_name,
        "ensemble" : args.ensemble,
        "al-step" : step,
        "examples" : args.examples,
        "precision" : precision,
        "recall" : recall,
        "f1" : f1,
        "synth-time" : synth_time - problem_time,
        "eval-time" : eval_time - synth_time,
        "al-time" : time.time() - stat_time,
        "ensemble-time" : ensemble_time - eval_time
    }

    # record them
    rows.append(row)
    print("P/R: {precision:.4f}/{recall:.4f}".format(**row))
    if args.jsonl: print(dumps(row))
    
    # check if we've achieved maximum performance
    if f1 == 1.0:
        print("Optimal performance achieved, stopping...")
        break

    # try to split if we can
    print("Checking for a candidate split...")
    split = ensemble.max_entropy(learnable)
    if split is None:
        print("No valid split found...")
        break
    print(f"Splitting on node {split}...")
    if isinstance(ensemble, WeightedVote):
        ensemble.update(split, split in target, learning_rate=args.learning_rate)
    else:
        ensemble.update(split, split in target)
    stat_time = time.time()

print("EVALUATION DONE")

# if we should write somewhere, do it - if the file exists, don't write the header
if args.output is not None:
    print(f"Writing output to {args.output}...")
    already_exists = os.path.isfile(args.output)
    with open(args.output, 'a') as f:
        writer = DictWriter(f, fieldnames=[
            "benchmark",
            "ensemble",
            "al-step",
            "examples",
            "precision",
            "recall",
            "f1",
            "synth-time",
            "eval-time",
            "al-time",
            "ensemble-time"
        ])

        if not already_exists:
            writer.writeheader()
        
        for row in rows:
            writer.writerow(row)
    print("Done.")