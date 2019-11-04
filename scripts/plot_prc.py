import seaborn
import matplotlib.pyplot as plt
from argparse import ArgumentParser
from pandas import concat
from analysis import load_prc

parser = ArgumentParser()
parser.add_argument('--prc-csv', nargs="+")
parser.add_argument('--output', default=None)

args = parser.parse_args()

# main
if __name__ == '__main__':
    # load the input data
    frames = []
    for csv_filepath in args.prc_csv:
        with open(csv_filepath, 'r') as f:
            frames.append(load_prc(csv_filepath))

    # stick them all together
    data = concat(frames, ignore_index=True, sort=False)

    # set some stylistic stuff up
    seaborn.set_style("white")
    palette = seaborn.color_palette('husl', n_colors=len(args.prc_csv))

    # plot the darn thing
    seaborn.lineplot(x='recall', y='precision', data=data,
        hue='tag', estimator=None, sort=False,
        palette=palette
    )
    seaborn.despine()

    # some basic styling
    plt.xlabel("Recall")
    plt.xlim(0, 1.1)
    plt.ylabel("Precision")
    plt.ylim(0, 1.1)
    plt.title("Precision-Recall Curve")
    
    # if theres an output, save it, otherwise just show it
    if args.output != None:
        plt.savefig(args.output)
    else:
        plt.show()