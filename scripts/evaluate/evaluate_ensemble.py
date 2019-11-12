import json, csv, pprint
from argparse import ArgumentParser
from analysis import Motif, ensemble_from_string, load_ground_truth, performance_statistics, load_motifs

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--image", required=True)
# parser.add_argument("--output", required=True)
parser.add_argument("--ensemble", default="count")

args = parser.parse_args()

# main
if __name__ == "__main__":
    # load the ground truth
    with open(args.ground_truth, 'r') as f:
        gt, _ = load_ground_truth(json.load(f))

    motifs = load_motifs(args.image)

    ensemble = ensemble_from_string(args.ensemble)(motifs)

    precision, recall, f1 = performance_statistics(ensemble.domain(), gt, beta=1)


    pprint.pprint({
        'precision': precision,
        'recall': recall,
        'f1': f1
    })