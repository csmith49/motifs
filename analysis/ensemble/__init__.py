import numpy as np
from math import ceil, exp, log
from .ensemble import Ensemble, HYPERPARAMETERS

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
            self._accuracies >= HYPERPARAMETERS['accuracy-threshold'],
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

        return self._value_map(np.argmax(entropy))

# MAJORITY VOTE
class MajorityVote(Disjunction):
    def classified(self):
        relevant = self._relevant_motifs()
        counts_for = self._inclusion @ np.transpose(relevant)
        counts_against = (1 - self._inclusion) @ np.transpose(relevant)
        return self.to_values(counts_for > counts_against)

class MostSpecific(Ensemble):
    pass
    # def __init__(self, motifs, class_ratio=0.01, **kwargs):
    #     super().__init__(motifs, **kwargs)
    #     self.total_size = len(self.domain())
    #     self.class_ratio = class_ratio

    #     # for memoizing some computations
    #     self.__been_updated = True
    #     self.__scores = []

    # def accuracy(self, motif):
    #     # term 1 - p[m(x) = 1]
    #     image = motif.total_size / self.total_size

    #     # term 2 - p[y = 1]
    #     class_ratio = self.class_ratio

    #     # term 3 - FNR
    #     fnr = 1 - to_prob(motif.accuracy)

    #     # compute accuracy from p[m(x) != y]
    #     return 1 - (image - class_ratio + 2 * fnr)

    # def score(self, motif):
    #     acc = self.accuracy(motif)
    #     return log(acc / (1 - acc))

    # def probabilities(self, value):
    #     if self.__been_updated:
    #         self.__scores = [(motif, self.score(motif)) for motif in self.motifs]
    #         self.__been_updated = False

    #     p_true = sum([score for (motif, score) in self.__scores if value in motif])
    #     p_false = sum([score for (motif, score) in self.__scores if value not in motif])

    #     return normalize(p_true, p_false)

    # def update(self, value, result):
    #     if result is True:
    #         self.__been_updated = True
    #         self._multiplicative_update(value, result)

ENSEMBLES = {
    'disjunction' : Disjunction,
    'majority-vote' : MajorityVote,
    'most-specific' : MostSpecific
}

from difflib import get_close_matches

def ensemble_from_string(string):
    candidates = get_close_matches(string, ENSEMBLES.keys(), n=1)
    return ENSEMBLES[candidates[0]]
