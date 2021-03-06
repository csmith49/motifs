import seaborn
import matplotlib.pyplot as plt
from argparse import ArgumentParser
from pandas import read_csv
from analysis import load_prc

parser = ArgumentParser()
parser.add_argument('--csv', required=True)
parser.add_argument('--output', default=None)

args = parser.parse_args()

# main
if __name__ == '__main__':
    # load the input data
    with open(args.csv, 'r') as f:
        data = read_csv(args.csv)

    # set some stylistic stuff up
    seaborn.set_style("white")
    n_colors = max(data['learning-step']) + 1
    palette = seaborn.color_palette('husl', n_colors=n_colors)

    # plot the darn thing
    seaborn.lineplot(x='recall', y='precision', data=data,
        hue='learning-step', estimator=None, sort=False,
        palette=palette
    )
    seaborn.despine()

    # some basic styling
    plt.xlabel("Recall")
    plt.xlim(0, 1.1)
    plt.ylabel("Precision")
    plt.ylim(0, 1.1)
    plt.title("Precision-Recall Curve for Active Learning")
    
    # if theres an output, save it, otherwise just show it
    if args.output != None:
        plt.savefig(args.output)
    else:
        plt.show()