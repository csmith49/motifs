# row
class Row:
    def __init__(file, image):
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
        self.motif = json_rep['motif']
        self.rows = rows
    def __contains__(self, other):
        return any([other in row for row in self.rows])
    @classmethod
    def of_json(cls, json_rep):
        rows = [Row.of_json(row) for row in json_rep['images']]
        return cls(json_rep['motif'], rows)