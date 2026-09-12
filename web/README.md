# ABSJ2027 web tools

This folder contains two static, GitHub Pages-compatible interfaces:

- `index.html` compares the precomputed counterfactual results for 12,873 cities.
- `simulator.html` runs a new baseline and counterfactual city using the Python
  paper parameterization.

The simulator loads Pyodide, NumPy, and SciPy from the jsDelivr CDN. It then
loads the model modules directly from `Python/functions` and runs them in a Web
Worker. Calculations take place on the visitor's computer. There is no Python
server, database, user account, or submitted user data.

The browser adapter is `Python/functions/web_simulation.py`. It calls the same
city creation, validation, equilibrium, change, and result-packing functions as
the desktop toolkit. To keep interaction fast, it omits the optional empirical
moment inversion and the extra solve used only to report the height gap.

Serve the repository root over HTTP for local testing. Opening the HTML files
directly from disk will not work because browsers restrict Worker and module
file access from `file:` URLs.
