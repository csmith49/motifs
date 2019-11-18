from math import ceil, exp
from .ensemble import Ensemble

# normalization utility
def normalize(*args):
    total = sum(args)
    return [arg / total for arg in args]

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
    def probabilities(self, value):
        p_true, p_false = 0.0, 0.0
        for motif in self.motifs:
            if value in motif:
                p_true += exp(motif.accuracy)
                p_false += exp(-motif.accuracy)
            else:
                p_true += exp(-motif.accuracy)
                p_false += exp(motif.accuracy)
        return normalize(p_true, p_false)

    def update(self, value, result):
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
