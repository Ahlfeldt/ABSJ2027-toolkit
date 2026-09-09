"""Conditional city equilibrium equations ported from MATLAB SOLVER.m."""

import numpy as np


def solver(params, fund, y, utility, density):
    """Evaluate the equilibrium mapping at candidate wage, utility, and density."""
    d = fund["D"]
    land = params["ell"] * fund["GEOLAND_x"]
    population = utility ** params["zeta"] / (utility ** params["zeta"] + params["U_tilde"]) * params["N_bar"]

    productivity = (fund["a_rand_C"] * params["a_bar_C"] * population ** params["beta_C"]
                    * np.exp(-params["tau_C"] * np.maximum(0.0, d - params["x_core_C"])))
    amenity = (fund["a_rand_R"] * params["a_bar_R"] * population ** params["beta_R"]
               * density ** params["beta_dens_R"]
               * np.exp(-params["tau_R"] * np.maximum(0.0, d - params["x_core_R"])))
    q_c = productivity ** (1 / (1 - params["alpha_C"])) * y ** (params["alpha_C"] / (params["alpha_C"] - 1))
    q_r = amenity ** (1 / (1 - params["alpha_R"])) * y ** (1 / (1 - params["alpha_R"])) * utility ** (-1 / (1 - params["alpha_R"]))

    height_c_star = (q_c / (params["c_C"] * (1 + params["theta_C"]))) ** (1 / (params["theta_C"] - params["omega_C"]))
    height_r_star = (q_r / (params["c_R"] * (1 + params["theta_R"]))) ** (1 / (params["theta_R"] - params["omega_R"]))
    height_c_all = np.minimum(height_c_star, params["S_bar_C"])
    height_r_all = np.minimum(height_r_star, params["S_bar_R"])

    bid_c = q_c / (1 + params["omega_C"]) * height_c_all ** (1 + params["omega_C"]) - params["c_C"] * height_c_all ** (1 + params["theta_C"])
    bid_r = q_r / (1 + params["omega_R"]) * height_r_all ** (1 + params["omega_R"]) - params["c_R"] * height_r_all ** (1 + params["theta_R"])

    use = np.full(d.shape, np.nan)
    use[(params["r_a"] > bid_c) & (params["r_a"] > bid_r)] = 3
    use[(bid_r > bid_c) & (bid_r > params["r_a"])] = 2
    use[(bid_c > bid_r) & (bid_c > params["r_a"])] = 1
    use[d > params["x1_max"]] = 3
    residential = np.flatnonzero((use == 2) & (d >= 0))
    noncommercial = np.flatnonzero((use != 1) & (d >= 0))
    x1 = np.max(d[residential]) if residential.size else np.nan
    x0 = np.min(d[noncommercial]) if noncommercial.size else np.nan

    height_c = np.where(use == 1, height_c_all, np.nan)
    height_r = np.where(use == 2, height_r_all, np.nan)
    floor_c_local = height_c * land
    floor_r_local = height_r * land
    floor_c = np.nansum(floor_c_local)
    floor_r = np.nansum(floor_r_local)
    tall_c = np.nansum(height_c * (height_c > params["T"]) * land)
    tall_r = np.nansum(height_r * (height_r > params["T"]) * land)
    tall_excess = (np.nansum(np.maximum(height_c - params["T"], 0) * land)
                   + np.nansum(np.maximum(height_r - params["T"], 0) * land))

    rent_c = np.where(use == 1, q_c / (1 + params["omega_C"]) * height_c ** params["omega_C"], np.nan)
    rent_r = np.where(use == 2, q_r / (1 + params["omega_R"]) * height_r ** params["omega_R"], np.nan)
    workers_local = params["alpha_C"] / (1 - params["alpha_C"]) * rent_c / y * height_c * land
    workers = np.nansum(workers_local)
    space_per_resident_local = np.where(use == 2, (1 - params["alpha_R"]) / rent_r * y, np.nan)
    residents_local = floor_r_local / space_per_resident_local

    product = np.nan_to_num(rent_c * floor_c_local, nan=0.0)
    y_up = params["alpha_C"] / (1 - params["alpha_C"]) * np.sum(product) / population
    housing_sum = np.nan_to_num(amenity ** (1 / (1 - params["alpha_R"])) * height_r ** (1 + params["omega_R"]) * land, nan=0.0)
    utility_up = ((y ** (1 / (1 - params["alpha_R"])) * np.sum(housing_sum) / (1 + params["omega_R"])) ** (1 - params["alpha_R"])
                  / ((1 - params["alpha_R"]) * y * population) ** (1 - params["alpha_R"]))

    urban = use < 3
    commercial = use == 1
    regional_welfare = (params["U_tilde"] + utility ** params["zeta"]) ** (1 / params["zeta"])
    area = np.pi * x1 ** 2 * params["ell"]
    with np.errstate(invalid="ignore", divide="ignore"):
        commuting = np.nansum(np.exp(params["tau_R"] * d) * residents_local) / np.nansum(residents_local)
        avg_rent_r = np.nansum(rent_r * residents_local) / np.nansum(residents_local)
        avg_rent_c = np.nansum(rent_c * workers_local) / np.nansum(workers_local)
        avg_productivity = np.nansum(productivity * workers_local) / np.nansum(workers_local)
    land_value = (np.nansum(land[use == 1] * bid_c[use == 1]) + np.nansum(land[use == 2] * bid_r[use == 2])
                  + np.nansum(land[use == 3] * params["r_a"]))
    with np.errstate(invalid="ignore", divide="ignore"):
        height_amenity = np.nansum(height_r ** (params["omega_R"] * (1 - params["alpha_R"])) * residents_local) / np.nansum(residents_local)

    varlist = {"LAND_x": land, "S_x_C": height_c, "S_x_R": height_r, "URBAN": urban, "COM": commercial,
               "p_bar_x_C": rent_c, "p_bar_x_R": rent_r, "r_x_C": bid_c, "r_x_R": bid_r,
               "L_x_C": workers_local, "f_bar_x_R": space_per_resident_local, "n_x": residents_local, "U": use}
    scalist = {"N": population, "L": workers, "AREA": area, "CC": commuting, "p_R": avg_rent_r, "p_C": avg_rent_c,
               "A_tilde_C": avg_productivity, "y": y, "LV": land_value, "U_bar": utility, "V": regional_welfare,
               "x0": x0, "x1": x1, "F_C": floor_c, "F_R": floor_r, "F_C_tall": tall_c, "F_R_tall": tall_r,
               "F_tall": tall_c + tall_r, "F_tallE": tall_excess, "HA": height_amenity}
    density_up = population / area if np.isfinite(area) and area > 0 else density
    return y_up, utility_up, scalist, varlist, density_up
