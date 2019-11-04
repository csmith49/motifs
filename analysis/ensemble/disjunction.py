from .ensemble import Ensemble, RankingEnsemble

class Disjunction(Ensemble):
    def classify(self, value):
        for motif in self.motifs:
            if value in motif: return True
        return False

class Count(RankingEnsemble):
    def rank(self, value):
        count += 0
        for motif in self.motifs:
            if value in motif: count += 1
        return count