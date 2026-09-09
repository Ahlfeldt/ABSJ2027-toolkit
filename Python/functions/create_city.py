"""Create the radial land grid without solving the model."""

import numpy as np


def create_city(params, options):
    """Build the symmetric coordinates and nonnegative radial integration grid."""
    ell = float(params["ell"])
    radius = float(options["radius"])
    spacing = float(options["spacing"])
    if not (0.0 < ell <= 1.0 and radius > 0.0 and spacing > 0.0):
        raise ValueError("ell, radius, and spacing must be positive; ell cannot exceed one.")
    cells = round(radius / spacing)
    if cells < 2 or abs(cells * spacing - radius) > 1e-8:
        raise ValueError("The radius must be an integer multiple of spacing.")
    x = np.arange(-cells, cells + 1, dtype=float) * spacing
    distance = x[x >= 0.0]
    width = (x.max() - x.min()) / x.size
    return {
        "x": x,
        "D": distance,
        "GEOLAND_x": width * 2.0 * np.pi * (distance + 0.5 * width),
        "a_rand_C": np.ones_like(distance),
        "a_rand_R": np.ones_like(distance),
        "grid_spacing": spacing,
    }