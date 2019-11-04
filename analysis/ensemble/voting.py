from .ensemble import RankingEnsemble
from math import floor

# majority vote
class MajorityVote(RankingEnsemble):
    def __init__(self, motifs):
        default_threshold = floor(len(motifs) / 2)
        super().__init__(motifs, default_threshold=default_threshold)
    
    def ranking(self, value):
        count = 0
        for motif in self.motifs:
            if value in motif:
                count += 1
        return count

# vote with a per-motif weight
class WeightedVote(RankingEnsemble):
    def __init__(self, motifs, motif_weight):
        self._weight = motif_weight
        super().__init__(motifs)

    def ranking(self, value):
        count = 0
        for motif in self.motifs:
            if value in motif:
                count += self._weight(motif)
        return count