function baseline = MATCH_FLOORSPACE(params, fund, targets, options)
%MATCH_FLOORSPACE Fit residential floor space using a common construction-cost multiplier.
target = targets.floor_space_per_resident; % Requested residential floor space in square metres per resident.
tolerance = 0.001; max_iterations = 20; % Require 0.1% relative fit and a bounded calibration.
work_options = options; starting_c_R = params.c_R; starting_c_C = params.c_C; % Preserve the supplied cost ratio and user controls.
cost_multiplier = 1; % A single multiplier scales both construction-cost levels.
STATUS(options,'Matching residential floor space: target %.2f m^2 per resident; calibrating a common multiplier for c_R and c_C.',target); % Explain the additional empirical moment.
for iteration = 1:max_iterations
    baseline = QUANTIFY_CITY(params,fund,targets,work_options); % Re-match population, urbanization, and any active height gap at this cost.
    residents = sum(baseline.varlist.n_x,'omitnan'); % Match the same resident weights used in the displayed statistic.
    actual = sum(baseline.varlist.n_x.*baseline.varlist.f_bar_x_R,'omitnan')/residents*1e6; % Convert model floor space to m^2 per resident.
    relative_error = abs(actual/target-1); % Assess the empirical moment in proportional terms.
    STATUS(options,'Floor-space fit %d: %.3f m^2 per resident (target %.3f); c_R = %.6g, c_C = %.6g.',iteration,actual,target,params.c_R,params.c_C); % Report each outer calibration step.
    if relative_error < tolerance
        baseline.options = options; % Do not expose the internal warm-start state as a user numerical setting.
        baseline.diagnostics.floor_space_per_resident = actual; % Record the fitted quantity in m^2.
        baseline.diagnostics.floor_space_target = target; % Record the empirical target.
        baseline.diagnostics.floor_space_error = relative_error; % Make the remaining matching error visible.
        baseline.diagnostics.floor_space_iterations = iteration; % Count nested city quantifications.
        baseline.diagnostics.starting_c_R = starting_c_R; % Retain the supplied residential cost.
        baseline.diagnostics.starting_c_C = starting_c_C; % Retain the supplied commercial cost.
        baseline.diagnostics.construction_cost_multiplier = cost_multiplier; % Document the common scale inferred from the floor-space moment.
        STATUS(options,'Floor-space target matched; common cost multiplier %.6g; c_R = %.6g, c_C = %.6g.',cost_multiplier,baseline.params.c_R,baseline.params.c_C); % Confirm that the solution, not just its labels, has changed.
        return; % Counterfactuals will inherit this calibrated cost without re-matching the moment.
    end
    factor = (actual/target)^(1+params.theta_R); % Use residential scaling as an initial update prediction; re-solve both sectors to verify actual fit.
    factor = min(100,max(0.01,factor)); % Bound individual updates for large mismatches or binding caps.
    new_multiplier = cost_multiplier*factor; % Increase the common cost scale when implied residential floor space is too large.
    new_costs = new_multiplier*[starting_c_R,starting_c_C]; % Preserve the original c_R/c_C ratio exactly up to floating-point precision.
    if any(~isfinite(new_costs)) || any(new_costs <= 0)
        error('ABSJ2027:FloorSpace','The requested floor-space target cannot be reached with finite positive construction costs.'); % Reject numerical overflow.
    end
    work_options.initial = baseline.initial; % Carry the solved state into the next quantification.
    commercial_height_scale = factor^(-1/(1+params.theta_C)); % Predict a commercial height response for the numerical warm start only.
    wage_scale = commercial_height_scale^((1-params.alpha_C)*(1+params.omega_C)); % Approximate the wage response to changed commercial floor space.
    work_options.initial.y = baseline.initial.y*wage_scale; % Start nearer the new commercial equilibrium; the solver still determines the wage.
    height_scale = factor^(-1/(1+params.theta_R)); % Predict the unconstrained residential height response to the cost change.
    work_options.initial.U_bar = baseline.initial.U_bar*wage_scale*height_scale^((1+params.omega_R)*(1-params.alpha_R)); % Warm-start utility consistently with the associated housing-rent change.
    cost_multiplier = new_multiplier; % Retain the common cumulative scale for diagnostics.
    params.c_R = new_costs(1); % Adjust residential construction cost.
    params.c_C = new_costs(2); % Apply the same proportional adjustment to commercial construction cost.
end
error('ABSJ2027:FloorSpace','Could not match residential floor space: target %.3f m^2, achieved %.3f after %d iterations. Height/FAR limits or other inputs may make the target infeasible.',target,actual,max_iterations); % Never silently accept an unmatched moment.
end
