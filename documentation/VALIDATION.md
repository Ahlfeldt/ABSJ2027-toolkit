# Initial validation

MATLAB: 24.1.0.2578822 (R2024a) Update 2. All 8 check groups passed.

- Master baseline-only workflow, graphics, population, markets, and GDP
- Omitted changes, empty changes, and exact zero-shock identity
- All three paper illustrative experiments within 0.6 percentage points
- Binding, nonbinding, and joint growth-boundary/height-cap experiments
- Interior height-gap inversion, boundary-conditional inversion, and direct-cap mode
- Repeatable percentage changes, fixed baseline primitives, and independent sector parameters
- Duplicate, unknown, infinite-percentage, and invalid-parameter rejection
- Exact original SOLVER identity at Inf and original baseline inversion comparison

Baseline population: 2998157.426104; target: 3,000,000.
Baseline GDP: 4013325.779980 model output units.
Maximum original-inversion relative difference: 0.
Maximum deviation from rounded illustrative reference: 0.094731 percentage points.

The full validation took approximately 116 seconds on this machine. The baseline solve alone took approximately 1.3 seconds. These timings are illustrative, not guarantees.

Run VALIDATE_TOOLKIT to generate current JSON, tables, and plots under MATLAB/outputs/validation. The original directory is needed only for the optional source comparison.

Final documented-version rerun: all 8 groups passed in 98 seconds. Required products confirmed by MATLAB: MATLAB and Statistics and Machine Learning Toolbox. One named function per file was checked for all 18 function files; MASTER contains no function definitions. Seven tracked source hashes remained unchanged. MATLAB Code Analyzer reported only advisory modernization, unused-variable, and small-loop allocation messages; inherited core calculations were retained.


## Progress reporting and input labels (8 September 2026)

Targeted MATLAB checks passed for the 50% interior height-gap inversion, zero and
100% endpoints, direct-cap mode, baseline-only output, and a productivity
counterfactual. Progress-enabled and quiet runs returned exactly identical
aggregate results and spatial profiles. Quiet mode emitted no progress text.
The unit check rejects `targets.height_gap = 10` with an explicit instruction to
use `0.1` for 10%. The master baseline is restored to `0`; `0.5` appears only as
a 50% example in its comments. These checks concern reporting and input labels;
the numerical equations and search controls were not changed.

## Figure and table exports (8 September 2026)

The master now calls SAVE_RESULTS automatically. MATLAB checks confirmed three
PNG/PDF figure pairs under Figures and TEX/CSV/XLSX tables under Tables. CSV and
XLSX numeric round trips matched MATLAB values within 1e-12 relative tolerance.
Baseline and counterfactual exports passed; exporting baseline-only results over
an existing comparison workbook removed the old comparison columns. LaTeX special
characters were escaped, and both table variants compiled successfully.

## Annual wage and square-metre reporting (8 September 2026)

Tests passed in MATLAB R2024a: supplying a 40,000 annual wage left every raw
baseline scalar and spatial profile exactly unchanged and produced a displayed
wage of 40,000. The counterfactual retained the same baseline conversion, preserving
its wage ratio. Local housing budgets and resident-weighted average expenditure
matched (1-alpha_R)*wage. Rents were divided by 1e6 for m², and floor space per
resident was multiplied by 1e6. Both calibrated and uncalibrated tables/figures
exported successfully. Invalid negative wage inputs were rejected.

## Manual height/FAR precedence (8 September 2026)

Checks passed for caps in either sector alone and both sectors together, against
conflicting height-gap targets 0, 0.5, and 1. Every result exactly matched direct
cap mode in both aggregate and spatial outputs. Both supplied caps were preserved,
including an unrestricted Inf sector. With both input caps Inf, gap inversion
still matched 0, 0.5, and 1. Progress text identified the overridden target.
The original inputs remain in requested_targets; targets.height_gap is empty
when ignored, and diagnostics.height_gap_overridden records this decision.

## Commuting income equivalent (8 September 2026)

Targeted MATLAB tests passed for resident weighting, zero tau_R, all locations
inside the flat core, a known constant distance, annual wage conversion, unchanged
raw results, and counterfactual use of the common baseline conversion. Doubling
the currency conversion doubled the monetary loss without changing its wage
share. The table contains 24 rows; both new commuting measures were exported to
CSV, XLSX, and LaTeX, and the XLSX loss matched the MATLAB value.

## Residential floor-space target (8 September 2026)

The unrestricted master now matches the requested 50 m² per resident by calibrating
c_R from 150 to approximately 14527.5. Two conditional city solves were required.
Population and urbanization remain matched. With the current USD 50,000 annual
wage target, reported average residential rent is about USD 373.73/m²/year.

Targeted tests passed for the new floor-space target, original 955.70796 m²
normalization when the target is empty, preservation of calibrated c_R in
counterfactuals, finite manual FAR precedence, and simultaneous matching of
50 m², a 50% height gap, and population. Core equilibrium equations were not
changed. The user-facing master regenerated PNG/PDF figures and TEX/CSV/XLSX
tables. Original-paper comparison tests now explicitly disable the additional
housing target before comparing against the original normalization.

## Baseline-referenced density disamenity (8 September 2026)

MATLAB checks passed for exact zero baseline loss, positive/negative signs with
higher/lower density, zero elasticity, invariance to area units, currency scaling,
unchanged raw results, counterfactual use of the baseline reference, and undefined
percentage changes from a zero baseline. Both new rows were exported successfully.


## Common construction-cost calibration (8 September 2026)

Supersedes the earlier residential-only cost calibration. The actual master
ran and exported all figures and tables: 50.037 m² per resident, c_R=c_C about
8377.75 (common multiplier 55.85), below 0.1% floor-space matching error.
Targeted MATLAB checks passed: unequal starting ratio 150/200 is preserved;
empty target retains both costs; a productivity counterfactual inherits both
calibrated costs; manual FAR caps retain precedence and the floor-space fit.
The joint 50 m² / 50% height-gap test raises ABSJ2027:HeightGap with simulated
zero gap, rather than silently accepting an unmatched target. This combination
does not pass for the current primitives. Default zero-gap master passed.
The full original paper-reference suite was not rerun for this change.


## Alternative housing and total-area targets (8 September 2026)

Targeted MATLAB checks passed with paper starting parameters and zero height gap:
- Empty optional targets retain construction costs and agricultural rent.
- Annual wage 50000, residential rent 240 and geographic area 1000 km²:
  achieved rent 239.719 and area 999.861; c_R=c_C=3556.37, r_a=221.688.
- Residential floor space 75 m²/resident and area 1000 km²:
  achieved 75.0415 and 998.740; c_R=c_C=3446.56, r_a=222.778.
- Area-only target 2500 km²: achieved 2498.32, with both costs retained at 150.
- A productivity counterfactual retains calibrated agricultural rent and costs.
- Simultaneous housing targets, rent without wage, and area beyond the domain
  are rejected. Empty counterfactual returns the baseline-only path.

The search now uses starting-city moment predictions and scaled warm starts;
cold initializations caused trial convergence failures during development.
Recognized failed trials are penalized, while final failures remain errors.
Final matching tolerance is 0.5%; a 0.2% objective-based early stop avoids excess
refinement on the spatial grid. These checks do not establish feasibility for
arbitrary positive height-gap targets or binding policy combinations. The full
paper-reference validation suite was not rerun for this extension.


## Common tau experiment: central CBD FAR near 10 (8 September 2026)

MASTER now sets tau_scale=2.30, tau_R=0.0368 and tau_C=0.0322. It retains
annual wage 75000 USD, residential rent target 240 USD/m²/year, total geographic
area target pi*18^2 km², population 3 million, urbanization 0.5 and zero height
gap. Both starting construction costs remain 150; their common fitted value
is 1292.79. Starting agricultural rent remains 50; its fitted value is 26.2613.

Trials at common tau multipliers 2, 2.24 and 3 gave central CBD FARs 8.13889,
9.62285 and 15.0225 after re-matching the same empirical targets. The final
master run at 2.30 gives CBD FAR 10.0266 and maximum residential FAR 4.1097.
It achieves annual residential rent 239.7299, fringe 17.995 km, geographic area
1017.3106 km², and residential floor space 125.3458 m² per resident. Commercial
rent is 462.406 USD/m²/year. Optional target errors are at most 0.113%; population
error 0.0792%, labor residual 0.0986%, housing residual 0.0035%.

The stronger-decay search encountered nonconvergent trial cities on the original
10-metre radial grid. The successful search and final master use a 5-metre grid
via explicit options.spacing=0.005 in MASTER, passed to CREATE_CITY and QUANTIFY.
The default NUMERICS grid and all equilibrium equations/tolerances are unchanged.
The final master was verified from its normal starting inputs, and all three
figures and all summary-table formats were regenerated. This is an experimental
parameterization, not the paper-default baseline. The full reference suite was
not rerun for this experiment.


## CBD target and independent master scripts (8 September 2026)

MASTER_EMPIRICAL was run from paper starting parameters, with rent 240,
annual wage 75000, area pi*18^2 and cbd_far=10. All optional target errors
were at most 0.111%. The estimated common tau multiplier was 2.29991,
with c_R=c_C=1296.48 and agricultural rent 26.0963. The tau ratio remained
8/7 to floating-point precision. The full script exported all figures and
table formats under outputs/Empirical.

Additional MATLAB checks passed: CBD-only calibration retains construction
costs and agricultural rent; a productivity counterfactual inherits both
calibrated taus; a central FAR target at a finite commercial cap is rejected;
a zero starting tau is rejected. After empirical targets were placed in the
workspace, MASTER_PAPER reset them all and reproduced the paper parameter
values, 10-metre grid and baseline diagnostics. It exported separately under
outputs/Paper, preserving the empirical results. MASTER remains a small wrapper
for MASTER_PAPER. The full original paper-reference suite was not rerun.


## Paper-only height-gap inversion and reported gaps (8 September 2026)

Targeted MATLAB checks passed: a paper 50% height-gap inversion agrees with the
saved outcome within its original tolerance; unrestricted baseline gap is 0%;
commercial and residential caps at T produce a counterfactual gap of 100%;
percentage change from a zero baseline is undefined. Setting T above all possible
tall development produces a NaN outcome, not a spurious zero. Non-paper parameter
values and optional empirical quantification reject active height-gap inversion.
Manual cap precedence is retained in the implementation.

Both master scripts ran and exported successfully. Empirical height_gap is empty;
its other optional targets still match within 0.111%. Both current baselines
report zero realized gap and store the outcome in results.mat. Both summary
tables include the new percent row; standalone LaTeX notes were refreshed.
ADD_HEIGHT_GAP benchmarks each scenario against its own unrestricted-height city,
retaining rural utility, regional population and any horizontal boundary. No core
solver equation or tolerance changed. The full reference suite was not rerun.


## Counterfactual exports and density rows (9 September 2026)

The current Paper tables already contained Change_pct, but legacy top-level
outputs/Tables files still held baseline-only results. SAVE_RESULTS now mirrors
complete Paper/Empirical runs to top-level Tables, Figures and results.mat,
while preserving each named version. The paper master was rerun with the user's
commercial/residential FAR caps of 10 and horizontal limit of 20 km unchanged.

MATLAB checks passed: Paper and top-level CSV/XLSX exports have five columns;
their percentage changes and undefined-value patterns match the MATLAB table;
LaTeX has both Counterfactual and Change columns; the top-level CSV exactly
matches the Paper CSV. All three versions of the table (Paper, Empirical and
latest) omit the density-disamenity income-loss and wage-share rows, retaining
the density amenity index. There are 26 outcome rows. Empirical tables were
refreshed from their saved results without re-estimating that city. Paper and
latest figures and saved model results were refreshed through the full master.
