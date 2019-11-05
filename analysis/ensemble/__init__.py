from .disjunction import Disjunction, Count
from .voting import MajorityVote, MostSpecific

ENSEMBLES = {
    'disjunction' : Disjunction,
    'count': Count,
    'majority-vote' : MajorityVote,
    'most-specific' : MostSpecific
}

from difflib import get_close_matches

def ensemble_from_string(string):
    candidates = get_close_matches(string, ENSEMBLES.keys(), n=1)
    return ENSEMBLES[candidates[0]]
