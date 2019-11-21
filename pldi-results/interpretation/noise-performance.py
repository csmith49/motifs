import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
from argparse import ArgumentParser
import os

parser = ArgumentParser()
parser.add_argument("--type", required=True, choices=["struct", "typo", "syn"])
args = parser.parse_args()

# load the data
data_path = os.path.join("csvs", f"noise-{args.type}-performance.csv")
with open(data_path, "r") as f:
    dataframe = pd.read_csv(f)

# convert experiment names to noise ratios
def noise_ratio(exp_name):
    return int(exp_name.split("-")[-1]) / 100

dataframe['noise-ratio'] = dataframe['benchmark'].apply(noise_ratio)

sns.lineplot(x="noise-ratio", y="f1", hue="ensemble", data=dataframe)
plt.title(f"Performance wrt {args.type} noise")
plt.savefig(os.path.join("graphs", f"noise-{args.type}-performance.png"))