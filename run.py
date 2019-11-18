import sqlite3, os, random, subprocess, time
from json import load, dump
from argparse import ArgumentParser
from csv import DictWriter
from analysis import *

parser = ArgumentParser("Run Script")
parser.add_argument("--data", required=True)
parser.add_argument("--benchmark", required=True)
parser.add_argument("--tmp", default="/tmp")
parser.add_argument("--examples", default=1)
parser.add_argument("--ensemble", default="count")
parser.add_argument("--max-al-steps", default=10, type=int)
parser.add_argument("--num-cores", default=8)
parser.add_argument("--output", default=None)
parser.add_argument("--use-cache", action="store_true")

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
experiment_name = f"{benchmark_name}-{args.ensemble}-{args.examples}"

start_time = time.time()

# SIDE EFFECT 0 - load ground truth from benchmark file (kept in memory only)
print("Constructing ground truth...")
gt_json = benchmark['ground-truth']

# if the gt is provided, use it
if gt_json['kind'] == 'provided':
    ground_truth = gt_json['labels']

# if a sql command is given, build it
elif benchmark['ground-truth']['kind'] == 'sql':
    # get all db filepaths
    db_filepaths = []
    db_root = os.path.join(args.data, gt_json['dataset'])
    for filepath in os.listdir(db_root):
        if filepath.endswith('.db'):
            db_filepaths.append(os.path.join(db_root, filepath))

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

gt_time = time.time()
print("Ground truth done")

# SIDE EFFECT 1 - generate problem file
print("Generating problem file...")

problem_filepath = os.path.join(args.tmp, f"{experiment_name}-problem.json")

if os.path.isfile(problem_filepath) and args.use_cache:
    print("Problem file detected, skipping generation")
else: 
    # construct by pulling relevant info from benchmark file
    metadata = benchmark['metadata']
    files = [ex['file'] for ex in ground_truth]

    # and from sampling examples as required
    examples = random.sample(
        population=list(filter(lambda ex: ex['example'] != [], ground_truth)),
        k=args.examples
    )

    # write the file out
    problem_json = {'metadata' : metadata, 'files' : files, 'examples' : examples}
    with open(problem_filepath, 'w') as f:
        dump(problem_json, f)

problem_time = time.time()
print("Problem file done")

# SIDE EFFECT 2 - synthesize motifs
print("Starting synthesis...")
motifs_filepath = os.path.join(args.tmp, f"{experiment_name}-motifs.json")
synthesis_args = [
    "./synthesize",
    "--problem", problem_filepath,
    "--output", motifs_filepath,
    "--num-cores", str(args.num_cores)
]

if os.path.isfile(motifs_filepath) and args.use_cache:
    print("Motifs file detected, skipping synthesis.")
else:
    subprocess.run(synthesis_args,
        universal_newlines=True,
        stdout=subprocess.PIPE
    )

synth_time = time.time()
print("Synthesis done ")

# SIDE EFFECT 3 - generate image
print("Starting evaluation...")

image_filepath = os.path.join(args.tmp, f"{experiment_name}-image.json")
eval_args = [
    "./evaluate",
    "--problem", problem_filepath,
    "--motifs", motifs_filepath,
    "--output", image_filepath,
    "--num-cores", str(args.num_cores)
]

if os.path.isfile(image_filepath) and args.use_cache:
    print("Image file detected, skipping evaluation.")
else:
    subprocess.run(eval_args,
        universal_newlines=True,
        stdout=subprocess.PIPE
    )

eval_time = time.time()
print("Evaluation done")

# PRIMARY GOAL
print("Starting analysis...")

# construct the ensemble
motifs = load_motifs(image_filepath) # the analysis motifs are stored with their evaluation
al = Active(ensemble_from_string(args.ensemble)(motifs))

# we have to extract just the ground truth values - the targets for the motifs
target = set()
for ex in ground_truth:
    target.update(ex['example'])

# we're outputting csv rows, but if there's no output we'll just print as we go
stat_time = time.time()
rows = []
for step in range(args.max_al_steps + 1):
    # compute stats
    precision, recall, f1 = performance_statistics(al.ensemble.classified(), target)
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
        "ensemble-size" : len(al.ensemble.motifs)
    }
    # record them
    rows.append(row)
    print(row)
    
    # try to split if we can
    split = al.candidate_split()
    if split is None: break
    al = al.split_on(split, split in target)
    stat_time = time.time()

# if we should write somewhere, do it - if the file exists, don't write the header
if args.output is not None:
    already_exists = os.path.isfile(args.output)
    with open(args.output, 'a') as f:
        writer = DictWriter(fieldnames=[
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
            "ensemble-size"
        ])

        if not already_exists:
            writer.writeheader()
        
        for row in rows:
            writer.writerow(row)