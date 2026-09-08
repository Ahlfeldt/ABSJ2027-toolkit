function baseline = MATCH_CITY_TARGETS(params,fund,targets,options,active)
%MATCH_CITY_TARGETS Fit a housing moment and/or total urban area with unchanged equilibrium equations.
housing = any(active(1:2)); % One common construction-cost multiplier identifies the selected housing moment.
count = housing + active(3) + active(4); % Agricultural rent supplies the second parameter when area is targeted.

controls = optimset('Display','off','OutputFcn',@STOP_CITY_TARGET_SEARCH,'TolX',0.0005,'TolFun',1e-9,'MaxIter',200,'MaxFunEvals',400); % Bound the search in log parameter space.
STATUS(options,'Matching optional city targets: housing costs %d; agricultural land rent %d; common tau scale %d.',housing,active(3),active(4)); % Explain the active calibration.
seed = QUANTIFY_CITY(params,fund,targets,options); % Solve the starting city once to estimate useful parameter scales.
work_options = options; work_options.initial = seed.initial; % Provide a solved reference state for candidate warm starts.
objective = @(z) CITY_TARGET_OBJECTIVE(z,params,fund,targets,work_options,active); % Bind arguments to a separate named function.
view = REPORT_CITY(seed,REPORT_UNITS(seed)); % Compare starting moments in the same units as the targets.
z0 = ones(1,count); k = 0; % Nonzero coordinates give the simplex an effective initial spread.
if housing
    k = k+1; % The housing moment adjusts the construction-cost scale.
    if active(1), ratio = view.scalist.floor_space_per_resident/targets.floor_space_per_resident; else, ratio = targets.residential_rent/view.scalist.p_R; end % Predict whether construction costs must rise or fall.
    z0(k) = 1+(1+params.theta_R)*log(ratio); % Use residential scaling only as a starting prediction.
end
if active(3), k = k+1; z0(k) = 1+log(view.scalist.total_urban_area/targets.total_urban_area); end % Higher agricultural rent tends to shrink the city.
if active(4)
    fitted = seed; % CBD-only calibration starts from the supplied city.
    if housing || active(3)
        other_active = active; other_active(4) = false; % First fit the other targets at the supplied taus to obtain a sensible starting point.
        fitted = MATCH_CITY_TARGETS(params,fund,targets,options,other_active); % This recursive call has no CBD target and terminates in the existing search.
        j = 0; % Translate preliminary fitted levels back into multipliers on the original inputs.
        if housing, j=j+1; z0(j)=1+log(fitted.params.c_R/params.c_R); end % Starting common cost scale.
        if active(3), j=j+1; z0(j)=1+log(fitted.params.r_a/params.r_a); end % Starting agricultural-rent scale.
    end
    k=k+1; z0(k)=1+0.8*log(targets.cbd_far/fitted.varlist.S_x_C(1)); % Predict a tau scale from the remaining central-height mismatch; the search verifies the result.
end
z = fminsearch(objective,z0,controls); % Verify and refine predictions through complete equilibrium solutions.
[~,baseline,errors] = CITY_TARGET_OBJECTIVE(z,params,fund,targets,work_options,active); % Recompute the actual final moment fit.
if any(abs(errors)>0.005)
    error('ABSJ2027:CityTargets','Optional targets could not be matched within 0.5%%. Maximum relative error %.3f%%; caps, the grid, or other inputs may make the targets infeasible.',100*max(abs(errors))); % Never silently accept an unmatched calibration.
end
baseline.options = options; % Keep internal warm-start controls out of saved user options.
baseline.diagnostics.optional_target_relative_errors = errors; % Store errors in active order: housing, then area, then CBD FAR.
baseline.diagnostics.optional_target_tolerance = 0.005; % Allow for the discrete radial land-use grid.
baseline.diagnostics.starting_tau_R = params.tau_R; % Record the residential decay before inversion.
baseline.diagnostics.starting_tau_C = params.tau_C; % Record the commercial decay before inversion.
baseline.diagnostics.tau_multiplier = baseline.params.tau_R/params.tau_R; % Both taus receive the same fitted multiplier.
baseline.diagnostics.cbd_far = baseline.varlist.S_x_C(1); % Central CBD FAR, not the average over the commercial district.
baseline.diagnostics.starting_c_R = params.c_R; % Preserve starting parameter provenance.
baseline.diagnostics.starting_c_C = params.c_C; % Preserve the supplied sectoral cost ratio.
baseline.diagnostics.starting_r_a = params.r_a; % Record the agricultural rent before area inversion.
baseline.diagnostics.construction_cost_multiplier = baseline.params.c_R/params.c_R; % Both cost levels receive this same multiplier.
if active(1)
    displayed = REPORT_CITY(baseline,REPORT_UNITS(baseline)); % Compute floor space with the reporting weights.
    baseline.diagnostics.floor_space_error = abs(displayed.scalist.floor_space_per_resident/targets.floor_space_per_resident-1); % Retain the existing diagnostic name.
end
STATUS(options,'Optional targets matched: c_R %.6g, c_C %.6g, agricultural rent %.6g; tau scale %.6g; maximum error %.3f%%.',baseline.params.c_R,baseline.params.c_C,baseline.params.r_a,baseline.diagnostics.tau_multiplier,100*max(abs(errors))); % Show fitted primitives and accuracy.
end
