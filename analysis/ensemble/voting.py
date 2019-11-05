from .ensemble import RankingEnsemble
from math import floor

# majority vote
class MajorityVote(RankingEnsemble):
    def __init__(self, motifs):
        default_threshold = floor(len(motifs) / 2)
        super().__init__(motifs, default_threshold=default_threshold)
    
    def confidence(self, motif):
        return 1

class MostSpecific(RankingEnsemble):
    def __init__(self, motifs):
        image = set()
        for motif in motifs:
            image.udpate(motif.domain())
        self.total_size = len(image)
        super().__init__(motifs)

    def confidence(self, motif):
        return len(motif.domain()) / self.total_size

# vote with a per-motif weight
class WeightedVote(RankingEnsemble):
    def __init__(self, motifs, motif_weight):
        self._weight = motif_weight
        super().__init__(motifs)

    def confidence(self, motif):
        return self._weight(motif)