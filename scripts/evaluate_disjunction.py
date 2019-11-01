import json, csv
from argparse import ArgumentParser
from numpy import linspace

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--image", required=True)
parser.add_argument("--threshold-output", required=True)
parser.add_argument("--threshold-steps", type=int, default=1)
parser.add_argument("--prc-output", default=None)

args = parser.parse_args()

# compute precision, recall, and f beta scores
def results(relevant, selected, beta=1):
    relevant, selected = set(relevant), set(selected)

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

def images_containing(value, program_images):
    count = 0
    for img in program_images:
        if value in img:
            count += 1
    return count

# threshold evaluation
def threshold_evaluation(program_images, ground_truth, steps, output):
    # compute threshold program counts
    thresholds = [int(f) for f in linspace(len(program_images), 1, steps)]
    thresholds.reverse()

    # open the output file
    with open(output, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'ensemble-ratio', 'precision', 'recall', 'f-beta', 'beta'
        ])
        writer.writeheader()

        # for each threshold, compute the stats
        for threshold in thresholds:
            image = get_selection(program_images[:threshold])
            precision, recall, f1 = results(ground_truth, image, beta=1)
            writer.writerow({
                'ensemble-ratio': threshold / len(program_images),
                'precision': precision,
                'recall': recall,
                'f-beta': f1,
                'beta': 1
            })

# prc evaluation
def prc_evaluation(program_images, ground_truth, output):
    # flatten the program images temporarily
    image = get_selection(program_images)

    # rank the nodes in the image by confidence (aka the number of programs they appear in)
    ranking = [(i, images_containing(i, program_images)) for i in image]
    ranking.sort(key=lambda p: p[-1], reverse=True)
    
    # list to hold the already-selected images
    selected = []

    # open the output
    with open(output, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'ranking', 'value', 'precision', 'recall', 'gt'
        ])
        writer.writeheader()

        # for every value/ranking, compute pr assuming that ranking as a threshold
        for (value, ranking) in ranking:
            selected.append(value)
            precision, recall, _ = results(ground_truth, selected, beta=1)
            writer.writerow({
                'ranking': ranking,
                'value': value,
                'precision': precision,
                'recall': recall,
                'gt': value in ground_truth
            })


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
    threshold_evaluation(program_images, ground_truth_image, args.threshold_steps, args.threshold_output)

    # if there's also a prc output, do that thing
    if args.prc_output != None:
        prc_evaluation(program_images, ground_truth_image, args.prc_output)