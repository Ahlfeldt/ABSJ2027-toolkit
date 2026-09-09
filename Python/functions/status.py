"""Progress reporting matching MATLAB STATUS.m."""


def status(options, message, *args):
    """Print one progress line unless verbose output is disabled."""
    if options.get("verbose", True):
        print("[ABSJ2027] " + (message % args if args else message), flush=True)