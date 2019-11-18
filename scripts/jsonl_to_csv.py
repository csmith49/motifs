from json import loads
from argparse import ArgumentParser
from csv import DictWriter

parser = ArgumentParser("jsonl2csv")
parser.add_argument("--input", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

if __name__ == "__main__":
    lines, keys = [], set()
    with open(args.input, "r") as f:
        for line in f.readlines():
            try:
                line = loads(line)
                lines.append(line)
                keys.update(line.keys())
            except:
                pass

    with open(args.output, "w") as f:
        writer = DictWriter(f, keys)
        writer.writeheader()
        for line in lines:
            writer.writerow(line)