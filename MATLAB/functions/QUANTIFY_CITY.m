function baseline = QUANTIFY_CITY(params, fund, targets, options)
%QUANTIFY_CITY Match population, urbanization, and optional height gap at a fixed c_R.
if nargin < 4, options = NUMERICS(); end % Default solver settings.
if isfield(targets,'wage') && ~isempty(targets.wage), validateattributes(targets.wage,{'numeric'},{'scalar','real','finite','positive'},mfilename,'targets.wage'); end % Reject invalid optional annual wage targets before solving.
validateattributes(targets.population,{'numeric'},{'scalar','real','finite','positive'}); % Urban population target.
validateattributes(targets.urban_share,{'numeric'},{'scalar','real','finite','>',0,'<',1}); % Interior migration share.
params.N_bar = targets.population/targets.urban_share; % Infer city plus hinterland population.
initial = []; initial_utility = 0.2; % Preserve the original default starting state.
if isfield(options,'initial') && ~isempty(options.initial)
    initial = options.initial; initial_utility = initial.U_bar; % Accept an explicit warm start from floor-space calibration.
end
params.U_tilde = initial_utility^params.zeta*(1-targets.urban_share)/targets.urban_share; % Initialize rural utility consistently with the target and original urban-utility guess.
VALIDATE_INPUTS(params,fund); % Check economic inputs before calibration.
started = tic; % Track total calibration time without changing numerical inputs.
STATUS(options,'Matching empirical moments: population %.0f; urban share %.1f%%.',targets.population,100*targets.urban_share); % Explain the current task.
gap = targets.height_gap; % Requested gap; a finite manual cap takes precedence below.
manual_caps = isfinite(params.S_bar_C) || isfinite(params.S_bar_R); % Treat either finite sector cap as a direct height/FAR policy.
gap_overridden = manual_caps && ~isempty(gap); % Record whether a supplied moment has been superseded.
if manual_caps
    STATUS(options,'Using manual height/FAR limits (commercial %.4g, residential %.4g); height-gap calibration is skipped.',params.S_bar_C,params.S_bar_R); % Make precedence visible while keeping both sector settings.
    gap = []; % Skip both cap inversion and validation against the superseded gap.
end
if ~isempty(gap) && ~IS_PAPER_PARAMETERS(params)
    error('ABSJ2027:HeightGapParameterization','Height-gap calibration requires the paper parameterization associated with T. Set targets.height_gap=[]; manual caps and reported height-gap outcomes remain available.'); % Protect direct calls as well as the main dispatcher.
end
if ~isempty(gap)
    if ~isnumeric(gap) || ~isscalar(gap) || ~isreal(gap) || ~isfinite(gap) || gap < 0 || gap > 1
        error('ABSJ2027:HeightGapUnits','targets.height_gap must be a fraction between 0 and 1: enter 0.1 for 10%%, not 10. Use [] to retain supplied height caps.'); % State input units in the error itself.
    end
    STATUS(options,'Height-gap target: %.1f%% (input fraction %.4g).',100*gap,gap); % Display both conventions explicitly.
    if gap == 0
        STATUS(options,'Zero height gap: using unrestricted heights.'); % Explain the endpoint shortcut.
        cap = Inf; % No vertical restrictions in the baseline.
    elseif gap == 1
        if params.T <= 0, error('ABSJ2027:HeightGap','A full height gap requires a positive tall-height threshold.'); end % Retain positive city buildings.
        STATUS(options,'Full height gap: setting both height caps to the tall-height threshold.'); % Explain the endpoint shortcut.
        cap = params.T; % Ban floor space above the tall-height threshold.
    else
        STATUS(options,'Searching for a height cap; each trial matches urbanization and solves an unrestricted-height comparison.'); % Explain why inversion takes longer.
        objective = @(HL) HG_obj(params,fund,options,targets.urban_share,gap,HL); % Named economic objective, with only argument binding here.
        search_options = optimset('TolFun',options.hg_tol,'TolX',0.01,'MaxIter',options.hg_max_iter,'MaxFunEvals',options.hg_max_evals,'Display','off'); % Replication search controls.
        [cap,~,exitflag] = fminsearch(objective,max(params.T,0.01),search_options); % Recover the common cap.
        if exitflag <= 0, error('ABSJ2027:HeightGap','Height-cap search did not converge.'); end % Reject exhausted searches.
    end
    params.S_bar_C = cap; % Apply the calibrated commercial cap.
    params.S_bar_R = cap; % Apply the calibrated residential cap.
end
STATUS(options,'Matching population and urbanization at the selected caps (residential %.4g, commercial %.4g effective floors).',params.S_bar_R,params.S_bar_C); % Identify the final inversion.
[params,~,~,scalist,varlist,iter,density] = FINDUtilde(params,fund,options,targets.urban_share,initial); % Return a coherent calibrated baseline.
baseline = PACK_RESULT(params,fund,options,scalist,varlist,density,iter); % Add GDP and diagnostics without changing equilibrium.
baseline.requested_targets = targets; % Preserve the user's original inputs for provenance.
baseline.targets = targets; % Record the moments actually used to identify the baseline.
baseline.targets.height_gap = gap; % An overridden gap is not a fitted empirical moment.
baseline.diagnostics.height_gap_overridden = gap_overridden; % Distinguish a manual policy from a matched height gap.
baseline.diagnostics.iteration_type = 'rural-utility inversion'; % Explain the stored iteration count.
baseline.diagnostics.population_error = abs(scalist.N/targets.population-1); % Verify the target fit.
if ~isempty(gap)
    STATUS(options,'Checking the achieved height gap against the unrestricted-height city.'); % Announce the final diagnostic solve.
    free = params; free.S_bar_C = Inf; free.S_bar_R = Inf; % Retain all other calibrated fundamentals.
    if isinf(params.S_bar_C) && isinf(params.S_bar_R)
        unlimited = scalist; % Avoid a redundant solve for an already unregulated baseline.
    else
        [~,~,unlimited] = EQFIND(free,fund,options,baseline.initial); % Benchmark conditional on the same horizontal boundary.
    end
    identified = unlimited.F_tallE > 1e-10; % Check whether the gap has an economic denominator.
    if identified, simulated_gap = 1-scalist.F_tallE/unlimited.F_tallE; else, simulated_gap = 0; end % Explicit no-tall-city convention.
    if (~identified && gap > 0) || abs(simulated_gap-gap) > options.hg_tol
        error('ABSJ2027:HeightGap','Height gap could not be matched: target %.2f%%, simulated %.2f%%. Tall development may be absent or the target infeasible.',100*gap,100*simulated_gap); % Do not conceal an unidentified or poor fit.
    end
    STATUS(options,'Height gap matched: %.2f%%; target %.2f%%.',100*simulated_gap,100*gap); % Report fit in percentage units.
    baseline.diagnostics.height_gap = simulated_gap; % Save the achieved gap.
    baseline.diagnostics.height_gap_identified = identified; % Record the no-tall-development case.
end
baseline.reporting = REPORT_UNITS(baseline); % Save the display conversion alongside raw model outcomes.
STATUS(options,'Baseline ready in %.1f seconds: population %.0f; urban share %.2f%%.',toc(started),scalist.N,100*scalist.N/params.N_bar); % Confirm successful completion.

end
