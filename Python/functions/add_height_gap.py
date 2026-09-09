"""Add the achieved height-gap statistic to a quantified result."""
import numpy as np
from find_utilde import find_utilde


def add_height_gap(result, options, urban_share):
    params = dict(result["params"], S_bar_R=np.inf, S_bar_C=np.inf)
    params, y, utility, scalist, _, _, _ = find_utilde(params, result["fund"], options, urban_share, result)
    denominator = scalist["F_tall"]
    result["height_gap"] = 0.0 if denominator <= 0 else max(0.0, 1-result["scalist"]["F_tall"]/denominator)
    result["scalist"]["height_gap"] = result["height_gap"]
    return result
