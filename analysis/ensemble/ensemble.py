class Ensemble:
    def __init__(self, motifs, default_threshold=0.0):
        self.default_threshold = default_threshold
        self.motifs = motifs
    
    def classify(self, value, threshold=None):
        if threshold is None:
            threshold = self.default_threshold
        return self.score(value) > threshold
    
    def score(self, value):
        scores = [self.weight(motif) for motif in self.motifs if value in motif]
        return sum(scores)

    def weight(self, motif):
        raise NotImplementedError

    def filter(self, pred):
        motifs = filter(pred, self.motifs)
        return self.__class__(list(motifs))

    def domain(self):
        result = set()
        for motif in self.motifs:
            result.update(motif.domain())
        return result
    
    def classified(self, threshold=None):
        result = set()
        for elt in self.domain():
            if self.classify(elt, threshold=threshold):
                result.add(elt)
        return result

    @property
    def size(self):
        return len(self.motifs)