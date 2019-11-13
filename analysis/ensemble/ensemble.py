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

    @property
    def size(self):
        return len(self.motifs)

# ranking ensemble provides a ranking function and a threshold
class RankingEnsemble(Ensemble):
    def __init__(self, motifs, default_threshold=0.0):
        self._default_threshold = default_threshold
        # self._frontier = frontier(motifs)
        super().__init__(motifs)

    # def domain(self):
    #     result = set()
    #     print("hello")
    #     for motif in self.motifs:
    #         result.update(motif.domain())
    #     return result

    def confidence(self, motif):
        raise NotImplementedError

    def rank(self, value, frontier=False):
        result = 0.0
        if frontier:
            relevant = self._frontier
        else:
            relevant = self.motifs
        for motif in relevant:
            if value in motif:
                result += self.confidence(motif)
        return result

    def classify(self, value, threshold=None, frontier=False):
        if threshold is None:
            threshold = self._default_threshold
        # print(self.rank(value, frontier=frontier))
        return self.rank(value, frontier=frontier) > threshold