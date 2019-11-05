from .ensemble import RankingEnsemble

# motif partial order captured by subset inclusion on motif domain
def leq(left, right):
    return left.domain().issubset(right.domain())
def lt(left, right):
    return leq(left, right) and not left.domain() == right.domain()

# frontier for ranking ensembles
class Frontier(RankingEnsemble):
    def __init__(self, ensemble):
        self.ensemble = ensemble
        self.motifs = self.ensemble.motifs
        self._default_threshold = self.ensemble._default_threshold
        self._frontier = []
        # update frontier
        for motif in self.motifs:
            if not any([lt(motif, other) for other in self.motifs]):
                self._frontier.append(motif)

    def confidence(self, motif):
        return self.ensemble.confidence(motif)

    def rank(self, value):
        result = 0.0
        for motif in self._frontier:
            if value in motif:
                result += self.confidence(motif)
        return result