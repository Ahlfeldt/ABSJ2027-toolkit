"""Assemble solver outputs into the public result structure."""
import numpy as np


def pack_result(params, fund, y, utility, scalist, varlist, density, iterations=None):
    scalist = dict(scalist)
    scalist["GDP"] = scalist["y"]*scalist["N"]/params["alpha_C"]
    scalist["wage_bill"] = scalist["y"]*scalist["N"]
    scalist["density"] = scalist["N"]/scalist["AREA"]
    scalist["DD"] = scalist["density"]**params["beta_dens_R"]
    scalist["urban_share"] = scalist["N"]/params["N_bar"]
    scalist["F"] = scalist["F_C"]+scalist["F_R"]
    return {
        "params": dict(params),
        "fund": fund,
        "y": float(y),
        "utility": float(utility),
        "scalist": scalist,
        "varlist": varlist,
        "density": density,
        "iterations": iterations,
        "diagnostics": {"iterations": iterations,
            "labor_error": abs(scalist["L"]/scalist["N"]-1),
            "housing_error": abs(np.nansum(varlist["n_x"])/scalist["N"]-1),
            "density_error": abs(density/scalist["density"]-1)},
    }
