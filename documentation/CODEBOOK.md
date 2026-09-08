> Initial prose draft. The maintained codebook is now [CODEBOOK.tex](CODEBOOK.tex); see [CODEBOOK.pdf](CODEBOOK.pdf) for the compiled version.

# ABSJ2027 | MATLAB toolkit codebook

## The Skyscraper Revolution

Companion to the paper by Gabriel M. Ahlfeldt, Nathaniel Baum-Snow, and Rémi Jedwab. Initial implementation, 8 September 2026.

Following the AB2022 toolkit approach, this codebook defines the economic objects, states the equilibrium conditions, and describes the numerical algorithms in language-independent pseudocode. It covers a stylized city and optional counterfactuals, rather than the full empirical replication. The algorithms are also intended for the future Python implementation.

## Quick start

Open either MATLAB/scripts/MASTER_PAPER.m or MATLAB/scripts/MASTER_EMPIRICAL.m and run the entire script. Edit its three sections: baseline parameters and fundamentals, empirical targets, and optional counterfactual changes. Defaults produce approximately three million urban residents, urbanization 0.5, and no height limits. Empty changes display only the baseline.

```text
Set baseline parameters and fundamentals.
Set population, urbanization, and optional height-gap targets.
Specify absolute / percentage counterfactual changes, if any.
CREATE_CITY -> QUANTIFY -> optional COUNTERFACTUAL -> RESULTS
Optionally SAVE_RESULTS to a chosen output folder.
```

## What calibration identifies

Regional population is urban population divided by the target urban share. Rural utility is inverted to reproduce that share. A supplied height-gap target also identifies a common residential and commercial height cap. Productivity and amenities are not separately estimated from those targets. Other primitives remain at the user's chosen values.

Editing baseline inputs and rerunning recalibrates the city. A counterfactual preserves calibrated fundamentals except those explicitly overridden. Regional population and rural utility normally remain fixed while urban population responds.

## Units and scope

Distances are kilometres, developable area is square kilometres, and heights are effective floors per unit developable land. The threshold near three effective floors is the paper's counterpart to empirically tall buildings, not a literal three-storey planning rule. GDP is model urban output, yN/alpha_C. Wages, rents, and GDP are in model units, not independently calibrated currency amounts.

The model is circular and monocentric. The optional growth boundary extends the paper and is disabled by x1_max = Inf. Python and shared-data folders are reserved for later work. No replication folder or external dataset is required to run this toolkit.

<!-- PAGE -->
# 1 | Inputs and notation

| MATLAB field | Default | Meaning |
| --- | --- | --- |
| alpha_R / alpha_C | 0.66 / 0.85 | Non-housing spending / labor shares |
| beta_dens_R | -0.1053554548 | Density elasticity of residential amenity |
| beta_R / beta_C | 0 / 0.03 | Population elasticities of amenity / productivity |
| tau_R / tau_C | 0.016 / 0.014 | Decay per km beyond each core |
| x_core_R / x_core_C | 1 / 1 | Flat amenity / productivity core radii, km |
| omega_R / omega_C | 0.07 / 0.03 | Height elasticities of floor-space rent |
| theta_R / theta_C | 0.55 / 0.5 | Height elasticities of unit construction cost |
| c_R / c_C | 150 / 150 | Construction-cost scales |
| a_bar_R / a_bar_C | 2 / 2 | Fundamental amenity / productivity |
| r_a | 50 | Agricultural land rent |
| ell | 0.5 | Developable share of geographic land |
| zeta | 6.4 | Preference heterogeneity |
| T | 2.9605069279 | Tall-height threshold, effective floors |
| S_bar_R / S_bar_C | Inf / Inf | Direct caps; any finite cap overrides the gap target |
| x1_max | Inf | Maximum urban radius, km |
| a_rand_R / a_rand_C | Vectors of ones | Positive local multipliers in fund |
| N_bar | population / urban_share | Calibrated city plus hinterland population |
| U_tilde | Inverted | Rural utility raised to power zeta |

The paper's beta^R is beta_dens_R in MATLAB. Below, beta_D denotes this density parameter and beta_P denotes the additional population term beta_R (zero in the paper). The paper rounds the housing share to 0.33; the replication uses 1 - alpha_R = 0.34. This toolkit preserves the latter.

| Empirical target | Default | Meaning |
| --- | --- | --- |
| population | 3,000,000 | Positive urban population |
| urban_share | 0.5 | Urban fraction, strictly between zero and one |
| height_gap | 0 | Fraction unrealized, zero to one; [] uses direct caps |

Estimated constants are stored at full precision. theta_R starts at theta_C + 0.05, but counterfactual changes are independent. Changing parameters does not trigger re-estimation. Exact closed-city zeta = 0 is not implemented; supported values satisfy zeta > 0.

<!-- PAGE -->
# 2 | Local equilibrium conditions

Write R for residential and C for commercial use. Available land at radius x is dL = 2πell x dx. The equilibrium state comprises wage y, urban utility U_bar, and density Dens. Rural utility itself is U_tilde^(1/zeta).

```text
N = N_bar U_bar^zeta / (U_bar^zeta + U_tilde)
Dens = N / (π ell x1²)
```

The migration elasticity is zeta(1 - N/N_bar). The local productivity and amenity shifters exclude the vertical component captured separately by omega:

```text
A_C(x) = a_rand_C(x) a_bar_C N^beta_C
         × exp[-tau_C max(0, x - x_core_C)]
A_R(x) = a_rand_R(x) a_bar_R N^beta_P Dens^beta_D
         × exp[-tau_R max(0, x - x_core_R)]
```

Define q_C and q_R as a_x_C and a_x_R in code. These are demand shifters before dividing by 1 + omega: q_U is (1 + omega_U) times the paper's height-invariant average-rent shifter.

```text
q_C(x) = A_C(x)^[1/(1-alpha_C)] y^[alpha_C/(alpha_C-1)]
q_R(x) = [A_R(x) y / U_bar]^[1/(1-alpha_R)]
```

Developers face cost c_U S^(1 + theta_U). Their optimal height, constrained choice, and land bid are:

```text
S_star_U(x) = [q_U(x)/{c_U(1+theta_U)}]^[1/(theta_U-omega_U)]
S_tilde_U(x) = min(S_star_U(x), S_bar_U)
r_U(x) = q_U(x) S_tilde_U(x)^(1+omega_U)/(1+omega_U)
         - c_U S_tilde_U(x)^(1+theta_U)
```

Require theta_U > omega_U. Within the permitted urban region, land goes to the highest commercial, residential, or agricultural bid. Beyond x1_max, agriculture is imposed. Realized S_U equals the constrained height in locations assigned to use U; other locations are excluded from that sector's aggregates.

```text
p_bar_U(x) = q_U(x) S_U(x)^omega_U / (1+omega_U)
```

The concentric ordering requires tau_C/(1-alpha_C) > tau_R/(1-alpha_R). At an interior CBD boundary, residential and commercial bids coincide. At an unconstrained fringe, residential and agricultural bids coincide. At a binding growth boundary, residential rent can remain above agricultural rent.

<!-- PAGE -->
# 3 | Market clearing and aggregate outcomes

Integrals below are evaluated as weighted sums over radial cells in MATLAB. Include only occupied land in the indicated sector. Let F_U = integral_U S_U dL.

```text
Labor demand: L(x) dx = [alpha_C/(1-alpha_C)]
                        × p_bar_C(x) S_C(x) dL / y
Housing per worker: f_bar_R(x) = (1-alpha_R) y / p_bar_R(x)
Residents: n(x) dx = S_R(x) dL / f_bar_R(x)
Clearing: integral_C L(x) dx = N = integral_R n(x) dx
```

The equilibrium updates are:

```text
y_hat = [alpha_C/(1-alpha_C)]
        × integral_C p_bar_C(x) S_C(x) dL / N
J_R = integral_R A_R(x)^[1/(1-alpha_R)] S_R(x)^(1+omega_R) dL
U_hat = {y^[1/(1-alpha_R)] J_R /
         [(1+omega_R)(1-alpha_R)yN]}^(1-alpha_R)
```

The solver iterates wage, utility, and density until all relative updates meet tolerance. Iteration exhaustion is an error, not convergence.

```text
GDP = yN/alpha_C; wage bill = yN
V = (U_tilde + U_bar^zeta)^(1/zeta)
LV = integral_C r_C dL + integral_R r_R dL + integral_A r_a dL
```

V includes city and hinterland residents. LV includes agricultural land out to the fixed regional numerical radius (100 km by default). This domain is distinct from the growth boundary and must be identical across baseline and counterfactual.

| Output | Definition |
| --- | --- |
| p_R / p_C | Mean floor-space rent weighted by residents / employment |
| CC | Resident-weighted exp(tau_R x); a cost index, not currency or time |
| DD | Dens^beta_dens_R; density component of amenity |
| HA | Resident-weighted S_R^[omega_R(1-alpha_R)] |
| F_C / F_R | Realized commercial / residential height integrated over land |
| F_tall | All floor space in cells with height above T |
| F_tallE | Integral of max(S_U - T, 0) times land; used for height gaps |

The inherited CC statistic uses x, not max(0, x - x_core_R). A finite-change utility decomposition using changes in these means is not an exact identity. Changed primitives also contribute directly to utility. The model computes U_bar from equilibrium, rather than reconstructing it from reported mean indices.

<!-- PAGE -->
# 4 | Algorithms: city creation and equilibrium

## Algorithm 1. CREATE_CITY

```text
INPUT: regional radius, grid spacing; baseline parameters
1. Create symmetric coordinates from -radius to +radius.
2. Retain the non-negative radius for model computations.
3. Compute geographic annulus areas with replication weights.
4. Initialize local amenity and productivity multipliers to one.
RETURN: fund (coordinates, areas, local multipliers)
```

## Algorithm 2. SOLVER

```text
INPUT: parameters, fund, guesses of wage, utility, and density
1. Compute urban population from urban and rural utility.
2. Compute local productivity and residential amenity shifters.
3. Compute demand shifters and unconstrained optimal heights.
4. Apply commercial and residential height caps.
5. Compute sector-specific land bids and assign land use.
6. Force all locations beyond x1_max into agricultural use.
7. Recover the CBD boundary and outermost residential radius.
8. Mask heights and rents by occupied sector.
9. Sum floor space, employment, and housing consumption.
10. Compute market-clearing wage and urban-utility updates.
11. Compute area, density, welfare, and other aggregates.
RETURN: updated guesses, local profiles, aggregate outcomes
```

## Algorithm 3. EQFIND

```text
INPUT: parameters, fund, controls, optional initial state
1. Use a warm start, or guesses (y=1, U=0.2, Dens=1000).
2. Until convergence or the iteration limit:
   a. Evaluate SOLVER at the current guesses.
   b. Clip each proposed update to 90-110% of its current value.
   c. Compute relative updates in wage, utility, and density.
   d. If all are below tolerance, retain this solved state.
   e. Otherwise update guesses using replication damping.
3. Reject nonconvergence, invalid outcomes, missing urban
   sectors, or a city truncated at the numerical grid edge.
RETURN: equilibrium state, profiles, scalars, iteration count
```

NUMERICS retains 0.001 relative equilibrium and urban-share tolerances, a maximum of 1,000 iterations, and the replication's accelerated early updates. Late weights are min(0.01, relative wage error), 0.05 for utility, and 0.25 for density. State is passed explicitly, without relying on unrelated workspace variables. Increase the grid radius and recalibrate if a city reaches its numerical edge.

<!-- PAGE -->
# 5 | Algorithms: inversion and quantification

## Algorithm 4. FINDUtilde

```text
INPUT: parameters, fund, target urban share mu, optional state
1. Solve equilibrium at the current rural-utility primitive.
2. Compare solved N/N_bar with mu.
3. If their relative difference is within tolerance, return
   the primitive actually used in this equilibrium.
4. Otherwise compute U_tilde_new = U_bar^zeta (1-mu)/mu.
5. Dampen the rural-utility update with replication weights.
6. Repeat, retaining the equilibrium as a warm start.
RETURN: rural primitive and its corresponding equilibrium
```

## Algorithm 5. HG_obj

```text
INPUT: candidate common cap HL, target gap, mu, primitives
1. Reject a cap below T or not strictly positive.
2. Set both sector height caps to HL.
3. Invert rural utility with FINDUtilde to match mu.
4. Record constrained tall floor space H = F_tallE.
5. Remove both height caps; retain rural utility, regional
   population, construction parameters, and x1_max.
6. Solve again and obtain unrestricted tall floor space H_star.
7. If H_star > 0, compute simulated gap = 1 - H/H_star.
RETURN: absolute gap error and identification status
```

## Algorithm 6. QUANTIFY

```text
INPUT: parameters, fund, population, urban share, height gap
1. Set N_bar = target population / target urban share.
2. Initialize U_tilde consistently with U_bar=0.2 and that share.
3. If either supplied cap is finite or gap is empty, retain both sector caps and skip gap matching.
4. If gap equals zero, set both caps to infinity.
5. If gap equals one, set both caps to T.
6. Otherwise minimize HG_obj over the cap using fminsearch.
7. At the selected caps, invert rural utility and solve again.
8. Verify population and, where requested, the height gap.
9. Package calibrated inputs and the solved equilibrium.
RETURN: baseline (inputs, targets, outputs, diagnostics)
```

The absolute gap tolerance is 0.01 in fractional units. If unrestricted tall floor space is zero, the gap is recorded as zero and flagged as unidentified; a positive target is rejected. Exact zero/one endpoints replace the replication's approximate 1%/99% shortcuts. Construction-cost parameters remain independently specified. Height-gap calibration always holds the growth boundary fixed.

<!-- PAGE -->
# 6 | Algorithms: counterfactuals and reporting

## Algorithm 7. APPLY_CHANGES and COUNTERFACTUAL

```text
INPUT: saved baseline; optional changes.set / changes.pct
1. If changes is omitted or empty, return no counterfactual.
2. Start with a fresh copy of the quantified baseline inputs.
3. Reject unknown fields or fields appearing in both operations.
4. For each set field, replace the baseline value.
5. For each pct field, value = baseline value (1 + X/100).
6. Reject percentages on zero or infinite baseline values.
7. Validate the resulting parameterization jointly.
8. Solve with EQFIND, warm-starting from the baseline.
9. Package the equilibrium; do not re-invert baseline targets.
RETURN: counterfactual, or empty for baseline-only mode
```

## Algorithm 8. PACK_RESULT, RESULTS, and SAVE_RESULTS

```text
INPUT: a baseline and optionally a counterfactual
1. Add GDP, wage bill, density, density amenity, urban share,
   and total floor space to the saved aggregate outcomes.
2. Record target fit and market-clearing diagnostics.
3. Build a table of baseline levels and units.
4. If supplied, append counterfactual levels and percentage
   changes: 100 (counterfactual / baseline - 1), where defined.
5. Plot saved heights, floor-space rents, and land bids.
6. Show each scenario's land-use zones and boundaries.
7. If requested, export a CSV table, MAT results, and PNGs.
RETURN: statistics and figure handles; optional saved files
```

## Example changes

```matlab
changes = struct();                 % Baseline only if left empty.
changes.pct.a_bar_C = 10;           % Productivity increases 10%.
changes.pct.c_R = -10;              % Residential cost falls 10%.
```

A smaller c_R improves construction efficiency at every height; a smaller theta_R changes how unit cost rises with height. These are different experiments. All changes refer to the saved baseline, so rerunning does not compound them.

```matlab
changes = struct();
changes.set.x1_max = 25;            % Maximum urban radius, km.
changes.set.S_bar_C = 5;            % Commercial effective-height cap.
changes.set.S_bar_R = 5;            % Residential effective-height cap.
```

Use absolute values for limits initially equal to Inf, zero-valued parameters, and elasticities where percentage language is ambiguous. No input may appear in both set and pct. To set baseline caps independently, use targets.height_gap = [] and supply params.S_bar_C and params.S_bar_R.

<!-- PAGE -->
# 7 | Implementation conventions and validation

## Preserved and changed

SOLVER retains the original arithmetic and aggregation order. The growth-boundary extension is U(D > params.x1_max) = 3, before boundary computation. The two hard-coded one-kilometre core radii are exposed as parameters with defaults of one. The original mapping is recovered at those defaults with x1_max = Inf in the regression check.

EQFIND retains the update equations, clipping, and damping. Workspace state is replaced with explicit arguments. FINDUtilde checks its target before its final update so the returned primitive corresponds to the returned equilibrium. The rural starting guess is target-consistent; baseline calibration no longer depends on an earlier estimation run.

Graphs use saved profiles; they do not call SOLVER or reset local fundamentals. Every named function has its own file in MATLAB/functions. MASTER is the only user-facing script and contains no function definitions. The anonymous fminsearch handle merely binds arguments to the separate HG_obj function.

## Numerical and reporting conventions

The annulus width is (max(x)-min(x))/number_of_points, exactly as in the replication. City area remains π ell x1², rather than the annulus sum. Boundaries have grid resolution. Keep the regional grid radius fixed across experiments because it also defines the domain of total agricultural land rent.

Spatial multipliers may be edited, but experiments should preserve the documented monocentric land-use structure. Disconnected urban systems are outside this toolkit's documented scope. The CC index uses unadjusted distance, an inherited reporting convention distinct from the flat central amenity core.

The full-city replication caps population and urbanization inputs for its empirical sample. This stylized-city toolkit does not silently cap user targets. It omits Stata preprocessing, estimation/bootstrap batches, all-city loops, and global aggregation. Structural parameter changes do not trigger re-estimation of the density elasticity or height threshold.

## Validation

VALIDATE_TOOLKIT checks the complete baseline-only master, graphics, GDP, population and market fit, unchanged counterfactuals, all three illustrative experiments, joint horizontal and vertical limits, interior height-gap calibration, direct-cap mode, independent changes, and invalid-input rejection.

With an optional read-only source path, the suite creates isolated reference copies inside the validation output folder and compares the original solver and baseline inversion. It never edits or runs the original replication scripts.

Initial validation passed eight groups in MATLAB R2024a Update 2. At the tested unrestricted state, original and toolkit SOLVER outputs were exactly identical, and the original baseline inversion matched exactly. The largest deviation from the rounded illustrative reference table was 0.095 percentage points (acceptance threshold: 0.6). The full suite took about 116 seconds; one baseline solve took about 1.3 seconds on this machine.

See VALIDATION.md for the current record, SOURCE_MAP.md for provenance and implementation decisions, and SOURCE_SHA256.json for source hashes. These checks do not establish convergence for every possible parameter combination. No GitHub publication has been performed.

