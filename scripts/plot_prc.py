import csv, seaborn, pandas, os
import matplotlib.pyplot as plt
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('--prc-csv', nargs="+")
parser.add_argument('--output', default=None)

args = parser.parse_args()

def load_dataframe(filepath):
    # pull the base out of the filepath
    experiment_name = os.path.splitext(os.path.basename(filepath))[0]
    # load the frame
    frame = pandas.read_csv(filepath)
    # add the base as a new column so we can plot all possible values
    exp_column = [experiment_name for _ in frame['value']]
    frame['experiment'] = exp_column
    # return
    return frame

def join(frames):
    return pandas.concat(frames, ignore_index=True, sort=False)

# main
if __name__ == '__main__':
    # load the input data
    frames = []
    for csv_filepath in args.prc_csv:
        with open(csv_filepath, 'r') as f:
            frames.append(load_dataframe(csv_filepath))

    data = join(frames)

    # set some stylistic stuff up
    seaborn.set_style("white")
    palette = seaborn.color_palette('husl', n_colors=len(args.prc_csv))

    # plot the darn thing
    seaborn.lineplot(x='recall', y='precision', data=data,
        hue='experiment', estimator=None, sort=False,
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