"""Public quantification dispatcher."""
import numpy as np
from add_height_gap import add_height_gap
from match_city_targets import match_city_targets
from quantify_city import quantify_city


def quantify(params, fund, targets, options):
    fields = ("floor_space_per_resident", "residential_rent", "total_urban_area", "cbd_far")
    active = [targets.get(name) is not None for name in fields]
    if active[0] and active[1]: raise ValueError("Choose either floor_space_per_resident or residential_rent, not both.")
    if (active[0] or active[1]) and not active[2]: raise ValueError("A housing quantity or rent target requires total_urban_area to identify physical space.")
    if active[1] and targets.get("wage") is None: raise ValueError("A residential_rent target requires an annual wage target.")
    if active[2] and targets["total_urban_area"] > np.pi*min(options["radius"], params["x1_max"])**2:
        raise ValueError("Total urban area exceeds the grid or urban growth boundary.")
    if targets.get("height_gap") is not None and np.isinf(params["S_bar_C"]) and np.isinf(params["S_bar_R"]) and any(active):
        raise ValueError("Height-gap calibration is only supported under the paper parameterization; omit it for empirical quantification.")
    baseline = match_city_targets(params, fund, targets, options, active) if any(active[1:]) else quantify_city(params, fund, options, targets)
    baseline["targets"] = dict(targets); baseline["options"] = dict(options)
    return add_height_gap(baseline, options, targets["urbanization_rate"])
