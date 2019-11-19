class Ensemble:
    def __init__(self, motifs, classification_threshold=0.7, accuracy_threshold=0.7, weight_smoothing=1, learning_rate=0.8):
        self.classification_threshold = classification_threshold
        self.accuracy_threshold = accuracy_threshold
        self.weight_smoothing = weight_smoothing
        self.learning_rate = learning_rate
        self.motifs = motifs
        for motif in self.motifs:
            motif.accuracy = 1
        self.observations = []

    def relevant_motifs(self):
        for motif in self.motifs:
            if motif.accuracy >= self.accuracy_threshold:
                yield motif

    def _accuracy_update(self, value, result):
        self.observations.append( (value, result) )
        for motif in self.motifs:
            correct = [v for (v, r) in self.observations if (v in motif) == r]
            accuracy = (self.weight_smoothing + len(correct)) / (self.weight_smoothing + len(self.observations))
            motif.accuracy = accuracy

    def _multiplicative_update(self, value, result):
        self.observations.append( (value, result) )
        for motif in self.motifs:
            if (value in motif) != result:
                motif.accuracy *= (1 - self.learning_rate)
            else:
                motif.accuracy *= (1 + self.learning_rate)

    def classify(self, value):
        prob_true, _ = self.probabilities(value)
        return prob_true > self.classification_threshold

    def domain(self):
        result = set()
        for motif in self.motifs:
            result.update(motif.domain())
        return result
    
    def classified(self):
        result = set()
        for elt in self.domain():
            if self.classify(elt):
                result.add(elt)
        return result

    def entropy_probabilities(self, value):
        return self.probabilities(value)

    @property
    def size(self):
        return len(self.motifs)

    def probabilities(self, value):
        raise NotImplementedError

    def update(self, value, result):
        raise NotImplementedError