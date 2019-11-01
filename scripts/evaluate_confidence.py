import json, csv
from argparse import ArgumentParser
from numpy import exp
from math import inf

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--image", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--accuracy",
    choices=["big", "small", "scaled"],
    default="big")

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

# accuracies
def accuracy(image, total_image):
    i, t = len(image), len(total_image)
    if args.accuracy == "big":
        return t / i
    elif args.accuracy == "small":
        return 1 - (i / t)
    elif args.accuracy == "scaled":
        return 2 * (1 - i / t) - 1
    else:
        return None

def program_confidences(program_images):
    output = []
    total_image = get_selection(program_images)
    for image in program_images:
        output.append( (image, accuracy(image, total_image)) )
    return output

def confidence(value, confidences):
    cumulative_confidence = 0.0
    for image, confidence in confidences:
        if value in image:
            cumulative_confidence += confidence
    return cumulative_confidence

# prc evaluation
def prc_evaluation(images, ground_truth, ranking, output):
    # flatten the program images temporarily
    image = get_selection(images)

    # rank the nodes in the img by the provided ranking function
    ranking = [(i, ranking(i)) for i in image]
    ranking.sort(key=lambda p: p[-1], reverse=True)
    
    # list to hold the already-selected images
    selected = []

    # open the output
    with open(output, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'ranking', 'value', 'precision', 'recall', 'gt', 'accuracy'
        ])
        writer.writeheader()

        # for every value/ranking, compute pr assuming that ranking as a threshold
        for (value, ranking) in ranking:
            selected.append(value)
            try:
                precision, recall, _ = results(ground_truth, selected, beta=1)
            except:
                precision, recall = 0, 0
            writer.writerow({
                'ranking': ranking,
                'value': value,
                'precision': precision,
                'recall': recall,
                'gt': value in ground_truth,
                'accuracy': args.accuracy
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

    # if there's also a prc output, do that thing
    confidences = program_confidences(program_images)
    ranking = lambda i: confidence(i, confidences)
    prc_evaluation(program_images, ground_truth_image, ranking, args.output)