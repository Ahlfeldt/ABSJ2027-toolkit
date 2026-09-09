"""Objective used to invert optional empirical city targets."""
import numpy as np
from quantify_city import quantify_city
from report_city import report_city
from report_units import report_units
from status import status


def city_target_objective(z, params, fund, targets, options, active, final=False):
    trial = dict(params); k = 0; cost_multiplier = 1.0; tau_multiplier = 1.0
    if active[0] or active[1]:
        cost_multiplier = np.exp(z[k]-1); k += 1
        trial["c_R"] *= cost_multiplier; trial["c_C"] *= cost_multiplier
    if active[2]:
        trial["r_a"] *= np.exp(z[k]-1); k += 1
    if active[3]:
        tau_multiplier = np.exp(z[k]-1); k += 1
        trial["tau_R"] *= tau_multiplier; trial["tau_C"] *= tau_multiplier
    try:
        initial = options.get("initial")
        if initial is not None:
            height_scale = cost_multiplier**(-1/(1+trial["theta_R"]))
            wage_scale = cost_multiplier**(-(1-trial["alpha_C"])*(1+trial["omega_C"])/(1+trial["theta_C"]))
            initial = {"y": initial["scalist"]["y"]*wage_scale,
                       "U_bar": initial["scalist"]["U_bar"]*wage_scale*height_scale**((1+trial["omega_R"])*(1-trial["alpha_R"])),
                       "density": initial["density"]}
        result = quantify_city(trial, fund, options, targets, initial)
        shown = report_city(result, report_units(result))
        actual = []; desired = []
        if active[0]: actual.append(shown["scalist"]["floor_space_per_resident"]); desired.append(targets["floor_space_per_resident"])
        elif active[1]: actual.append(shown["scalist"]["p_R"]); desired.append(targets["residential_rent"])
        if active[2]: actual.append(np.pi*result["scalist"]["x1"]**2); desired.append(targets["total_urban_area"])
        if active[3]: actual.append(result["varlist"]["S_x_C"][0]); desired.append(targets["cbd_far"])
        actual = np.asarray(actual); desired = np.asarray(desired)
        errors = actual/desired-1
        loss = float(np.sum(np.log(actual/desired)**2))
        status(options, "Optional target fit: maximum error %.3f%%; c_R %.6g, c_C %.6g, agricultural rent %.6g; tau multiplier %.6g.",
               100*np.max(np.abs(errors)), trial["c_R"], trial["c_C"], trial["r_a"], tau_multiplier)
        return loss, result, errors
    except (RuntimeError, ValueError, FloatingPointError):
        if final: raise
        return 1e6+float(np.sum(np.asarray(z)**2)), None, None
