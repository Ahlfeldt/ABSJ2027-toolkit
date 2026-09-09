"""Numerical controls matching MATLAB NUMERICS.m."""


def numerics():
    """Return a fresh dictionary of documented numerical controls."""
    return {
        "verbose": True,
        "radius": 100.0,
        "spacing": 0.01,
        "conv": 0.01,
        "conv_U": 0.5,
        "tol": 0.001,
        "tol_U": 0.001,
        "max_iter": 1000,
        "type": "rich",
        "A": 0.98,
        "B": 1.0,
        "v": 1.0,
        "M": 8.0,
        "A_U": 0.99,
        "B_U": 1.0,
        "v_U": 1.0,
        "M_U": 22.0,
        "jump_x": 0.0002,
        "jump_m": 7.5,
        "jump_n": 7,
        "jump_x_U": 0.001,
        "jump_m_U": 0.2,
        "jump_n_U": 22,
        "hg_tol": 0.01,
        "hg_max_iter": 250,
        "hg_max_evals": 300,
    }