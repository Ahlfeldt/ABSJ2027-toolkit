# ABSJ2027 MATLAB toolkit

The MATLAB version stays close to the code used for the paper: users edit one
of two lean master scripts, while all model equations, inversion routines,
graphs, validation, and exports live in separate files under `functions`.

- `scripts/MASTER_PAPER.m` retains the parameterization of the paper and
  illustrates joint vertical and horizontal development constraints.
- `scripts/MASTER_EMPIRICAL.m` illustrates inversion to annual wage,
  residential rent, total urban area, and central CBD FAR.

Open either master script in MATLAB and choose **Run**. Each script locates the
toolkit from its own file path, so it runs independently of MATLAB's current
working directory. No replication-directory files or external data are needed.

The toolkit has been tested with MATLAB R2024a Update 2. It requires the
**Statistics and Machine Learning Toolbox** for the inherited `nansum` calls.
The numerical searches use `fminsearch`, which is included with MATLAB; no
Optimization Toolbox is required.

Outputs are written to `outputs/Paper` or `outputs/Empirical`, with figures as
PNG/PDF, tables as CSV/XLSX/TEX, and complete MATLAB results in `results.mat`.
