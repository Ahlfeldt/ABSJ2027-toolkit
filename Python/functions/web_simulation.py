"""Thin JSON-friendly adapter for the browser-based paper model.

This module deliberately calls the existing toolkit functions.  It skips the
optional empirical-moment inversion and the descriptive height-gap re-solve so
that an interactive browser request only solves the baseline and counterfactual
cities.
"""

import math
import numpy as np

from apply_changes import apply_changes
from create_city import create_city
from eqfind import eqfind
from numerics import numerics
from pack_result import pack_result
from quantify_city import quantify_city
from validate_inputs import validate_inputs


DEFAULT_PARAMS = {
    "alpha_R": .66, "alpha_C": .85, "beta_R": 0.,
    "beta_dens_R": -.10535545480050244, "beta_C": .03,
    "tau_R": .016, "tau_C": .014, "x_core_R": 1., "x_core_C": 1.,
    "omega_R": .07, "omega_C": .03, "theta_C": .5, "theta_R": .55,
    "c_R": 150., "c_C": 150., "a_bar_R": 2., "a_bar_C": 2.,
    "r_a": 50., "ell": .5, "zeta": 6.4, "T": 2.9605069278556773,
    "S_bar_C": np.inf, "S_bar_R": np.inf, "x1_max": np.inf,
}

ALLOWED_SET = {"S_bar_C", "S_bar_R", "x1_max"}
ALLOWED_PCT = {"a_bar_C", "a_bar_R", "c_C", "c_R", "tau_C", "tau_R"}


def _number(value, name, minimum=None, maximum=None):
    value = float(value)
    if not math.isfinite(value):
        raise ValueError(f"{name} must be finite.")
    if minimum is not None and value < minimum:
        raise ValueError(f"{name} must be at least {minimum}.")
    if maximum is not None and value > maximum:
        raise ValueError(f"{name} must not exceed {maximum}.")
    return value


def _clean_changes(payload):
    supplied = payload.get("changes", {})
    changes = {"set": {}, "pct": {}}
    for name, value in supplied.get("set", {}).items():
        if name not in ALLOWED_SET:
            raise ValueError(f"The browser simulator cannot set {name}.")
        if value is not None and value != "":
            changes["set"][name] = _number(value, name, 0.01)
    for name, value in supplied.get("pct", {}).items():
        if name not in ALLOWED_PCT:
            raise ValueError(f"The browser simulator cannot change {name}.")
        if value is not None and value != "":
            changes["pct"][name] = _number(value, name, -95., 500.)
    return changes


def _safe(value):
    value = float(value)
    return value if math.isfinite(value) else None


def _profile(result, maximum_distance):
    distance = np.asarray(result["fund"]["D"])
    keep = distance <= maximum_distance
    indices = np.flatnonzero(keep)
    if indices.size > 260:
        indices = indices[np.linspace(0, indices.size - 1, 260).astype(int)]
    variables = result["varlist"]

    def values(name):
        array = np.asarray(variables[name])[indices]
        return [_safe(item) for item in array]

    return {
        "distance": [_safe(item) for item in distance[indices]],
        "commercial_height": values("S_x_C"),
        "residential_height": values("S_x_R"),
        "commercial_floor_rent": values("p_bar_x_C"),
        "residential_floor_rent": values("p_bar_x_R"),
        "commercial_land_rent": values("r_x_C"),
        "residential_land_rent": values("r_x_R"),
        "agricultural_land_rent": [_safe(result["params"]["r_a"])] * len(indices),
        "land_use": [int(item) if math.isfinite(float(item)) else None
                     for item in np.asarray(variables["U"])[indices]],
    }


def _aggregates(result):
    scalars = result["scalist"]
    names = ("N", "y", "GDP", "p_R", "p_C", "LV", "CC", "U_bar",
             "V", "AREA", "density", "DD", "F", "x0", "x1")
    return {name: _safe(scalars[name]) for name in names}


def simulate_web(payload):
    """Run the paper-parameterization baseline and one counterfactual."""
    baseline_inputs = payload.get("baseline", {})
    population = _number(baseline_inputs.get("population", 3_000_000),
                         "population", 10_000)
    urbanization = _number(baseline_inputs.get("urbanization_rate", .5),
                           "urbanization_rate", .01, .99)
    params = dict(DEFAULT_PARAMS)
    options = numerics()
    options["verbose"] = False
    fund = create_city(params, options)
    targets = {
        "population": population,
        "urbanization_rate": urbanization,
        "height_gap": None,
    }
    baseline = quantify_city(params, fund, options, targets)

    changes = _clean_changes(payload)
    counter_params, counter_fund = apply_changes(
        baseline["params"], baseline["fund"], changes)
    validate_inputs(counter_params, counter_fund)
    y, utility, scalars, variables, iterations, density = eqfind(
        counter_params, counter_fund, options, baseline)
    counterfactual = pack_result(counter_params, counter_fund, y, utility,
                                 scalars, variables, density, iterations)

    edge = max(baseline["scalist"]["x1"], counterfactual["scalist"]["x1"])
    maximum_distance = min(options["radius"], max(5., edge * 1.12))
    baseline_aggregates = _aggregates(baseline)
    counter_aggregates = _aggregates(counterfactual)
    changes_out = {}
    for name, base in baseline_aggregates.items():
        counter = counter_aggregates[name]
        changes_out[name] = None if base in (None, 0) or counter is None else counter / base - 1

    return {
        "baseline": {
            "aggregates": baseline_aggregates,
            "profile": _profile(baseline, maximum_distance),
            "iterations": baseline.get("iterations"),
        },
        "counterfactual": {
            "aggregates": counter_aggregates,
            "profile": _profile(counterfactual, maximum_distance),
            "iterations": counterfactual.get("iterations"),
        },
        "changes": changes_out,
        "metadata": {
            "mode": "paper_parameterization_fast",
            "spatial_units": "model units",
            "monetary_units": "model units",
        },
    }
