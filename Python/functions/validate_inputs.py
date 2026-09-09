"""Economic input validation matching MATLAB VALIDATE_INPUTS.m."""

import numpy as np


def validate_inputs(params, fund):
    """Reject parameter combinations outside the model domain."""
    for name in ("c_R", "c_C", "a_bar_R", "a_bar_C", "r_a", "zeta", "U_tilde", "N_bar"):
        value = params[name]
        if not np.isfinite(value) or value <= 0:
            raise ValueError(f"{name} must be finite and positive.")
    for name in ("alpha_R", "alpha_C"):
        if not 0 < params[name] < 1:
            raise ValueError(f"{name} must lie strictly between zero and one.")
    if not 0 < params["ell"] <= 1:
        raise ValueError("ell must lie in (0,1].")
    for name in ("tau_R", "tau_C", "x_core_R", "x_core_C", "omega_R", "omega_C", "T"):
        if not np.isfinite(params[name]) or params[name] < 0:
            raise ValueError(f"{name} must be finite and nonnegative.")
    if params["theta_R"] <= params["omega_R"] or params["theta_C"] <= params["omega_C"]:
        raise ValueError("Each theta must exceed its matching omega.")
    for name in ("S_bar_R", "S_bar_C", "x1_max"):
        if np.isnan(params[name]) or params[name] <= 0:
            raise ValueError(f"{name} must be positive or infinite.")
    if params["tau_R"] / (1 - params["alpha_R"]) >= params["tau_C"] / (1 - params["alpha_C"]):
        raise ValueError("The commercial gradient must be steeper than the residential gradient.")
    for name in ("a_rand_R", "a_rand_C"):
        values = np.asarray(fund[name], dtype=float)
        if values.shape != np.asarray(fund["D"]).shape or np.any(~np.isfinite(values)) or np.any(values <= 0):
            raise ValueError(f"{name} must be a positive vector matching the radial grid.")