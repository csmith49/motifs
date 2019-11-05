# motif partial order captured by subset inclusion on motif domain
def leq(left, right):
    return left.domain().issubset(right.domain())
def lt(left, right):
    return leq(left, right) and not left.domain() == right.domain()

# compute the frontier
def frontier(motifs):
    # sorting helsp improve performance
    motifs = sorted(motifs, key=lambda m: len(m.domain()), reverse=True)
    results = []
    # check each canddiate
    for motif in motifs:
        ok = True
        for other in motifs:
            if motif.domain() != other.domain():
                if lt(motif, other):
                    ok = False
                    break
        if ok:
            results.append(motif)
    return results