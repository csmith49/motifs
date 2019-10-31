import json, random
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--metadata", required=True)
parser.add_argument("--number-of-examples", type=int, default=1)

args = parser.parse_args()

# main
if __name__ == "__main__":
    # load up the ground truth
    with open(args.ground_truth, 'r') as f:
        ground_truth = json.load(f)

    # load the metadata
    with open(args.metadata, 'r') as f:
        metadata = json.load(f)

    # get the files
    files = [elt['file'] for elt in ground_truth]

    # sample the examples
    examples = random.sample(
        population=list(
            filter(lambda elt: elt['example'] != [], ground_truth)
        ),
        k=args.number_of_examples
    )

    # construct the output
    output = {
        'metadata' : metadata, 
        'files' : files,
        'examples' : examples
    }

    # write the output
    with open(args.output, 'w') as f:
        json.dump(output, f)