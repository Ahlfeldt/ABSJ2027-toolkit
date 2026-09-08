function [loss,baseline,errors] = CITY_TARGET_OBJECTIVE(z,params,fund,targets,options,active)
%CITY_TARGET_OBJECTIVE Re-solve the city at positive candidate cost and land-rent levels.
multiplier = 1; % Default cost multiplier when only urban area is targeted.
tau_multiplier = 1; % Report unchanged spatial decay when the CBD target is inactive.
k = 0; % Read only coordinates belonging to active targets.
if any(active(1:2))
    k = k+1; multiplier = exp(z(k)-1); % Log coordinates preserve positive construction costs.
    params.c_R = params.c_R*multiplier; params.c_C = params.c_C*multiplier; % Preserve the starting sectoral ratio.
end
if active(3)
    k = k+1; params.r_a = params.r_a*exp(z(k)-1); % Adjust agricultural land rent to identify total urban area.
end
if active(4)
    k=k+1; tau_multiplier=exp(z(k)-1); % One positive multiplier preserves the relative decay rates.
    params.tau_R=params.tau_R*tau_multiplier; params.tau_C=params.tau_C*tau_multiplier; % Change both spatial gradients together.
end
if isfield(options,'initial') && ~isempty(options.initial)
    height_scale = multiplier^(-1/(1+params.theta_R)); % Predict residential height for numerical initialization only.
    wage_scale = multiplier^(-(1-params.alpha_C)*(1+params.omega_C)/(1+params.theta_C)); % Predict the wage response to commercial costs.
    options.initial.y = options.initial.y*wage_scale; % Start near the new commercial equilibrium.
    options.initial.U_bar = options.initial.U_bar*wage_scale*height_scale^((1+params.omega_R)*(1-params.alpha_R)); % Predict utility consistently with housing costs.
end
try
    baseline = QUANTIFY_CITY(params,fund,targets,options); % Re-match population, urbanization, and any active height gap at every candidate.
catch err
    expected = {'ABSJ2027:NoConvergence','ABSJ2027:Infeasible','ABSJ2027:Domain','ABSJ2027:Inversion','ABSJ2027:HeightGap'}; % Only recognized economic/numerical trial failures may be skipped.
    if nargout == 1 && any(strcmp(err.identifier,expected))
        STATUS(options,'Skipping failed optional-calibration trial: %s',err.message); % Expose why the candidate was rejected.
        loss = 1e6+sum(z.^2); return; % Let the search try another candidate; never return this as a calibrated city.
    end
    rethrow(err); % Final verification and unexpected programming errors must fail visibly.
end
displayed = REPORT_CITY(baseline,REPORT_UNITS(baseline)); % Evaluate rent in the wage-defined annual currency units.
actual = []; desired = []; % Retain housing-then-area ordering in diagnostics.
if active(1)
    actual(end+1) = displayed.scalist.floor_space_per_resident; desired(end+1) = targets.floor_space_per_resident; % Resident-weighted m^2 per resident.
elseif active(2)
    actual(end+1) = displayed.scalist.p_R; desired(end+1) = targets.residential_rent; % Resident-weighted annual rent per m^2.
end
if active(3)
    actual(end+1) = pi*baseline.scalist.x1^2; desired(end+1) = targets.total_urban_area; % Geographic area, including non-developable land.
end
if active(4)
    actual(end+1)=baseline.varlist.S_x_C(1); desired(end+1)=targets.cbd_far; % Realized FAR at the centre, in m^2 of floors per m^2 of developable land.
end
errors = actual./desired-1; % Proportional errors are comparable across different units.
loss = sum(log(actual./desired).^2); % Penalize proportional over- and under-shoots symmetrically.
STATUS(options,'Optional target fit: maximum error %.3f%%; c_R %.6g, c_C %.6g, agricultural rent %.6g; tau multiplier %.6g.',100*max(abs(errors)),params.c_R,params.c_C,params.r_a,tau_multiplier); % Keep nested calibration progress visible.
end
