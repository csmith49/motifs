import json, random
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--experiment", required=True)

args = parser.parse_args()

# main
if __name__ == "__main__":
    # load up the ground truth
    with open(args.ground_truth, 'r') as f:
        ground_truth = json.load(f)

    # load the experiment
    with open(args.experiment, 'r') as f:
        experiment = json.load(f)

    # get the files
    files = [elt['file'] for elt in ground_truth]

    # number of examples
    if "number-of-examples" in experiment.keys():
        number_of_examples = experiment["number-of-examples"]
    else:
        number_of_examples = 1

    # sample the examples
    examples = random.sample(
        population=list(
            filter(lambda elt: elt['example'] != [], ground_truth)
        ),
        k=number_of_examples
    )

    # construct the output
    output = {
        'metadata' : experiment["metadata"],
        'files' : files,
        'examples' : examples
    }

    # write the output
    with open(args.output, 'w') as f:
        json.dump(output, f)