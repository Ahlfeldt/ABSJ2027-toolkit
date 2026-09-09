"""Quantify one city, including migration and optional height-gap inversion."""
import numpy as np
from scipy.optimize import minimize

from find_utilde import find_utilde
from is_paper_parameters import is_paper_parameters
from pack_result import pack_result
from status import status
from validate_inputs import validate_inputs


def _solve(params, fund, options, urban_share, initial=None):
    fitted, y, utility, scalist, varlist, iterations, density = find_utilde(
        params, fund, options, urban_share, initial)
    return pack_result(fitted, fund, y, utility, scalist, varlist, density, iterations)


def quantify_city(params, fund, options, targets, initial=None):
    """Match urbanization and, when requested, the paper height-gap moment."""
    params = dict(params)
    params["N_bar"] = targets["population"] / targets["urbanization_rate"]
    if not params.get("U_tilde"):
        u0 = 0.2 if initial is None else (initial["utility"] if "utility" in initial else initial["U_bar"])
        params["U_tilde"] = u0 ** params["zeta"] * (1-targets["urbanization_rate"]) / targets["urbanization_rate"]
    validate_inputs(params, fund)

    manual_cap = np.isfinite(params["S_bar_R"]) or np.isfinite(params["S_bar_C"])
    gap = targets.get("height_gap")
    if gap is None or manual_cap:
        if gap is not None and manual_cap:
            status(options, "Manual height limits supersede the height-gap target.")
        result = _solve(params, fund, options, targets["urbanization_rate"], initial)
        result["targets"] = dict(targets); result["options"] = dict(options)
        return result
    if not is_paper_parameters(params):
        raise ValueError("The height gap can only be inverted under the paper parameterization because T is paper-specific.")

    status(options, "Matching the height gap (target %.1f%%)...", 100*gap)
    if gap <= options["hg_tol"]:
        params["S_bar_R"] = np.inf
        params["S_bar_C"] = np.inf
        result = _solve(params, fund, options, targets["urbanization_rate"], initial)
        result["targets"] = dict(targets); result["options"] = dict(options)
        return result

    cache = {"initial": initial}
    def objective(log_cap):
        cap = float(np.exp(log_cap[0]))
        trial = dict(params, S_bar_R=cap, S_bar_C=cap)
        result = _solve(trial, fund, options, targets["urbanization_rate"], cache["initial"])
        cache["initial"] = result
        unrestricted = _height_gap(result, options, targets["urbanization_rate"])
        return abs(unrestricted-gap)

    start = max(params["T"], 0.01)
    fit = minimize(objective, [np.log(start)], method="Nelder-Mead",
                   options={"xatol": options["tol"], "fatol": options["hg_tol"],
                            "maxiter": options["hg_max_iter"], "maxfev": options["hg_max_fun_eval"]})
    params["S_bar_R"] = float(np.exp(fit.x[0])); params["S_bar_C"] = params["S_bar_R"]
    result = _solve(params, fund, options, targets["urbanization_rate"], cache["initial"])
    result["height_gap"] = _height_gap(result, options, targets["urbanization_rate"])
    result["scalist"]["height_gap"] = result["height_gap"]
    result["targets"] = dict(targets); result["options"] = dict(options)
    return result


def _height_gap(result, options, urban_share):
    unrestricted_params = dict(result["params"], S_bar_R=np.inf, S_bar_C=np.inf)
    unrestricted = _solve(unrestricted_params, result["fund"], options, urban_share, result)
    denominator = unrestricted["scalist"]["F_tall"]
    return 0.0 if denominator <= 0 else max(0.0, 1-result["scalist"]["F_tall"]/denominator)
