import json, csv
from argparse import ArgumentParser
from functools import reduce

from analysis import Active, Motif, load_ground_truth, performance_statistics, prc, load_motifs
from analysis import ensemble_from_string

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--image", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--ensemble", default="disjunction")
parser.add_argument("--learning-steps", type=int, default=1)

args = parser.parse_args()

# main
if __name__ == "__main__":
    # load the ground truth
    with open(args.ground_truth, 'r') as f:
        gt, _ = load_ground_truth(json.load(f))

    # load the image
    motifs = load_motifs(args.image)

    # make the ensemble
    ensemble = ensemble_from_string(args.ensemble)(motifs)

    # for some statistics
    number_of_motifs = len(motifs)
    
    # open the output file and fake active learning here
    with open(args.output, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'learning-step', 'ensemble-ratio', 'precision', 'recall', 'ranking', 'gt', 'value'
        ])
        writer.writeheader()

        # make the active loop
        active = Active(ensemble)

        # for each step of the learning...
        for step in range(args.learning_steps):
            results = prc(active.ensemble, gt, frontier=True)
            for row in results:
                row['learning-step'] = step
                row['ensemble-ratio'] = active.ensemble.size / number_of_motifs
                writer.writerow(row)

            # update the motifs by faking a learning loop
            split = active.candidate_split(frontier=True)
            if split is None: break
            active = active.split_on(split, split in gt)