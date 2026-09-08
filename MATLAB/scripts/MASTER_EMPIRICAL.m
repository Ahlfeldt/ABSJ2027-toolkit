%% ABSJ2027: Empirically quantified city
% Edit the three input sections, then run this entire script.
% Source directories are never read or written by this standalone toolkit.
toolkit = fileparts(fileparts(mfilename('fullpath'))); % Locate the MATLAB folder independently of the working directory.
addpath(fullfile(toolkit,'functions')); % Make the separate function files available.

%% 1. Starting parameters: paper values before empirical calibration
params = struct(); % Reset inputs when rerunning the master script.
params.alpha_R = 0.66; % Non-housing expenditure share; housing receives 0.34.
params.alpha_C = 0.85; % Labor share; commercial floor space receives 0.15.
params.beta_R = 0; % Additional population elasticity of residential amenity (off in paper).
params.beta_dens_R = -0.10535545480050244; % Estimated density elasticity of residential amenity.
params.beta_C = 0.03; % Population elasticity of commercial productivity.
params.tau_R = 0.016; % Residential amenity decay per km beyond the 1-km core.
params.tau_C = 0.014; % Commercial productivity decay per km beyond the 1-km core.
params.x_core_R = 1; % Radius of the flat residential amenity core, km.
params.x_core_C = 1; % Radius of the flat commercial productivity core, km.
params.omega_R = 0.07; % Residential rent elasticity with respect to height.
params.omega_C = 0.03; % Commercial rent elasticity with respect to height.
params.theta_C = 0.5; % Commercial unit construction-cost elasticity with respect to height.
params.theta_R = params.theta_C+0.05; % Paper baseline; counterfactual theta changes are independent.
params.c_R = 150; % Residential construction-cost scale; floor-space calibration scales c_R and c_C together.
params.c_C = 150; % Commercial construction-cost scale; the initial c_R/c_C ratio is preserved during calibration.
params.a_bar_R = 2; % Fundamental residential amenity.
params.a_bar_C = 2; % Fundamental commercial productivity.
params.r_a = 50; % Agricultural land rent, model units per unit land.
params.ell = 0.5; % Developable fraction of geographic land.
params.zeta = 6.4; % Preference heterogeneity; migration elasticity is zeta*(1-urban_share).
params.T = 2.9605069278556773; % Estimated model tall-height threshold, effective floors.
params.S_bar_C = Inf; % Commercial height/FAR limit: floor space per unit developable land; Inf = unrestricted.
params.S_bar_R = Inf; % Residential height/FAR limit: floor space per unit developable land; Inf = unrestricted.
% Either finite S_bar overrides targets.height_gap; both sector caps then apply exactly as entered.
% Example: params.S_bar_R = 5 permits at most 5 m^2 of floors per m^2 of developable land, not necessarily 5 storeys.
params.x1_max = inf; % Optional urban growth boundary in km; Inf reproduces the paper.

%% 2. Empirical baseline targets
targets = struct(); % Reset optional inputs so switching scripts cannot leave stale targets.
targets.population = 3000000; % Urban population.
targets.floor_space_per_resident = []; % Quantity target disabled because residential rent is targeted instead.
% Optional experimental calibration: enter a positive m^2-per-resident target to scale both costs; this changes the economic baseline.
targets.residential_rent = 240; % Alternative to floor_space_per_resident: average residential rent, currency per m^2 per YEAR.
% Example: 240 means 240 USD/m^2/year if currency is USD; requires a positive targets.wage.
% Choose ONE housing target only. Both adjust a common construction-cost multiplier, preserving c_R/c_C.
targets.total_urban_area = pi*18^2; % Optional geographic urban area in km^2, INCLUDING non-developable land; calibrates params.r_a.
% Example: 1000 targets 1000 km^2 within the urban fringe. Can accompany either housing target.
targets.cbd_far = 10; % Central CBD FAR; calibrates a common multiplier on tau_R and tau_C, preserving their ratio.
% FAR is m^2 of floors per m^2 of developable land at the centre, not the CBD-wide mean.
targets.urban_share = 0.50; % Urbanization rate: urban population as a share of total city plus hinterland population, between 0 and 1.
targets.height_gap = []; % Height-gap calibration is disabled: the paper threshold T is not recalibrated for these empirical parameters.
% Keep [] here. The realized gap relative to T is reported descriptively; set manual FAR limits for policy experiments.
% Height gap = share of potential floor space above T that is unrealized.
% With no finite manual cap: 1 = no floor space above T; [] keeps both sectors unrestricted. Do not enter 50 for 50%.
% Used only when BOTH S_bar values are Inf. Any finite manual height/FAR limit supersedes this target.

% Optional annual wage: sets the monetary units of tables and figures.
targets.wage = 75000; % Average ANNUAL wage per urban worker; [] retains model monetary units.
targets.currency = 'USD'; % Currency label, for example 'EUR' or 'USD'.
% Example: targets.wage = 40000; targets.currency = 'EUR';
% If enabled, both scenarios use the baseline conversion; rents are per m^2 per year.
% Monetary conversion does not calibrate physical floor space or building heights.

%% 3. Optional counterfactual: uncomment any combination of distinct inputs
changes = struct(); % Empty means solve and display the baseline only.
% changes.pct.a_bar_C = 10; % Increase commercial productivity by 10 percent.
% changes.pct.c_R = -10; % Reduce the residential construction-cost scale by 10 percent.
% changes.set.theta_C = 0.6; % Set commercial cost of height to the illustrative counterfactual.
% changes.set.theta_R = 0.65; % Set residential cost of height separately.
changes.set.S_bar_C = 7.5; % Limit commercial height / floor area ratio to 7.5.
changes.set.S_bar_R = 7.5; % Limit residential height / floor area ratio to 7.5.
changes.set.x1_max = 15; % Prohibit urban development beyond 15 km.

%% Create, quantify, solve, and display
options = NUMERICS(); % Keep numerical controls separate from economic inputs.
options.spacing = 0.005; % A 5-metre radial grid resolves land-use boundaries under the steeper decay parameters.
fund = CREATE_CITY(params,options); % Generate the radial grid and uniform local fundamentals.
baseline = QUANTIFY(params,fund,targets,options); % Infer regional population, rural utility, and optional height caps.
counterfactual = COUNTERFACTUAL(baseline,changes); % Skip the second solve when changes is empty.
[statistics,figures] = RESULTS(baseline,counterfactual); % Display aggregate statistics and spatial profiles.
SAVE_RESULTS(fullfile(toolkit,'outputs','Empirical'),baseline,counterfactual,statistics,figures); % Refresh Figures (PNG/PDF), Tables (TEX/CSV/XLSX), and full MAT results.





