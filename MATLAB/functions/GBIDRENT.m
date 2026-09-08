function fig = GBIDRENT(baseline, counterfactual)
%GBIDRENT Plot rents per square metre using the baseline monetary conversion.
if nargin < 2, counterfactual = []; end % Support baseline-only operation.
units = REPORT_UNITS(baseline); % Use the same conversion as the results table.
displayed_base = REPORT_CITY(baseline,units); % Convert a copy of saved outcomes only.
displayed_next = []; % Preserve baseline-only presentation.
if ~isempty(counterfactual), displayed_next = REPORT_CITY(counterfactual,units); end % Keep one conversion across scenarios.
fig = PLOT_PROFILE(displayed_base,displayed_next,'p_bar_x_C','p_bar_x_R','Floor-space rent',char(units.rent)); % Clearly label area and annual currency units when calibrated.
end
