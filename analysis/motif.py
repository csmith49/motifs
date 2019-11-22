import json
import os

def file_equal(left, right):
    return os.path.basename(left) == os.path.basename(right)

# row
class Row:
    def __init__(self, file, image):
        self.file = file
        self.image = image
    def __contains__(self, other):
        return other in self.image
    @classmethod
    def of_json(cls, json_rep):
        return cls(json_rep['file'], set(json_rep['image']))

# motifs
class Motif:
    def __init__(self, motif, rows):
        self.motif = motif
        self.rows = rows
        self.size = len(self.domain())
    def __contains__(self, other):
        return any([other in row for row in self.rows])

    # what are the values captured by this motif
    def domain(self):
        result = set()
        for row in self.rows:
            result.update(row.image)
        return result

    def domain_from_files(self, files):
        result = set()
        for row in self.rows:
            if any([file_equal(row.file, file) for file in files]):
                result.update(row.image)
        return result

    # for ease of construction
    @classmethod
    def of_json(cls, json_rep):
        rows = [Row.of_json(row) for row in json_rep['images']]
        return cls(json_rep['motif'], rows)

# loading from file
def load_motifs(filename, unique=False):
    motifs = []
    with open(filename, 'r') as f:
        for motif in json.load(f):
            motifs.append(Motif.of_json(motif))
    if unique:
        results, images = [], []
        for motif in motifs:
            if motif.domain() not in images:
                results.append(motif)
                images.append(motif)
        return results
    else:
        return motifs
