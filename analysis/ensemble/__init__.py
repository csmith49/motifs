from math import ceil, exp, log
from .ensemble import Ensemble

# normalization utility
def normalize(*args):
    total = sum(args)
    return [arg / total for arg in args]

# convert to prob
def to_prob(pos_value):
    return exp(pos_value) / (exp(pos_value) + exp(-pos_value))

# DISJUNCTION
class Disjunction(Ensemble):
    def probabilities(self, value):
        for motif in self.relevant_motifs():
            if value in motif:
                return 1, 0
        return 0, 1

    def entropy_probabilities(self, value):
        inc, exc = 0, 0
        for motif in self.relevant_motifs():
            if value in motif: inc += 1
            else: exc += 1
        return normalize(inc, exc)

    def update(self, value, result):
        self._accuracy_update(value, result)

# MAJORITY VOTE
class MajorityVote(Ensemble):
    def probabilities(self, value):
        inc, exc = 0, 0
        for motif in self.relevant_motifs():
            if value in motif: inc += 1
            else: exc += 1
        return normalize(inc, exc)
    
    def update(self, value, result):
        self._accuracy_update(value, result)

class MostSpecific(Ensemble):
    def __init__(self, motifs, class_ratio=0.01, **kwargs):
        super().__init__(motifs, **kwargs)
        self.total_size = len(self.domain())
        self.class_ratio = class_ratio

        # for memoizing some computations
        self.__been_updated = True
        self.__scores = []

    def accuracy(self, motif):
        # term 1 - p[m(x) = 1]
        image = motif.total_size / self.total_size

        # term 2 - p[y = 1]
        class_ratio = self.class_ratio

        # term 3 - FNR
        fnr = 1 - to_prob(motif.accuracy)

        # compute accuracy from p[m(x) != y]
        return 1 - (image - class_ratio + 2 * fnr)

    def score(self, motif):
        acc = self.accuracy(motif)
        return log(acc / (1 - acc))

    def probabilities(self, value):
        if self.__been_updated:
            self.__scores = [(motif, self.score(motif)) for motif in self.motifs]
            self.__been_updated = False

        p_true = sum([score for (motif, score) in self.__scores if value in motif])
        p_false = sum([score for (motif, score) in self.__scores if value not in motif])

        return normalize(p_true, p_false)

    def update(self, value, result):
        if result is True:
            self.__been_updated = True
            self._multiplicative_update(value, result)

ENSEMBLES = {
    'disjunction' : Disjunction,
    'majority-vote' : MajorityVote,
    'most-specific' : MostSpecific
}

from difflib import get_close_matches

def ensemble_from_string(string):
    candidates = get_close_matches(string, ENSEMBLES.keys(), n=1)
    return ENSEMBLES[candidates[0]]
