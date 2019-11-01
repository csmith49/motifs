import csv, seaborn, pandas
import matplotlib.pyplot as plt
from argparse import ArgumentParser

parser = ArgumentParser()
parser.add_argument('--active-csv', required=True)
parser.add_argument('--output', default=None)

args = parser.parse_args()

# main
if __name__ == '__main__':
    # load the input data
    data = pandas.read_csv(args.active_csv)
    # convert data pivot style
    data = pandas.melt(
        data,
        id_vars=['learning-step'],
        value_vars=['precision', 'recall', 'f-beta', 'ensemble-ratio'],
        var_name='statistic',
        value_name='performance'
    )

    # set some stylistic stuff up
    seaborn.set_style("white")
    palette = seaborn.color_palette('husl', 4)

    # plot the darn thing
    seaborn.lineplot(
        x='learning-step', y='performance', data=data,
        hue='statistic', palette=palette)
    seaborn.despine()

    # some basic styling
    plt.xlabel("Learning Steps")
    # plt.xlim(0, 1)
    plt.ylabel("Performance")
    # plt.ylim(0, 1)
    plt.title("Performance Indicators")
    
    # if theres an output, save it, otherwise just show it
    if args.output != None:
        plt.savefig(args.output)
    else:
        plt.show()