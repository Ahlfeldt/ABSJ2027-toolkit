# Source map and implementation decisions

The original QuantitativeModel source and Overleaf paper were read only.
Source hashes are recorded in SOURCE_SHA256.json. The toolkit runs independently
of these source folders.

| Toolkit function | Source / role | Changes |
| --- | --- | --- |
| CREATE_CITY | BASEDATA spatial setup | Function inputs and outputs; no clear, globals, saves, or estimation placeholders |
| NUMERICS | BASEDATA numerical settings | Explicit options; original grid and damping defaults |
| SOLVER | Functions/SOLVER.m | Same arithmetic; growth-boundary mask; core radii exposed at original defaults; comments |
| EQFIND | Functions/EQFIND.m | Explicit warm starts, unchanged updates/damping, failure/domain checks |
| FINDUtilde | Functions/FINDUtilde.m | Explicit state; return before final unmatched primitive update; failure check |
| HG_obj | Functions/HG_obj.m | Same excess-height objective; independent theta_R/theta_C; Inf cap; invalid-cap and no-tall checks |
| QUANTIFY | SIMULATION_CFT_flex calibration | One city; direct-cap mode; target-consistent initial guess; exact endpoints; fit checks |
| APPLY_CHANGES | New interface | set/pct; no silent parameter coupling or compounding |
| COUNTERFACTUAL | ILLUSTRATION / SIMULATION_CFT_flex | Saved baseline and optional changes; no recalibration |
| PACK_RESULT | SOLVER scalars plus identities | GDP, wage bill, density, amenity, urban share, diagnostics |
| GHEIGHT / GBIDRENT / GLANDRENT | Existing presentation roles | Plot saved solutions, without resetting fundamentals or resolving |
| PLOT_PROFILE | New shared graphics helper | Baseline/comparison profiles and land-use strips |
| RESULTS | Existing reporting role | Explicit input, levels/changes table, graph calls |
| SAVE_RESULTS | Output operations | Optional CSV/MAT/PNG export |
| VALIDATE_INPUTS | New guard | Mathematical domains, gradient ordering, input shapes |
| VALIDATE_TOOLKIT | New regression suite | Model, interface, plots, scenarios, and source comparisons |

## Omitted machinery

MMC, MM, ELAST, and HEAT support estimation or diagnostic grids. Their estimation
uses F_tall and log(1+X), whereas height-gap inversion uses F_tallE. These measures
are not interchangeable. The toolkit starts with estimated constants and does not
re-estimate them. Parallel loops, callbacks, bootstrap scripts, Stata preparation,
global aggregation, temporary-file moving, and batch logging are not dependencies.

## Precise implementation choices

- Default beta_dens_R and T come at full precision from BASE_cost.mat. Some original
  illustrative grids instead load BASE.mat with zero density disamenity; this
  toolkit deliberately uses the estimated baseline.
- Runtime functions do not retrieve or assign base-workspace variables. Only the
  optional validation of the legacy source initializes its old workspace interface.
- Quantification initializes U_tilde = 0.2^zeta (1-mu)/mu. This changes the starting
  guess, not the calibration targets or equilibrium equations.
- The returned rural primitive is the one used in the returned equilibrium. The
  source performs one additional damped update before returning.
- Inf replaces the original no-limit height sentinel 999.
- Exact 0/1 height-gap endpoints replace approximate 1%/99% shortcuts; interior
  targets are checked within 0.01 absolute gap tolerance. A positive gap with zero
  unrestricted tall development is rejected.
- No silent population or urbanization winsorization is applied to user targets.
- x_core_C and x_core_R replace hard-coded 1 km, with identical defaults.
- The growth-boundary assignment occurs before x0/x1 computation, so urban
  quantities and density use the restricted allocation. Rural land remains.
- Graphs use saved radial solutions. Land-bid curves outside occupied zones show
  potential use; the land-use strips show actual allocations under the policy.

## Progress reporting

`STATUS.m` is a separate display helper. `QUANTIFY`, `HG_obj`, `FINDUtilde`,
`EQFIND`, and `COUNTERFACTUAL` report calibration and solution activity through
it. Long iterations issue time-limited updates; `NUMERICS.verbose = false`
suppresses reporting. Timers and messages do not enter numerical updates or
convergence criteria. Height-gap inputs use fractions; progress output uses
percent and percentage points, explicitly labelled.

## Export helpers

SAVE_RESULTS writes PNG and vector PDF figures to Figures, and summary tables to
Tables in CSV, XLSX, and LaTeX formats. WRITE_TABLE_TEX and TEX_ESCAPE are separate
functions for publication-table formatting and safe labels. The master refreshes
these outputs automatically; full equilibrium structures remain in results.mat.
CSV/XLSX store numeric values; LaTeX displays six significant digits.

## Display units

REPORT_UNITS derives a single monetary conversion from the baseline annual wage
target. REPORT_CITY converts temporary display copies and calculates resident-
weighted floor space and housing expenditure. RESULTS, GBIDRENT, and GLANDRENT use
these helpers. QUANTIFY and COUNTERFACTUAL retain conversion metadata alongside
raw model outcomes. Core SOLVER, EQFIND, and inversion arithmetic are unchanged.

## Manual height/FAR limits take precedence

QUANTIFY checks for a finite S_bar_C or S_bar_R before height-gap inversion.
Either finite cap selects direct-cap mode for both sectors. Population and
urbanization are still matched; the overridden height-gap target is not fitted
or checked. The underlying SOLVER and HG_obj equations are unchanged. Limits are
effective floor-area ratios per unit developable land, not literal storey counts.

## Monetary equivalent of commuting

REPORT_CITY calculates the resident-weighted loss share using
-expm1(-tau_R*max(0,D-x_core_R)), then multiplies by the scenario wage and baseline
reporting conversion. RESULTS displays the monetary loss per resident and its
percentage of wages. The inherited CC statistic and all solver equations remain
unchanged. The new statistic is an income equivalent holding rents and other
amenities fixed, not transport expenditure or a complete welfare decomposition.

## Residential floor-space calibration

QUANTIFY is now a dispatcher: an empty floor_space_per_resident target calls
QUANTIFY_CITY (the previous quantification routine at fixed c_R and c_C). A positive
target calls MATCH_FLOORSPACE, which adjusts a common multiplier for c_R and c_C and repeats QUANTIFY_CITY.
Optional explicit warm starts pass into FINDUtilde and HG_obj; absent a warm
start, the original initialization is preserved. No solver equation changes.
The initial multiplier correction predicts the residential scaling
k_new/k_old = (floor_space_actual/floor_space_target)^(1+theta_R), followed
by numerical re-solution and a 0.1% relative target check. Changes are bounded
per iteration and calibration fails visibly after 20 iterations if unmatched.
The reference validation disables the extra target before comparing original
paper illustrative outcomes; toolkit-baseline checks retain the extra moment.

## Density disamenity income equivalent

REPORT_UNITS fixes the reference density at the baseline N/AREA. REPORT_CITY
uses -expm1(beta_dens_R*log(density/reference_density)) for the loss share and
multiplies by the scenario wage using the baseline currency conversion. This
normalization is invariant to the unit of area. If beta_dens_R changes, the
statistic isolates the density effect at the scenario's elasticity. The raw
DD index and all model equations remain unchanged. Zero baseline loss makes
percentage changes from baseline undefined; output levels and wage shares remain
available, with negative losses denoting benefits.

The common multiplier preserves the supplied c_R/c_C ratio. Both costs are
retained in baseline diagnostics and inherited by counterfactuals. Wage and
utility warm starts predict responses in both sectors; actual equilibria and
moment fits are always solved numerically.


## Alternative housing target and urban-area inversion

QUANTIFY validates mutually exclusive floor-space and residential-rent targets.
A rent target requires a wage target to define annual currency units. With rent
or area active, MATCH_CITY_TARGETS minimizes squared log moment errors using
fminsearch. CITY_TARGET_OBJECTIVE is a separate function file; it applies a
common cost multiplier for the selected housing target and a positive r_a
multiplier for geographic area, then calls QUANTIFY_CITY. Thus the existing
population, urbanization and height-gap inversion remains inside each trial.
Final proportional errors must not exceed 0.5%; diagnostics store these errors,
starting costs, starting agricultural rent, and the common cost multiplier.
No SOLVER, EQFIND, or counterfactual equilibrium equation was changed.

The starting city supplies moment-based multiplier guesses and scaled wage/utility
warm starts. STOP_CITY_TARGET_SEARCH ends refinement when the squared log-error
objective guarantees errors below 0.2%; final verification still applies.


## Central CBD FAR and separate workflows

QUANTIFY validates optional cbd_far; MATCH_CITY_TARGETS adds one common tau
log multiplier and initializes it after fitting the other optional targets.
CITY_TARGET_OBJECTIVE applies it to both taus and adds the central S_x_C(1)
moment. STOP_CITY_TARGET_SEARCH and final checks include the new residual.
No equilibrium equation was changed. MASTER_PAPER and MASTER_EMPIRICAL contain
complete independent input sections and write to distinct Paper/Empirical
output directories; MASTER is a compatibility wrapper for MASTER_PAPER.


## Height-gap calibration versus reported outcome

Height-gap calibration is restricted to the paper structural parameterization:
the estimated threshold T belongs to that height scale. The empirical master
sets targets.height_gap=[]; supplying an active gap together with optional
physical calibration, or changed structural parameters, raises an error.
Finite manual caps retain precedence over an otherwise ignored gap input.

The summary table now reports Height gap (relative to T), in percent, for each
scenario. ADD_HEIGHT_GAP compares realized excess floor space above T with the
same scenario solved without vertical limits, retaining all other primitives,
rural utility, regional population and the horizontal growth boundary. It uses
1-F_tallE/F_tallE_unrestricted. A missing unrestricted tall-development denominator
is undefined (NaN / --), not zero. In empirical cities this is a descriptive
statistic at the retained T, not an empirically calibrated paper height gap.
QUANTIFY and COUNTERFACTUAL store the outcome; RESULTS supports older saved cities.
The extra unrestricted solve occurs after calibration, not in each optional trial.
