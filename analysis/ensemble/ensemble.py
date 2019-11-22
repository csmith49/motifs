import numpy as np

CLASSIFICATION_THRESHOLD=0.01
ACCURACY_THRESHOLD=0.7
LEARNING_RATE=4
CLASS_RATIO=0.1

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
        for motif in self._motif_map:
            rows.append(self.to_row(motif.domain()))
        # build inclusion matrix
        self._inclusion = np.transpose(np.array(rows))

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
    def domain(self):
        return self._value_map
    
    def domain_from_files(self, files):
        results = set()
        for motif in self._motif_map:
            results.update(motif.domain_from_files(files))
        return results

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
