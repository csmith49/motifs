import csv, seaborn
import matplotlib.pyplot as plt
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('--prc-csv', required=True)
parser.add_argument('--output', default=None)

args = parser.parse_args()

# main
if __name__ == '__main__':
    # load the input data
    datapoints = []
    with open(args.prc_csv, 'r') as f:
        for row in csv.DictReader(f):
            datapoints.append(row)

    # project to x and y axes for plot
    x = [float(row['recall']) for row in datapoints]
    y = [float(row['precision']) for row in datapoints]

    # set some stylistic stuff up
    seaborn.set_style("white")

    # plot the darn thing
    seaborn.lineplot(x=x, y=y, estimator=None)
    seaborn.despine()

    # some basic styling
    plt.xlabel("recall")
    plt.xlim(0, 1)
    plt.ylabel("precision")
    plt.ylim(0, 1)
    plt.title("PRC Curve")
    
    # if theres an output, save it, otherwise just show it
    if args.output != None:
        plt.savefig(args.output)
    else:
        plt.show()