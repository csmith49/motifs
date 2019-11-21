import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from argparse import ArgumentParser
import os

parser = ArgumentParser()
parser.add_argument("--benchmark", required=True)
args = parser.parse_args()

# load the data
data_path = os.path.join("csvs", f"{args.benchmark}-performance.csv")
with open(data_path, "r") as f:
    dataframe = pd.read_csv(f)

sns.lineplot(x="threshold", y="f1", hue="examples", data=dataframe)
plt.title(f"majority vote performance for {args.benchmark}")
plt.savefig(os.path.join("graphs", f"{args.benchmark}-majority-vote-threshold.png"))