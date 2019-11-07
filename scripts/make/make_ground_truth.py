import sqlite3, json, os
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('--db-directory', required=True)
parser.add_argument('--output', required=True)
parser.add_argument('--sql', required=True)

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
    # load the sql thing
    with open(args.sql, 'r') as f:
        data = json.load(f)
        dataset, sql = data['dataset'], data['sql']

    # get all db filenames
    db_filepaths = []
    db_root = os.path.join(args.db_directory, dataset)
    for filepath in os.listdir(db_root):
        if filepath.endswith('.db'):
            db_filepaths.append(os.path.join(db_root, filepath))

    # construct json output
    output = []
    for db_filepath in db_filepaths:
        image = list(process_db(db_filepath, sql))
        output.append(
            {'file': db_filepath, 'example': image}
        )
    
    # write the output
    with open(args.output, 'w') as f:
        json.dump(output, f)