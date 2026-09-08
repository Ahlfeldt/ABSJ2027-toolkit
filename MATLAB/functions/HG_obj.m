function [obj, HG_sim, identified] = HG_obj(params, fund, options, mu, HG_set, HL)
%HG_OBJ Match a common height cap, keeping theta_R and theta_C independent.
if ~isfinite(HL) || HL < params.T || HL <= 0
    obj = 1e6+abs(HL); HG_sim = NaN; identified = false; return; % Keep the unconstrained search in the admissible region.
end
STATUS(options,'Trying height cap %.4g effective floors: matching empirical moments...',HL); % Show activity before the expensive nested solve.
params.S_bar_C = HL; % Candidate commercial cap.
params.S_bar_R = HL; % Candidate residential cap.
initial = []; % Preserve the original default unless an outer calibration supplies a warm start.
if isfield(options,'initial'), initial = options.initial; end % Reuse the floor-space calibration's predicted state.
[params,y,U_bar,limited,~,~,density] = FINDUtilde(params,fund,options,mu,initial); % Match the city population at this cap.
initial = struct('y',y,'U_bar',U_bar,'density',density); % Warm-start the unregulated equilibrium.
params.S_bar_C = Inf; % Remove only the commercial height cap.
params.S_bar_R = Inf; % Remove only the residential height cap; retain the growth boundary.
[~,~,unlimited] = EQFIND(params,fund,options,initial); % Keep the inverted rural primitive fixed.
identified = unlimited.F_tallE > 1e-10; % A gap needs positive unconstrained tall floor space.
if identified
    HG_sim = 1-limited.F_tallE/unlimited.F_tallE; % Replication's excess-height gap.
else
    HG_sim = 0; % Convention for a city with no potential tall development.
end
STATUS(options,'Trial gap %.2f%%; target %.2f%%; difference %.2f percentage points.',100*HG_sim,100*HG_set,100*abs(HG_sim-HG_set)); % Keep reported units unambiguous.
obj = abs(HG_sim-HG_set); % Replication objective: absolute height-gap mismatch.
end
