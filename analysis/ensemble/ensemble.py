import numpy as np

HYPERPARAMETERS = {
    "classification-threshold" : 0.7,
    "accuracy-threshold" : 0.7,
    "learning-rate" : 0.8,
    "class-ratio" : 0.01
}

class Ensemble:
    def __init__(self, motifs):
        # construct set of all values captured by motifs
        values = set()
        for motif in motifs:
            values.update(motif.domain())
        # construct maps (by index)
        self._value_map = list(values)
        self._motif_map = motifs
        # construct rows
        rows = []
        for value in self._value_map:
            row = [1 if value in motif else 0 for motif in self._motif_map]
            rows.append(row)
        # build inclusion matrix
        self._inclusion = np.array(rows)

    # for converting a row to a set of values
    def to_values(self, row):
        result = set()
        for v, w in zip(self._value_map, np.nditer(row, order='C')):
            if w:
                result.add(v)
        return result

    def to_row(self, values):
        row = [1 if value in values else 0 for value in self._value_map]
        return np.array(row)

    # some accessors
    @property
    def domain(self):
        return self._value_map
    
    @property
    def size(self):
        return len(self._motif_map)

    # some builtins, easily redefined
    def classify(self, value):
        value in self.classified()

    # to be defined by subclasses
    def update(self):
        raise NotImplementedError

    def classified(self):
        raise NotImplementedError