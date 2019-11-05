from math import log2, inf

# summand term to keep entropy well-defined
def entropy_summand(p):
    if p == 0.0: return p
    else:
        return (-1 * p * log2(p))

# simple entropy
def entropy(value, groups):
    included, excluded = 0, 0
    for group in groups:
        if value in group: included += 1
        else: excluded += 1
    p_i = included / len(groups)
    p_e = excluded / len(groups)
    return entropy_summand(p_i) + entropy_summand(p_e)

# compute the maximum entropy value over a set of groups
def maximal_entropy(values, groups):
    m, m_e = None, -inf
    # check each possible value
    for v in values:
        v_e = entropy(v, groups)
        if v_e > m_e:
            m, m_e = v, v_e
    # return the maximal element and the associated entropy
    return m, m_e

class Active:
    def __init__(self, ensemble):
        self.ensemble = ensemble
        self.motifs = self.ensemble.motifs
    
    def candidate_split(self, frontier=False):
        if frontier:
            relevant_motifs = self.ensemble._frontier
        else:
            relevant_motifs = self.ensemble.motifs
        possibilities = self.ensemble.domain()
        split, _ = maximal_entropy(possibilities, relevant_motifs)
        return split
    
    def split_on(self, value, ground_truth_value):
        def pred(motif): 
            return (value in motif) == ground_truth_value
        ensemble = self.ensemble.filter(pred)
        return self.__class__(ensemble)