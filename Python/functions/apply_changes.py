"""Apply level and percentage counterfactual changes."""
import copy
import numpy as np


def apply_changes(params, fund, changes):
    params = dict(params); fund = copy.deepcopy(fund)
    levels = changes.get("set", {}); percentages = changes.get("pct", {})
    overlap = set(levels) & set(percentages)
    if overlap:
        raise ValueError("A variable cannot appear in both changes['set'] and changes['pct']: " + ", ".join(sorted(overlap)))
    for name, value in levels.items():
        _assign(params, fund, name, value)
    for name, value in percentages.items():
        baseline = params[name] if name in params else fund[name]
        if np.any(~np.isfinite(baseline)) or np.any(np.asarray(baseline) == 0):
            raise ValueError(f"Percentage changes require a finite, nonzero baseline for {name}.")
        _assign(params, fund, name, np.asarray(baseline)*(1+value/100))
    return params, fund


def _assign(params, fund, name, value):
    if name in params:
        params[name] = value
    elif name in ("a_rand_R", "a_rand_C"):
        fund[name] = np.broadcast_to(value, np.asarray(fund["D"]).shape).astype(float).copy()
    else:
        raise KeyError(f"Unknown primitive or parameter: {name}")
