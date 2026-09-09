"""Fixed-point equilibrium solver matching MATLAB EQFIND.m."""

import numpy as np
from solver import solver


def eqfind(params, fund, options, initial=None):
    """Solve for wage, urban utility, and density using MATLAB damping rules."""
    if initial is None:
        state = {"y": 1.0, "U_bar": 0.2, "density": 1000.0}
    elif "scalist" in initial:
        state = {"y": initial["y"], "U_bar": initial["utility"], "density": initial["density"]}
    else:
        state = dict(initial)
    y = state["y"]
    utility = state["U_bar"]
    density = state["density"]
    for iteration in range(1, options["max_iter"] + 1):
        y_up, utility_up, scalist, varlist, density_up = solver(params, fund, y, utility, density)
        y_up = max(0.9 * y, min(1.1 * y, y_up))
        utility_up = max(0.9 * utility, min(1.1 * utility, utility_up))
        density_up = max(0.9 * density, min(1.1 * density, density_up))
        rel_y = abs((y_up - y) / max(abs(y), 1e-8))
        rel_u = abs((utility_up - utility) / max(abs(utility), 1e-8))
        rel_d = abs((density_up - density) / max(abs(density), 1e-8))
        if max(rel_y, rel_u, rel_d) < options["tol"]:
            break
        if options["type"] == "rich":
            conv_y = options["A"] + (min(options["conv"], rel_y) - options["A"]) / (1 + np.exp(-options["B"] * (iteration - options["M"]))) ** (1 / options["v"])
            conv_u = options["A"] + (0.05 - options["A"]) / (1 + np.exp(-options["B"] * (iteration - options["M"]))) ** (1 / options["v"])
            conv_d = options["A"] + (0.25 - options["A"]) / (1 + np.exp(-options["B"] * (iteration - options["M"]))) ** (1 / options["v"])
        elif options["type"] == "jump" and iteration <= options["jump_n"]:
            boost = min(1.0, (options["jump_m"] * iteration + options["jump_x"] * options["max_iter"]) / ((1 + options["jump_x"]) * options["max_iter"]))
            conv_y = min(options["conv"], rel_y) ** boost
            conv_u = 0.05 ** boost
            conv_d = 0.25 ** boost
        else:
            conv_y, conv_u, conv_d = min(options["conv"], rel_y), 0.05, 0.25
        y = y_up * conv_y + y * (1 - conv_y)
        utility = utility_up * conv_u + utility * (1 - conv_u)
        density = density_up * conv_d + density * (1 - conv_d)
    else:
        raise RuntimeError("City equilibrium did not converge.")
    values = np.array([scalist["N"], scalist["L"], scalist["AREA"], y, utility, density])
    if np.any(~np.isfinite(values)) or np.any(values <= 0):
        raise RuntimeError("Inputs do not produce a finite positive equilibrium.")
    if not np.any(varlist["COM"]) or not np.any(varlist["URBAN"] & ~varlist["COM"]):
        raise RuntimeError("The city must contain commercial and residential land.")
    if scalist["x1"] >= np.max(fund["D"]) and params["x1_max"] >= np.max(fund["D"]):
        raise RuntimeError("The city reaches the numerical grid edge.")
    return y, utility, scalist, varlist, iteration, density
