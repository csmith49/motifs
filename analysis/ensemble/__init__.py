from math import ceil, exp
from .ensemble import Ensemble

# normalization utility
def normalize(*args):
    total = sum(args)
    return [arg / total for arg in args]

# DISJUNCTION
class Disjunction(Ensemble):
    def probabilities(self, value):
        for motif in self.motifs:
            if value in motif:
                return 1, 0
        return 0, 1

class MajorityVote(Ensemble):
    def probabilities(self, value):
        inc, exc = 0, 0
        for motif in self.motifs:
            if value in motif:
                inc += 1
            else:
                exc += 1
        return normalize(inc, exc)

class MostSpecific(Ensemble):
    def __init__(self, motifs, default_threshold=0.5):
        image = set()
        for motif in motifs:
            image.update(motif.domain())
        self.total_size = len(image)
        super().__init__(motifs, default_threshold=default_threshold)

    def weight(self, motif):
        return (1 - (len(motif.domain()) / self.total_size))

    def probabilities(self, value):
        p_true, p_false = 0.0, 0.0
        for motif in self.motifs:
            if value in motif:
                p_true += exp(self.weight(motif))
                p_false += exp(-self.weight(motif))
            else:
                p_true += exp(-self.weight(motif))
                p_false += exp(self.weight(motif))
        return normalize(p_true, p_false)

ENSEMBLES = {
    'disjunction' : Disjunction,
    'majority-vote' : MajorityVote,
    'most-specific' : MostSpecific
}

from difflib import get_close_matches

def ensemble_from_string(string):
    candidates = get_close_matches(string, ENSEMBLES.keys(), n=1)
    return ENSEMBLES[candidates[0]]
