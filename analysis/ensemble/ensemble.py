class Ensemble:
    def __init__(self, motifs, default_threshold=0.5):
        self.default_threshold = default_threshold
        self.motifs = motifs
    
    def classify(self, value, threshold=None):
        if threshold is None:
            threshold = self.default_threshold
        prob_true, _ = self.probabilities(value)
        return prob_true > threshold

    def probabilities(self, value):
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