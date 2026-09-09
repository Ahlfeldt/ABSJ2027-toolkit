"""Jointly fit the optional housing, urban-area, and CBD-FAR moments."""
import numpy as np
from scipy.optimize import minimize
from city_target_objective import city_target_objective
from quantify_city import quantify_city
from report_city import report_city
from report_units import report_units
from status import status


def match_city_targets(params, fund, targets, options, active):
    housing = active[0] or active[1]; count = int(housing)+int(active[2])+int(active[3])
    status(options, "Matching optional city targets: housing costs %d; agricultural land rent %d; common tau scale %d.", housing, active[2], active[3])
    seed = quantify_city(params, fund, options, targets)
    work = dict(options, initial=seed)
    shown = report_city(seed, report_units(seed)); z0 = np.ones(count); k = 0
    if housing:
        ratio = (shown["scalist"]["floor_space_per_resident"]/targets["floor_space_per_resident"]
                 if active[0] else targets["residential_rent"]/shown["scalist"]["p_R"])
        z0[k] = 1+(1+params["theta_R"])*np.log(ratio); k += 1
    if active[2]:
        z0[k] = 1+np.log(shown["scalist"]["total_urban_area"]/targets["total_urban_area"]); k += 1
    if active[3]:
        fitted = seed
        if housing or active[2]:
            preliminary = list(active); preliminary[3] = False
            fitted = match_city_targets(params, fund, targets, options, preliminary)
            j = 0
            if housing:
                z0[j] = 1+np.log(fitted["params"]["c_R"]/params["c_R"]); j += 1
            if active[2]:
                z0[j] = 1+np.log(fitted["params"]["r_a"]/params["r_a"])
        z0[k] = 1+0.8*np.log(targets["cbd_far"]/fitted["varlist"]["S_x_C"][0])
    objective = lambda z: city_target_objective(z, params, fund, targets, work, active)[0]
    fit = minimize(objective, z0, method="Nelder-Mead",
                   options={"xatol": 5e-4, "fatol": 1e-9, "maxiter": 200, "maxfev": 400})
    _, result, errors = city_target_objective(fit.x, params, fund, targets, work, active, final=True)
    if np.max(np.abs(errors)) > .005:
        raise RuntimeError(f"Optional targets could not be matched within 0.5%. Maximum relative error {100*np.max(np.abs(errors)):.3f}%.")
    result["diagnostics"] = {"optional_target_relative_errors": errors,
        "optional_target_tolerance": .005, "starting_tau_R": params["tau_R"], "starting_tau_C": params["tau_C"],
        "tau_multiplier": result["params"]["tau_R"]/params["tau_R"], "starting_c_R": params["c_R"],
        "starting_c_C": params["c_C"], "starting_r_a": params["r_a"],
        "construction_cost_multiplier": result["params"]["c_R"]/params["c_R"]}
    return result
