import json, csv
from argparse import ArgumentParser
from math import log2, inf
from functools import reduce

parser = ArgumentParser()
parser.add_argument("--ground-truth", required=True)
parser.add_argument("--image", required=True)
parser.add_argument("--output", required=True)
parser.add_argument("--learning-steps", type=int, default=1)

args = parser.parse_args()

class Motif:
    def __init__(self, dict):
        self.image = set()
        self.motif = dict['motif']
        for row in dict['images']:
            self.image.update(row['image'])
    
    def __contains__(self, other):
        return other in self.image

    @staticmethod
    def disjunction(motifs):
        result = set()
        for motif in motifs:
            result |= motif.image
        return result

# compute precision, recall, and f beta scores
def results(relevant, selected, beta=1):
    relevant, selected = set(relevant), set(selected)

    true_positives = relevant & selected
    false_positives = selected - relevant

    precision = len(true_positives) / (len(true_positives) + len(false_positives))
    recall = len(true_positives) / len(relevant)
    f_beta = (1 + beta ** 2) * (precision * recall) / ((beta ** 2 * precision) + recall)
    return (precision, recall, f_beta)


# simulated active learning
def entropy_summand(p):
    if p == 0.0: return 0.0
    else:
        return (-1 * p * log2(p))

def entropy(value, motifs):
    included, excluded = 0, 0
    for motif in motifs:
        if value in motif: included += 1
        else: excluded += 1
    p_i = included / len(motifs)
    p_e = excluded / len(motifs)
    return entropy_summand(p_i) + entropy_summand(p_e)

def find_split(motifs):
    split, split_entropy = None, -inf
    # check each value in the image of the disjunction
    for value in Motif.disjunction(motifs):
        # compute the entropy and check if we've found the highest so far
        value_entropy = entropy(value, motifs)
        if value_entropy > split_entropy:
            split, split_entropy = value, value_entropy
    # return the split - may still be none
    return split

def split_on(split, ground_truth, motifs):
    consistent = []
    # we have to check every motif
    for motif in motifs:
        # if the motif agrees with the ground truth...
        if (split in motif) == (split in ground_truth):
            # we keep it
            consistent.append(motif)
    return consistent

# main
if __name__ == "__main__":
    # load the ground truth
    with open(args.ground_truth, 'r') as f:
        ground_truth_json = json.load(f)
    
        # compute ground truth image
        ground_truth = []
        for elt in ground_truth_json:
            ground_truth += elt['example']

    # load the image
    with open(args.image, 'r') as f:
        image = json.load(f)

        # load all the motifs
        motifs = []
        for motif in image:
            motifs.append(Motif(motif))

    # for some statistics
    number_of_motifs = len(motifs)
    
    # open the output file and fake active learning here
    with open(args.output, 'w') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'learning-step', 'ensemble-ratio', 'precision', 'recall', 'f-beta', 'beta'
        ])
        writer.writeheader()

        # for each step of the learning...
        for step in range(args.learning_steps):
            # compute the image and how good it is
            image = Motif.disjunction(motifs)
            precision, recall, f1 = results(ground_truth, image, beta=1)
            # write the results to the output file
            writer.writerow({
                'learning-step': step,
                'ensemble-ratio': len(motifs) / number_of_motifs,
                'precision': precision, 'recall': recall, 'f-beta': f1, 'beta': 1
            })
            # update the motifs by faking a learning loop
            split_value = find_split(motifs)
            # note the split may not exist
            if split_value is None: break
            # but if it is, update the motif list by getting rid of anything inconsistent
            motifs = split_on(split_value, ground_truth, motifs)