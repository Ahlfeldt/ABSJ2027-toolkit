"""Urbanization inversion matching MATLAB FINDUtilde.m."""
import numpy as np
from eqfind import eqfind


def find_utilde(params, fund, options, urban_share, initial=None):
    params = dict(params)
    state = initial
    for iteration in range(1, options["max_iter"] + 1):
        y, utility, scalist, varlist, _, density = eqfind(params, fund, options, state)
        state = {"y": y, "U_bar": utility, "density": density}
        error = abs((scalist["N"] / params["N_bar"] - urban_share) / urban_share)
        if error < options["tol_U"]:
            return params, y, utility, scalist, varlist, iteration, density
        target = utility ** params["zeta"] * (1 - urban_share) / urban_share
        weight = options["conv_U"] / (1 + np.exp(-1000 * abs(target - params["U_tilde"]) + 1))
        if options["type"] == "rich":
            denominator = (1 + np.exp(-options["B_U"] * (iteration - options["M_U"]))) ** (1 / options["v_U"])
            weight = options["A_U"] + (weight - options["A_U"]) / denominator
        params["U_tilde"] = weight * target + (1 - weight) * params["U_tilde"]
    raise RuntimeError("Rural-utility inversion did not converge.")
