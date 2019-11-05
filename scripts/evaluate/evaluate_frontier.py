import json, csv
from argparse import ArgumentParser
from analysis import Motif, ensemble_from_string, load_ground_truth, prc

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--image", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--ensemble", default="count")

args = parser.parse_args()

# main
if __name__ == "__main__":
    # load the ground truth
    with open(args.ground_truth, 'r') as f:
        gt, _ = load_ground_truth(json.load(f))

    # load the image
    motifs = []
    with open(args.image, 'r') as f:
        for motif in json.load(f):
            motifs.append(Motif.of_json(motif))

    # compute the ensemble
    ensemble = ensemble_from_string(args.ensemble)(motifs)

    # write out frontier and non-frontier results
    with open(args.output, 'w') as f:
        writer = csv.DictWriter(f, [
            'frontier', 'precision', 'recall', 'ranking', 'gt', 'value'
        ])
        writer.writeheader()

        # evaluate prc for no frontier
        for row in prc(ensemble, gt):
            row['frontier'] = False
            writer.writerow(row)
        
        # and for frontier
        for row in prc(ensemble, gt, frontier=True):
            row['frontier'] = True
            writer.writerow(row)