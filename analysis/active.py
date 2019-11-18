from math import log2, inf

# summand term to keep entropy well-defined
def entropy_summand(p):
    if p == 0.0: return p
    else:
        return (-1 * p * log2(p))

def ensemble_entropy(value, ensemble):
    p_i, p_e = ensemble.probabilities(value)
    # convert to entropy
    return entropy_summand(p_i) + entropy_summand(p_e)

def maximal_ensemble_entropy(values, ensemble):
    m, m_e = None, -inf
    # check each val
    possibilities = [(value, ensemble_entropy(value, ensemble)) for value in values]
    entropies = set([p[1] for p in possibilities])
    if len(entropies) <= 1:
        return None, -inf
    else:
        return max(possibilities, key=lambda p: p[1])

class Active:
    def __init__(self, ensemble):
        self.ensemble = ensemble

    def candidate_split(self, possibilities=None):
        if possibilities is None:
            possibilities = self.ensemble.domain()
        split, entropy = maximal_ensemble_entropy(possibilities, self.ensemble)
        return split

    def split_on(self, value, ground_truth_value):
        def pred(motif): 
            return (value in motif) == ground_truth_value
        ensemble = self.ensemble.filter(pred)
        return self.__class__(ensemble)