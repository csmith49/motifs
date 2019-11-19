from math import log2, inf

# summand term to keep entropy well-defined
def entropy_summand(p):
    if p <= 0.0: 
        print(f"WARNING: Non-positive probability of {p}")
        return 0.0
    else: return (-1 * p * log2(p))

def ensemble_entropy(value, ensemble):
    p_i, p_e = ensemble.entropy_probabilities(value)
    return entropy_summand(p_i) + entropy_summand(p_e)

def maximal_ensemble_entropy(values, ensemble):
    m, m_e = None, -inf
    # check each val
    for v in values:
        v_e = ensemble_entropy(v, ensemble)
        if v_e > m_e:
            m, m_e = v, v_e
    # return the maximal elt, and assoc entropy
    return m, m_e

def candidate_split(possibilities, ensemble):
    split, _ = maximal_ensemble_entropy(possibilities, ensemble)
    return split