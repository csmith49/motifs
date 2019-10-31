import json, csv
from argparse import ArgumentParser
from numpy import linspace

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--image", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--prc-steps", type=int, default=1)

args = parser.parse_args()

# compute precision, recall, and f beta scores
def results(relevant, selected, beta=1):
    relevant, selected = set(relevant), set(selected)
    print(len(relevant), len(selected))

    true_positives = relevant & selected
    false_positives = selected - relevant

    precision = len(true_positives) / (len(true_positives) + len(false_positives))
    recall = len(true_positives) / len(relevant)
    f_beta = (1 + beta ** 2) * (precision * recall) / ((beta ** 2 * precision) + recall)
    return (precision, recall, f_beta)

# flatten program images
def get_selection(program_images):
    result = set()
    for image in program_images:
        result.update(image)
    return result

# main
if __name__ == "__main__":
    # load the ground truth
    with open(args.ground_truth, 'r') as f:
        ground_truth = json.load(f)
    
    # compute ground truth image
    ground_truth_image = []
    for elt in ground_truth:
        ground_truth_image += elt['example']

    # load the image
    with open(args.image, 'r') as f:
        image = json.load(f)

    # compute the number of programs to use at each roc step
    num_programs = len(image)
    steps = [
        int(step) for step in linspace(num_programs, 1, args.prc_steps)
    ]
    steps.reverse()

    # compute image per-program
    program_images = []
    for row in image:
        program_image = set()
        for file_eval in row['images']:
            file_image = set(file_eval['image'])
            program_image.update(file_image)
        program_images.append(program_image)

    # sort based on size
    program_images.sort(key=lambda s: len(s))

    # open the output file
    with open(args.output, 'w') as f:
        writer = csv.DictWriter(f, [
            'ensemble-size', 'precision', 'recall', 'f-beta'
        ])

        writer.writeheader()

        # iterate based on ensemble size
        for ensemble_size in steps:
            ensemble_image = get_selection(program_images[:ensemble_size])
            precision, recall, f_beta = results(ground_truth_image, ensemble_image)
            # construct the output dict
            output = {
                'ensemble-size': ensemble_size,
                'precision': precision,
                'recall': recall,
                'f-beta': f_beta
            }
            writer.writerow(output)