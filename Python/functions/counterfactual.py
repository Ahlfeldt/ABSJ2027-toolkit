"""Solve a counterfactual while holding regional population primitives fixed."""
from add_height_gap import add_height_gap
from apply_changes import apply_changes
from eqfind import eqfind
from pack_result import pack_result
from status import status
from validate_inputs import validate_inputs


def counterfactual(baseline, changes, options, urban_share):
    if not changes.get("set") and not changes.get("pct"):
        return None
    status(options, "Solving the counterfactual city...")
    params, fund = apply_changes(baseline["params"], baseline["fund"], changes)
    validate_inputs(params, fund)
    y, utility, scalist, varlist, iterations, density = eqfind(params, fund, options, baseline)
    result = pack_result(params, fund, y, utility, scalist, varlist, density, iterations)
    return add_height_gap(result, options, urban_share)
