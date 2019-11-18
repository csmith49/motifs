from .frontier import frontier

# ensemble base class
class Ensemble:
    def __init__(self, motifs):
        self.motifs = motifs
    
    def classify(self, value):
        raise NotImplementedError

    def __contains__(self, value):
        return self.classify(value)

    def filter(self, pred):
        motifs = filter(pred, self.filter_candidates())
        return self.__class__(list(motifs))

    def domain(self):
        result = set()
        for motif in self.motifs:
            result.update(motif.domain())
        return result
    
    def filter_candidates(self):
        return self.motifs

    def classified(self):
        result = set()
        for elt in self.domain():
            if self.classify(elt):
                result.add(elt)
        return result

    @property
    def size(self):
        return len(self.motifs)

# ranking ensemble provides a ranking function and a threshold
class RankingEnsemble(Ensemble):
    def __init__(self, motifs, default_threshold=0.0):
        self._default_threshold = default_threshold
        super().__init__(motifs)

    def confidence(self, motif):
        raise NotImplementedError

    def rank(self, value):
        result = 0.0
        for motif in self.motifs:
            if value in motif:
                result += self.confidence(motif)
        return result

    def classify(self, value, threshold=None):
        if threshold is None:
            threshold = self._default_threshold
        return self.rank(value) > threshold

    def classified(self, threshold=None):
        result = set()
        for elt in self.domain():
            if self.classify(elt, threshold=threshold):
                result.add(elt)
        return result