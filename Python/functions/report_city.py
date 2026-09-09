"""Convert a result copy into user-facing units without changing the solver state."""
import copy
import numpy as np


def report_city(city, units):
    shown = copy.deepcopy(city); s = shown["scalist"]; raw = city["scalist"]
    s["total_urban_area"] = np.pi*raw["x1"]**2
    s["height_gap_pct"] = 100*city.get("height_gap", raw.get("height_gap", np.nan))
    for name in ("GDP", "wage_bill", "y", "LV"):
        if name in s: s[name] = raw[name]*units["factor"]
    for name in ("p_R", "p_C"):
        s[name] = raw[name]*units["factor"]/units["space_factor"]
    for name in ("p_bar_x_R", "p_bar_x_C", "r_x_R", "r_x_C"):
        shown["varlist"][name] = city["varlist"][name]*units["factor"]/units["space_factor"]
    shown["params"]["r_a"] = city["params"]["r_a"]*units["factor"]/units["space_factor"]
    weights = city["varlist"]["n_x"]; space = city["varlist"]["f_bar_x_R"]
    residents = np.nansum(weights)
    s["floor_space_per_resident"] = np.nansum(weights*space)/residents*units["space_factor"]
    s["housing_expenditure"] = np.nansum(weights*space*city["varlist"]["p_bar_x_R"])/residents*units["factor"]
    distance = np.maximum(0, city["fund"]["D"]-city["params"]["x_core_R"])
    loss = -np.expm1(-city["params"]["tau_R"]*distance)
    mean_loss = np.nansum(weights*loss)/residents
    s["commuting_income_loss"] = s["y"]*mean_loss; s["commuting_loss_pct"] = 100*mean_loss
    density = raw["N"]/raw["AREA"]
    density_loss = -np.expm1(city["params"]["beta_dens_R"]*np.log(density/units["reference_density"]))
    s["density_income_loss"] = s["y"]*density_loss; s["density_loss_pct"] = 100*density_loss
    shown["reporting"] = units
    return shown
