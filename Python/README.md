# ABSJ2027 Python toolkit

The Python version mirrors the MATLAB toolkit: users edit one of two lean master
scripts, while all model equations, inversion routines, graphs, and exports live
in separate files under `functions`.

- `scripts/MASTER_PAPER.py` retains the parameterization of the paper.
- `scripts/MASTER_EMPIRICAL.py` illustrates inversion to annual wage, residential
  rent, total urban area, and central CBD FAR.

Both scripts use Spyder `# %%` cells and locate the toolkit from their own file
path, so they run independently of Spyder's current working directory. Open a
master script in Spyder and choose **Run file**. The standard Anaconda/Spyder
scientific stack supplies NumPy, SciPy, pandas, Matplotlib, and openpyxl; minimum
versions are listed in `requirements.txt`.

The scripts explicitly display all three figures. To show them in Spyder's
**Plots** pane, select the **Inline** graphics backend under
**Tools > Preferences > IPython console > Graphics** and restart the console
after changing that setting. Other backends open the same figures in separate
windows instead.

Outputs are written to `outputs/Paper` or `outputs/Empirical`, with figures as
PNG/PDF, tables as CSV/XLSX/TEX, and full results as a Python pickle.
