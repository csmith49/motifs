from csv import DictWriter

# compute precision, recall, and f beta scores
def performance_statistics(selected, relevant, beta=1):
    # requires our images be given as sets
    true_positives = relevant & selected
    false_positives = selected - relevant

    # compte all the relevant stats, return as tuple
    if len(selected) == 0:
        precision = 0.0
    else:
        precision = len(true_positives) / (len(true_positives) + len(false_positives))
    recall = len(true_positives) / len(relevant)
    if precision == 0.0 and recall == 0.0:
        f_beta = 0.0
    else:
        f_beta = (1 + beta ** 2) * (precision * recall) / ((beta ** 2 * precision) + recall)
    return (precision, recall, f_beta)

# precision-recall evaluation
def prc(ensemble, ground_truth, output=None):
    # sort the values by the ranking
    ranking = [(v, ensemble.probabilities(v)[0]) for v in ensemble.domain()]
    ranking.sort(key=lambda p: p[-1], reverse=True)

    # list to hold the already-selectd iamges
    selected = set()
    # and the output
    result = []

    # compute the values
    for (value, ranking) in ranking:
        selected.add(value)
        try: precision, recall, _ = performance_statistics(selected, ground_truth, beta=1)
        except: precision, recall = 0, 0
        result.append({
            'ranking' : ranking,
            'value' : value,
            'precision' : precision,
            'recall' : recall,
            'gt' : value in ground_truth
        })

    # if we've been given output, use it, otherwise just return
    if output is None: return result
    else:
        with open(output, 'w') as f:
            writer = DictWriter(f, fieldnames=[
                'ranking', 'value', 'precision', 'recall', 'gt'
            ])
            writer.writeheader()
            for row in result:
                writer.writerow(result)