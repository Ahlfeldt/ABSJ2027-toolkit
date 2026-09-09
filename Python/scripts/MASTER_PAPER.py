# %% ABSJ2027: paper-parameterization city
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

# %% 1. Baseline parameters and fundamentals: paper parameterization
params = {
    "alpha_R": .66, "alpha_C": .85, "beta_R": 0.,
    "beta_dens_R": -.10535545480050244, "beta_C": .03,
    "tau_R": .016, "tau_C": .014, "x_core_R": 1., "x_core_C": 1.,
    "omega_R": .07, "omega_C": .03, "theta_C": .5, "theta_R": .55,
    "c_R": 150., "c_C": 150., "a_bar_R": 2., "a_bar_C": 2.,
    "r_a": 50., "ell": .5, "zeta": 6.4, "T": 2.9605069278556773,
    "S_bar_C": np.inf, "S_bar_R": np.inf, "x1_max": np.inf,
}
# S_bar_C and S_bar_R are height/FAR limits: floor area per unit developable land.
# Any finite manual limit supersedes targets["height_gap"]. x1_max is an optional
# horizontal urban growth boundary in model distance units.

# %% 2. Empirical baseline targets
targets = {
    "population": 3_000_000.,
    "floor_space_per_resident": None,  # Alternative housing target, m2/resident.
    "residential_rent": None,          # Annual currency/m2; requires wage and area.
    "total_urban_area": None,          # Geographic km2, including undevelopable land.
    "cbd_far": None,                   # Central CBD floor area ratio.
    "urbanization_rate": .50,          # Urban share of city plus hinterland population.
    "height_gap": 0.,                  # Fraction: 0.5 means a 50 percent height gap.
    "wage": None,                      # Average annual wage; None keeps model units.
    "currency": "USD",
}
# Height-gap inversion should only be used with the paper parameterization.

# %% 3. Optional counterfactual changes
changes = {"set": {}, "pct": {}}
# changes["pct"]["a_bar_C"] = 10       # Raise productivity by 10 percent.
# changes["pct"]["c_R"] = -10         # Reduce residential construction costs 10 percent.
changes["set"]["S_bar_C"] = 10.
changes["set"]["S_bar_R"] = 10.
changes["set"]["x1_max"] = 20.

# %% Create, quantify, solve, display, and save
options = numerics()
fund = create_city(params, options)
baseline = quantify(params, fund, targets, options)
counterfactual = solve_counterfactual(baseline, changes, options, targets["urbanization_rate"])
statistics, figures = results(baseline, counterfactual)
save_results(toolkit / "outputs" / "Paper", baseline, counterfactual, statistics, figures)
