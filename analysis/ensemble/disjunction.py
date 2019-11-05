from .ensemble import Ensemble, RankingEnsemble

class Disjunction(Ensemble):
    def classify(self, value):
        for motif in self.motifs:
            if value in motif: return True
        return False

class Count(RankingEnsemble):
    def confidence(self, motif):
        return 1