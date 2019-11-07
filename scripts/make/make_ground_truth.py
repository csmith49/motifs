import sqlite3, json, os
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('--db-directory', required=True)
parser.add_argument('--output', required=True)
parser.add_argument('--experiment', required=True)

args = parser.parse_args()

def process_db(db_filepath, sql):
    # connect to db
    connection = sqlite3.connect(db_filepath)
    cursor = connection.cursor()

    # evaluate the sql and get results
    cursor.execute(sql)
    for row in cursor.fetchall():
        yield row[0]

# main
if __name__ == "__main__":
    # load the experiment
    with open(args.experiment, 'r') as f:
        data = json.load(f)
    
    # check what kind of ground truth to make
    kind = data['ground-truth']['kind']
    
    # if we're provided, we'll just copy it over
    if kind == "provided":
        with open(args.output, 'w') as f:
            ground_truth = data['ground-truth']['labels']

    # if we're given a sql command, get all the dbs and execute
    elif kind == "sql":
        db_filepaths = []
        db_root = os.path.join(args.db_directory, data['ground-truth']['dataset'])
        for filepath in os.listdir(db_root):
            if filepath.endswith('.db'):
                db_filepaths.append(os.path.join(db_root, filepath))

        # construct json output
        ground_truth = []
        for db_filepath in db_filepaths:
            image = list(process_db(db_filepath, data['ground-truth']['sql']))
            ground_truth.append(
                {'file': db_filepath, 'example': image}
            )

    # write the output
    with open(args.output, 'w') as f:
        json.dump(ground_truth, f)