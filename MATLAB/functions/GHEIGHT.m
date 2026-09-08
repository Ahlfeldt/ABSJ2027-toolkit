function fig = GHEIGHT(baseline, counterfactual)
%GHEIGHT Plot saved spatial outcomes; never recompute or reset fundamentals.
if nargin < 2, counterfactual = []; end % Support baseline-only operation.
fig = PLOT_PROFILE(baseline,counterfactual,'S_x_C','S_x_R','Building height','Effective floors'); % Shared presentation only.
end
