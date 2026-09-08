function report = VALIDATE_TOOLKIT(source_root, report_folder)
%VALIDATE_TOOLKIT Run regression and behavior checks without editing sources.
% Optional source_root is the original QuantitativeModel folder, read-only.
% report_folder receives validation artifacts; default is MATLAB/outputs/validation.
matlab_root = fileparts(fileparts(mfilename('fullpath'))); % Locate this standalone toolkit.
if nargin < 1, source_root = ''; end % Source-independent checks work for public users.
if nargin < 2, report_folder = fullfile(matlab_root,'outputs','validation'); end % Keep generated artifacts out of source folders.
if ~isfolder(report_folder), mkdir(report_folder); end % Create the selected validation destination.
old_visibility = get(groot,'DefaultFigureVisible'); % Preserve the caller's graphics preference.
cleanup_visibility = onCleanup(@() set(groot,'DefaultFigureVisible',old_visibility)); % Restore that preference even after a failure.
set(groot,'DefaultFigureVisible','off'); % Validate figures without interrupting the desktop.
timer = tic; report = struct(); report.checks = {}; % Start a machine-readable validation record.
run(fullfile(matlab_root,'scripts','MASTER.m')); % Exercise the complete baseline-only user workflow.
assert(isempty(counterfactual)); % No empty counterfactual solve or comparison output.
assert(width(statistics)==3 && numel(figures)==3); % Baseline table and all three graphs must exist.
assert(baseline.diagnostics.population_error < baseline.options.tol_U); % Enforce the population target.
assert(max([baseline.diagnostics.labor_error,baseline.diagnostics.housing_error]) < 0.005); % Independently check market clearing.
assert(abs(baseline.scalist.GDP-baseline.scalist.y*baseline.scalist.N/baseline.params.alpha_C)<1e-8); % GDP equals model output.
report.checks{end+1} = 'Master baseline-only workflow, graphics, population, markets, and GDP'; % Record passed checks only.
report.baseline = baseline.scalist; % Preserve baseline numeric benchmarks.
SAVE_RESULTS(fullfile(report_folder,'baseline'),baseline,[],statistics,figures); % Save graphs for visual inspection.
close(figures); % Close only this validation's figures.
assert(isempty(COUNTERFACTUAL(baseline))); % Omitted changes must also skip the second solve.
assert(isempty(COUNTERFACTUAL(baseline,struct('set',struct(),'pct',struct())))); % Empty operation blocks mean no experiment.
zero.pct.a_bar_C = 0; unchanged = COUNTERFACTUAL(baseline,zero); % A specified zero shock is a valid comparison.
assert(isequaln(unchanged.scalist,baseline.scalist)); % Same converged state should be reproduced exactly.
report.checks{end+1} = 'Omitted changes, empty changes, and exact zero-shock identity'; % Confirm baseline semantics.

if isfield(targets,'floor_space_per_resident') && ~isempty(targets.floor_space_per_resident)
    fit_tolerance = 0.001; % Floor-space-only matching tolerance.
    if isfield(baseline.diagnostics,'optional_target_tolerance'), fit_tolerance = baseline.diagnostics.optional_target_tolerance; end % Joint targets allow for the spatial grid.
    assert(baseline.diagnostics.floor_space_error<fit_tolerance); % The user-facing baseline must fit its additional housing-quantity moment.
    report.floor_space_calibration = baseline.diagnostics; % Retain the new toolkit calibration separately from paper reference tests.
end
targets.cbd_far = []; % Paper reference experiments keep the supplied spatial decay parameters.
targets.residential_rent = []; targets.total_urban_area = []; % Disable optional rent and area inversion for paper-reference experiments.
targets.floor_space_per_resident = []; % Paper reference experiments use the supplied cost normalization without the optional housing target.
baseline = QUANTIFY(params,fund,targets); % Recover the replication baseline before comparing its illustrative experiments.
report.paper_baseline = baseline.scalist; % Distinguish reference outcomes from the user's calibrated toolkit baseline.

cost.set.theta_C = 0.6; cost.set.theta_R = 0.65; % Paper's illustrative construction-cost experiment.
more_cost = COUNTERFACTUAL(baseline,cost); % Solve without re-inverting rural utility.
ban.set.S_bar_C = baseline.params.T; ban.set.S_bar_R = baseline.params.T; % Ban floor space above the tall-height threshold.
no_tall = COUNTERFACTUAL(baseline,ban); % Second paper experiment.
higher_params = baseline.params; higher_params.theta_C = 0.6; higher_params.theta_R = 0.65; % Alternative baseline with higher costs.
higher = QUANTIFY(higher_params,fund,targets); % Recalibrate its population as in ILLUSTRATION.
higher_ban = COUNTERFACTUAL(higher,ban); % Third illustrative experiment has its own reference city.
fields = {'N','AREA','CC','p_R','p_C','A_tilde_C','y','LV','U_bar','V'}; % Rows of the supplied illustrative table.
expected = [-9.1 -20.1 -14.6;15.6 16.0 8.7;2.6 7.9 5.6;-0.4 -15.0 -12.1;7.5 0.8 -2.4;-0.9 -5.1 -4.3;-2.5 -6.6 -4.9;-0.4 3.7 2.9;-2.8 -6.2 -4.5;-1.4 -2.8 -2.1]; % Rounded replication reference outputs.
actual = zeros(size(expected)); scenarios = {more_cost,no_tall,higher_ban}; bases = {baseline,baseline,higher}; % Pair each experiment with its correct baseline.
for j = 1:3
    for k = 1:numel(fields)
        actual(k,j) = 100*(scenarios{j}.scalist.(fields{k})/bases{j}.scalist.(fields{k})-1); % Compute comparable percentage changes.
    end
end
assert(max(abs(actual-expected),[],'all') < 0.6); % Allow rounding and warm-start differences, but reject meaningful changes.
report.illustrative_fields = fields; report.illustrative_percent = actual; % Save full-precision results.
report.illustrative_max_deviation_pp = max(abs(actual-expected),[],'all'); % Report deviation from rounded saved results.
report.checks{end+1} = 'All three paper illustrative experiments within 0.6 percentage points'; % Record the explicit tolerance.
[comparison,comparison_figs] = RESULTS(baseline,no_tall); % Exercise two-scenario reporting.
assert(width(comparison)==5); % Require both levels and percentage changes.
SAVE_RESULTS(fullfile(report_folder,'height_ban'),baseline,no_tall,comparison,comparison_figs); % Save comparison figures for visual review.
close(comparison_figs); % Release only figures created here.

boundary.set.x1_max = 25; constrained = COUNTERFACTUAL(baseline,boundary); % A binding boundary inside the baseline fringe.
assert(constrained.scalist.x1 <= 25 && ~any(constrained.varlist.URBAN(constrained.fund.D>25))); % No urban use may escape the boundary.
assert(abs(constrained.scalist.AREA-pi*constrained.scalist.x1^2*constrained.params.ell)<1e-8); % Density denominator follows the constrained city.
report.boundary = constrained.scalist; % Retain the boundary experiment benchmark.
nonbinding.set.x1_max = 90; free_boundary = COUNTERFACTUAL(baseline,nonbinding); % Boundary well beyond this city.
assert(isequaln(free_boundary.scalist,baseline.scalist)); % Nonbinding regulation has no effect.
joint.set = struct('x1_max',25,'S_bar_C',5,'S_bar_R',5); % Joint horizontal and vertical limits.
joint_city = COUNTERFACTUAL(baseline,joint); % Solve both regulations together.
assert(joint_city.scalist.x1<=25 && max(joint_city.varlist.S_x_C,[],'omitnan')<=5 && max(joint_city.varlist.S_x_R,[],'omitnan')<=5); % Both constraints must bind only as specified.
report.checks{end+1} = 'Binding, nonbinding, and joint growth-boundary/height-cap experiments'; % Confirm the model extension.

interior_targets = targets; interior_targets.height_gap = 0.5; % Test the nested cap/rural-utility inversion.
interior = QUANTIFY(params,fund,interior_targets); % Recover a nontrivial common cap.
assert(abs(interior.diagnostics.height_gap-0.5)<interior.options.hg_tol); % Require achieved gap fit.
assert(interior.diagnostics.population_error<interior.options.tol_U); % Simultaneously retain population fit.
report.interior_height_gap = interior.diagnostics; % Preserve inversion accuracy.
bounded_params = params; bounded_params.x1_max = 25; % Calibrate while holding a growth boundary fixed.
bounded = QUANTIFY(bounded_params,fund,interior_targets); % Height-gap benchmark must retain the same boundary.
assert(bounded.scalist.x1<=25 && abs(bounded.diagnostics.height_gap-0.5)<bounded.options.hg_tol); % Check both baseline targets.
direct_targets = targets; direct_targets.height_gap = []; % Switch to direct-cap baseline mode.
direct_params = params; direct_params.S_bar_C = 8; direct_params.S_bar_R = 5; % Allow different baseline sector caps.
direct = QUANTIFY(direct_params,fund,direct_targets); % Invert only rural utility.
assert(direct.params.S_bar_C==8 && direct.params.S_bar_R==5); % Direct caps cannot be overwritten by calibration.
priority_targets = targets; priority_targets.height_gap = 0.5; % Leave a conflicting empirical gap in place.
priority = QUANTIFY(direct_params,fund,priority_targets,baseline.options); % Explicit finite caps must win.
assert(isequaln(priority.scalist,direct.scalist) && isempty(priority.targets.height_gap)); % Same equilibrium as explicit direct-cap mode.
assert(priority.diagnostics.height_gap_overridden && priority.requested_targets.height_gap==0.5); % Keep an audit of the ignored target.
assert(~isfield(priority.diagnostics,'height_gap')); % Do not claim the ignored gap was matched.

report.checks{end+1} = 'Interior height-gap inversion, boundary-conditional inversion, and direct-cap mode'; % Cover both quantification interfaces.

shock.pct.a_bar_C = 10; first = COUNTERFACTUAL(baseline,shock); second = COUNTERFACTUAL(baseline,shock); % Repeat exactly the same experiment.
assert(first.params.a_bar_C==1.1*baseline.params.a_bar_C && isequaln(first.scalist,second.scalist)); % Percentage changes never compound.
assert(first.params.U_tilde==baseline.params.U_tilde && first.params.N_bar==baseline.params.N_bar); % Preserve baseline migration primitives.
single.set.theta_C = 0.6; [single_params,~,~] = APPLY_CHANGES(baseline,single); % Inspect a one-sector override.
assert(single_params.theta_R==baseline.params.theta_R); % Do not silently couple sector parameters.
report.checks{end+1} = 'Repeatable percentage changes, fixed baseline primitives, and independent sector parameters'; % Confirm experiment semantics.
invalids = {struct('set',struct('a_bar_C',2),'pct',struct('a_bar_C',10)),struct('set',struct('misspelled_parameter',2)),struct('pct',struct('x1_max',10)),struct('set',struct('theta_C',0.01))}; % Common user errors.
for k = 1:numel(invalids)
    rejected = false; % Reset for this invalid specification.
    try, APPLY_CHANGES(baseline,invalids{k}); catch, rejected = true; end % Each invalid input must fail visibly.
    assert(rejected); % Never silently ignore invalid changes.
end
report.checks{end+1} = 'Duplicate, unknown, infinite-percentage, and invalid-parameter rejection'; % Confirm input guards.

if ~isempty(source_root)
    reference_dir = fullfile(report_folder,'reference_helpers'); % Copies are written only in the chosen validation output folder.
    if ~isfolder(reference_dir), mkdir(reference_dir); end % Do not touch the original replication.
    for name = {'SOLVER','EQFIND','FINDUtilde'}
        content = fileread(fullfile(source_root,'Functions',[name{1} '.m'])); % Read the original source verbatim.
        content = regexprep(content,'\<SOLVER\s*\(','REFERENCE_SOLVER('); % Isolate function lookup in the copied code.
        content = regexprep(content,'\<EQFIND\s*\(','REFERENCE_EQFIND('); % Preserve original implementation under a unique name.
        content = regexprep(content,'\<FINDUtilde\s*\(','REFERENCE_FINDUtilde('); % Preserve the original inversion implementation.
        file = fopen(fullfile(reference_dir,['REFERENCE_' name{1} '.m']),'w'); % Open only the validation copy.
        fwrite(file,content); fclose(file); % Write and close the isolated reference helper.
    end
    addpath(reference_dir); cleanup_path = onCleanup(@() rmpath(reference_dir)); % Remove temporary lookup paths afterwards.
    [a,b,c,d,e] = SOLVER(baseline.params,fund,baseline.initial.y,baseline.initial.U_bar,baseline.initial.density); % Evaluate the toolkit mapping.
    [ar,br,cr,dr,er] = REFERENCE_SOLVER(baseline.params,fund,baseline.initial.y,baseline.initial.U_bar,baseline.initial.density); % Evaluate the original mapping with identical inputs.
    assert(isequaln(a,ar)&&isequaln(b,br)&&isequaln(c,cr)&&isequaln(d,dr)&&isequaln(e,er)); % Require exact identity at x1_max=Inf.
    reference_params = baseline.params; reference_params.U_tilde = 0.2^params.zeta*(1-targets.urban_share)/targets.urban_share; % Use the same cold-start rural guess.
    assignin('base','y',1); assignin('base','U_bar',0.2); assignin('base','density',1000); % Initialize the original base-workspace interface in this validation session.
    [~,~,~,reference_scalist] = REFERENCE_FINDUtilde(reference_params,fund,baseline.options,targets.urban_share); % Run the original nested solution algorithm.
    errors = zeros(numel(fields),1); % Compare economically meaningful outputs.
    for k = 1:numel(fields), errors(k)=abs(baseline.scalist.(fields{k})/reference_scalist.(fields{k})-1); end % Relative baseline differences.
    assert(max(errors)<0.005); % Require agreement well within half a percent.
    report.reference_max_relative_error = max(errors); % Preserve observed discrepancy.
    report.checks{end+1} = 'Exact original SOLVER identity at Inf and original baseline inversion comparison'; % Record source-based regression checks.
end
report.elapsed_seconds = toc(timer); report.matlab_version = version; % Record execution context.
report.passed = true; % Set success only after every assertion passes.
file = fopen(fullfile(report_folder,'validation.json'),'w'); % Save a reviewable completion record.
fwrite(file,jsonencode(report,PrettyPrint=true)); fclose(file); % Preserve full precision and readable formatting.
fprintf('\nVALIDATION PASSED: %d check groups in %.1f seconds.\n',numel(report.checks),report.elapsed_seconds); % Clear completion marker.
end
