import numpy as np
from math import ceil, exp, log
from .ensemble import Ensemble, CLASSIFICATION_THRESHOLD, LEARNING_RATE, ACCURACY_THRESHOLD, CLASS_RATIO

# normalization utility
def normalize(*args):
    total = sum(args)
    return [arg / total for arg in args]

# convert to prob
def to_prob(pos_value):
    return exp(pos_value) / (exp(pos_value) + exp(-pos_value))

# summand term to keep entropy well-defined
def entropy_summand(p):
    if p <= 0.0: 
        print(f"WARNING: Non-positive probability of {p}")
        return 0.0
    else: return (-1 * p * log2(p))

# DISJUNCTION
class Disjunction(Ensemble):
    def __init__(self, motifs, accuracy_smoothing=1):
        # build inclusion matrix
        super().__init__(motifs)
        # we keep observations
        self._observations = []
        # and a set of accuracies built from the observations
        self.accuracy_smoothing = accuracy_smoothing
        self._accuracies = np.ones(len(self._motif_map))

    def update(self, value, truth):
        self._observations.append( (value, truth) )
        accuracies = []
        for motif in self._motif_map:
            correct = sum([1 for (value, truth) in self._observations if (value in motif) == truth])
            total = len(self._observations)
            accuracies.append(
                (correct + self.accuracy_smoothing) / (total + self.accuracy_smoothing)
            )
        self._accuracies = np.array(accuracies)
    
    # get the indicator array for all motifs with accuracies above the threshold
    def _relevant_motifs(self):
        return np.where(
            self._accuracies >= ACCURACY_THRESHOLD,
            np.ones_like(self._accuracies),
            np.zeros_like(self._accuracies)
        )

    def classified(self):
        counts = self._inclusion @ np.transpose(self._relevant_motifs())
        return self.to_values(counts)

    def max_entropy(self, domain):
        relevant = self._relevant_motifs()
        pos_counts = self._inclusion @ np.transpose(relevant)
        neg_counts = (1 - self._inclusion) @ np.transpose(relevant)

        size = self.size
        pos_ent = -1 * (pos_counts / size) * np.log2(pos_counts + 0.01)
        neg_ent = -1 * (neg_counts / size) * np.log2(neg_counts + 0.01)
        entropy = np.where(
            self.to_row(domain) == 1,
            pos_ent + neg_ent,
            np.zeros_like(pos_ent)
        )

        return self._value_map[np.argmax(entropy)]

# MAJORITY VOTE
class MajorityVote(Disjunction):
    def classified(self):
        relevant = self._relevant_motifs()
        counts_for = self._inclusion @ np.transpose(relevant)
        counts_against = (1 - self._inclusion) @ np.transpose(relevant)
        return self.to_values(counts_for > counts_against)

class WeightedVote(Ensemble):
    def __init__(self, motifs):
        super().__init__(motifs)
        # set up weights and class ratio
        self._class_ratio = CLASS_RATIO
        self._weights = np.ones(len(self._motif_map))
        # and motif accuracies
        self._accuracies = np.array([motif.size for motif in self._motif_map]) / self.size

    def update(self, value, truth, learning_rate=None):
        # only do updates if the truth is good
        if truth != True:
            return None
        
        if learning_rate is None:
            learning_rate = LEARNING_RATE

        # otherwise, we're doing multiplicative updates to the weights based on who agrees
        value_index = self._value_map.index(value)
        agreement = self._inclusion[value_index,]
        updates = np.where(
            agreement > 1,
            np.ones_like(agreement) * (1 + learning_rate),
            np.ones_like(agreement) * (1 - learning_rate)
        )

        # do the update
        self._weights *= updates

        m, M = np.argmin(self._weights), np.argmax(self._weights)
        print(self._weights[m], self._weights[M])
        print(self._accuracies[m], self._accuracies[M])

    def probabilities(self):
        fnr = 1 - np.exp(self._weights) / (np.exp(self._weights) + np.exp(-1 * self._weights))
        accuracies = np.clip(1 - (self._accuracies - self._class_ratio + 2 * fnr), 0.001, 0.999)
        p_true = np.exp(self._inclusion @ np.transpose(np.log(accuracies)))
        p_false = np.exp(self._inclusion @ np.transpose(np.log(1 - accuracies)))

        yes = self._inclusion @ np.transpose(np.exp(self._weights))
        no = (1 - self._inclusion) @ np.transpose(np.exp(-1 * self._weights))
        trial = (yes + no) / np.sum(np.exp(self._weights))

        return trial, 1 - trial

    def classified(self):
        score_for, score_against = self.probabilities()
        return self.to_values(score_for > score_against)

    def max_entropy(self, domain):
        p_true, p_false = self.probabilities()
        entropy = np.where(
            self.to_row(domain) == 1,
            -1 * p_true * np.log(p_true + 0.001) - p_false * np.log(p_false + 0.001),
            np.zeros_like(p_true)
        )
        return self._value_map[np.argmax(entropy)]

    # def max_entropy(self, domain):
    #     score_for, score_against = self.scores()
    #     entropy = np.where(
    #         self.to_row(domain) == 1,
    #         np.abs(score_for - score_against),
    #         np.ones_like(score_for) * np.infty
    #     )
    #     return self._value_map[np.argmin(entropy)]

ENSEMBLES = {
    'disjunction' : Disjunction,
    'majority-vote' : MajorityVote,
    'weighted-vote' : WeightedVote
}

from difflib import get_close_matches

def ensemble_from_string(string):
    candidates = get_close_matches(string, ENSEMBLES.keys(), n=1)
    return ENSEMBLES[candidates[0]]
