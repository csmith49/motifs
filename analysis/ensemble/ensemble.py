# ensemble base class
class Ensemble:
    def __init__(self, motifs):
        self.motifs = motifs
    
    def classify(self, value):
        raise NotImplementedError

    def __contains__(self, value):
        return self.classify(value)

    def filter(self, pred):
        motifs = filter(pred, self.motifs)
        return self.__class__.__init__(list(motifs))

# ranking ensemble provides a ranking function and a threshold
class RankingEnsemble(Ensemble):
    def __init__(self, motifs, default_threshold=0.0):
        self._default_threshold = default_threshold
        super().__init__(motifs)

    def rank(self, value):
        raise NotImplementedError

    def classify(self, value, threshold=None):
        if threshold is None:
            threshold = self._default_threshold
        return self.rank(value) > threshold