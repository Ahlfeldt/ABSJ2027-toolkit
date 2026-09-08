function counterfactual = COUNTERFACTUAL(baseline, changes)
%COUNTERFACTUAL Solve a changed city without re-inverting baseline targets.
counterfactual = []; % Empty output selects baseline-only reporting.
if nargin < 2, return; end % No changes supplied means no second solve.
[params,fund,changed] = APPLY_CHANGES(baseline,changes); % Apply overrides to a baseline copy.
if ~changed, return; end % Empty set/pct structures also mean baseline only.
STATUS(baseline.options,'Solving the counterfactual city with the specified changes.'); % Announce the second scenario only when requested.
[~,~,scalist,varlist,iter,density] = EQFIND(params,fund,baseline.options,baseline.initial); % Keep rural utility and regional population unless explicitly changed.
counterfactual = PACK_RESULT(params,fund,baseline.options,scalist,varlist,density,iter); % Package this independent equilibrium.
counterfactual = ADD_HEIGHT_GAP(counterfactual); % Report the gap relative to this scenario with its height limits removed.
STATUS(baseline.options,'Counterfactual ready.'); % Confirm the scenario has solved.
counterfactual.reporting = REPORT_UNITS(baseline); % Preserve the baseline display scale in saved experiment metadata.
counterfactual.changes = changes; % Retain the experiment specification.
counterfactual.diagnostics.iteration_type = 'equilibrium'; % Explain the iteration counter.
end
