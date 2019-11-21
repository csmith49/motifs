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

sns.lineplot(x="al-step", y="f1", data=dataframe)
plt.title(f"Weighted vote performance for {args.benchmark}")
plt.savefig(os.path.join("graphs", f"{args.benchmark}-weighted-vote-convergence.png"))