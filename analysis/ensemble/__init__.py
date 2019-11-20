import numpy as np
from math import ceil, exp, log
from .ensemble import Ensemble, CLASSIFICATION_THRESHOLD, LEARNING_RATE, ACCURACY_THRESHOLD, CLASS_RATIO
import random

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
        return self.to_values(counts_for > (self.size * CLASSIFICATION_THRESHOLD))

class WeightedVote(Ensemble):
    def __init__(self, motifs):
        super().__init__(motifs)
        # set up weights and class ratio
        self._class_ratio = CLASS_RATIO
        self._alpha = np.ones(len(self._motif_map))
        # and motif accuracies
        acc = np.array([motif.size for motif in self._motif_map]) / self.size
        self._w_c = np.log((1 - acc - self._class_ratio) / (acc + self._class_ratio))

    def update(self, value, truth, learning_rate=None):
        # only do updates if the truth is good
        if truth != True:
            return None
        
        # set the learning rate if it's passed in
        if learning_rate is None:
            learning_rate = LEARNING_RATE

        # multiplicative updates to alpha
        v_i = self._value_map.index(value)
        m_i = (self._inclusion[v_i,] * 2) - 1

        self._alpha *= np.exp(learning_rate * m_i)

    def probabilities(self):
        w_i = self._w_c + 2 * self._alpha * self._class_ratio

        s_plus = self._inclusion @ np.transpose(np.exp(w_i))
        s_minus = (1 - self._inclusion) @ np.transpose(np.exp(-1 * w_i))
        Z = np.sum(np.exp(w_i))

        ans = (s_plus + s_minus) / Z

        return ans, 1 - ans

    def classified(self):
        p_true, p_false = self.probabilities()
        return self.to_values(p_true >= p_false)

    def max_entropy(self, domain):
        p_true, p_false = self.probabilities()
        entropy = np.where(
            self.to_row(domain) == 1,
            -1 * p_true * np.log(p_true + 0.001) - p_false * np.log(p_false + 0.001),
            np.zeros_like(p_true)
        )
        return self._value_map[np.argmax(entropy)]

ENSEMBLES = {
    'disjunction' : Disjunction,
    'majority-vote' : MajorityVote,
    'weighted-vote' : WeightedVote
}

from difflib import get_close_matches

def ensemble_from_string(string):
    candidates = get_close_matches(string, ENSEMBLES.keys(), n=1)
    return ENSEMBLES[candidates[0]]
