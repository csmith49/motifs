import sqlite3, json, os
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('--input-directory', required=True)
parser.add_argument('--output', required=True)
parser.add_argument('--sql-path', required=True)

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
    # get all db filenames
    db_filepaths = []
    for filepath in os.listdir(args.input_directory):
        if filepath.endswith('.db'):
            db_filepaths.append(os.path.join(args.input_directory, filepath))

    # load the sql command
    with open(args.sql_path, 'r') as f:
        sql = f.read()

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