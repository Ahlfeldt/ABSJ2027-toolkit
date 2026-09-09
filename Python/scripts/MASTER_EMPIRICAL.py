# %% ABSJ2027: empirically quantified city
# Edit the three input sections, then run this entire file in Spyder.
from pathlib import Path
import sys
import numpy as np

toolkit = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(toolkit / "functions"))
from numerics import numerics
from create_city import create_city
from quantify import quantify
from counterfactual import counterfactual as solve_counterfactual
from results import results
from save_results import save_results

# %% 1. Starting parameters: paper values before empirical calibration
params = {
    "alpha_R": .66, "alpha_C": .85, "beta_R": 0.,
    "beta_dens_R": -.10535545480050244, "beta_C": .03,
    "tau_R": .016, "tau_C": .014, "x_core_R": 1., "x_core_C": 1.,
    "omega_R": .07, "omega_C": .03, "theta_C": .5, "theta_R": .55,
    "c_R": 150., "c_C": 150., "a_bar_R": 2., "a_bar_C": 2.,
    "r_a": 50., "ell": .5, "zeta": 6.4, "T": 2.9605069278556773,
    "S_bar_C": np.inf, "S_bar_R": np.inf, "x1_max": np.inf,
}

# %% 2. Empirical baseline targets
targets = {
    "population": 3_000_000.,
    "floor_space_per_resident": None,
    "residential_rent": 240.,           # USD/m2/year with the wage below.
    "total_urban_area": np.pi * 18**2,  # Geographic km2, including undevelopable land.
    "cbd_far": 10.,
    "urbanization_rate": .50,
    "height_gap": None,                 # Descriptive only outside paper calibration.
    "wage": 75_000.,
    "currency": "USD",
}

# %% 3. Optional counterfactual changes
changes = {"set": {"S_bar_C": 7.5, "S_bar_R": 7.5, "x1_max": 15.}, "pct": {}}

# %% Create, quantify, solve, display, and save
options = numerics()
options["spacing"] = .005
fund = create_city(params, options)
baseline = quantify(params, fund, targets, options)
counterfactual = solve_counterfactual(baseline, changes, options, targets["urbanization_rate"])
statistics, figures = results(baseline, counterfactual)
save_results(toolkit / "outputs" / "Empirical", baseline, counterfactual, statistics, figures)
