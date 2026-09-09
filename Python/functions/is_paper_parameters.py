"""Identify the structural parameterization associated with the paper's T."""

import numpy as np


PAPER_PARAMETERS = {
    "alpha_R": 0.66, "alpha_C": 0.85, "beta_R": 0.0,
    "beta_dens_R": -0.10535545480050244, "beta_C": 0.03,
    "tau_R": 0.016, "tau_C": 0.014, "x_core_R": 1.0, "x_core_C": 1.0,
    "omega_R": 0.07, "omega_C": 0.03, "theta_C": 0.5, "theta_R": 0.55,
    "c_R": 150.0, "c_C": 150.0, "a_bar_R": 2.0, "a_bar_C": 2.0,
    "r_a": 50.0, "ell": 0.5, "zeta": 6.4, "T": 2.9605069278556773,
}


def is_paper_parameters(params):
    """Return True when every paper structural parameter agrees to numerical tolerance."""
    return all(name in params and np.isclose(params[name], value, rtol=1e-10, atol=1e-10)
               for name, value in PAPER_PARAMETERS.items())