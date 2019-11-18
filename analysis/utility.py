from pandas import read_csv
import json
from os.path import splitext, basename

# load ground truth as a big set, and an index mapping each value to the file it came from
def load_ground_truth(json):
    source = {}
    image = set()

    # iterate over every row
    for row in json:
        for value in row['example']:
            image.add(value)
            source[value] = row['file']

    return image, source

# load prc data
def load_prc(filepath):
    tag = splitext(basename(filepath))[0]
    # load the frame
    frame = read_csv(filepath)
    # add the tag as a new column
    tag_column = [tag for _ in frame['value']]
    frame['tag'] = tag_column

    return frame
