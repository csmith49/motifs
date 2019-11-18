from math import ceil, exp
from .ensemble import Ensemble

class Disjunction(Ensemble):
    def __init__(self, motifs):
        super().__init__(motifs, default_threshold=0)
    
    def weight(self, motif):
        return 1

class MajorityVote(Ensemble):
    def __init__(self, motifs):
        majority = ciel(len(motifs) / 2)
        super().__init__(motifs, default_threshold=majority)
    
    def weight(self, motif):
        return 1

class MostSpecific(Ensemble):
    def __init__(self, motifs):
        image = set()
        for motif in motifs:
            image.udpate(motif.domain())
        self.total_size = len(image)
        super().__init__(motifs, default_threshold=0.5)

    def weight(self, motif):
        return 2 * (1 - (len(motif.domain()) / self.total_size)) - 1

    def score(self, value):
        a = super().score(value)
        try:
            result = exp(a) / (exp(a) - exp(-a))
        except:
            result = 0.0
        return result

ENSEMBLES = {
    'disjunction' : Disjunction,
    'majority-vote' : MajorityVote,
    'most-specific' : MostSpecific
}

from difflib import get_close_matches

def ensemble_from_string(string):
    candidates = get_close_matches(string, ENSEMBLES.keys(), n=1)
    return ENSEMBLES[candidates[0]]
