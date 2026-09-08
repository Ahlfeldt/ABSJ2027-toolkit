function [statistics, figures] = RESULTS(baseline, counterfactual, make_graphs)
%RESULTS Display baseline levels alone, or levels and counterfactual changes.
if nargin < 2, counterfactual = []; end % Baseline-only mode is the default.
if nargin < 3, make_graphs = true; end % Allow numerical-only reporting for validation.
if ~isfield(baseline.scalist,'height_gap'), baseline=ADD_HEIGHT_GAP(baseline); end % Upgrade older saved results once before tabulation.
if ~isempty(counterfactual) && ~isfield(counterfactual.scalist,'height_gap'), counterfactual=ADD_HEIGHT_GAP(counterfactual); end % Use the counterfactual's own unrestricted benchmark.
units = REPORT_UNITS(baseline); % Fix one monetary conversion from the baseline for both scenarios.
displayed_base = REPORT_CITY(baseline,units); % Convert reporting values without altering the solved city.
fields = {'N','urban_share','GDP','wage_bill','y','total_urban_area','AREA','density','x0','x1','F_C','F_R','F','p_R','p_C','CC','commuting_income_loss','commuting_loss_pct','DD','HA','U_bar','V','LV','floor_space_per_resident','housing_expenditure','height_gap_pct'}; % Ordered model outcomes.
metric = ["Urban population";"Urbanization rate";"GDP";"Wage bill";"Wage";"Total urban area";"Developable urban area";"Population density";"CBD boundary";"Urban fringe";"Commercial floor space";"Residential floor space";"Total floor space";"Average residential rent";"Average commercial rent";"Commuting disamenity index";"Commuting disamenity: income loss per resident";"Commuting disamenity: share of wage";"Density amenity index";"Height amenity index";"Urban utility";"Regional expected welfare";"Aggregate regional land rent";"Residential floor space per resident";"Housing expenditure per resident";"Height gap (relative to T)"]; % Plain-language labels.
unit = ["people";"fraction";units.flow;units.flow;units.flow+" / worker";units.area;units.area;units.density;units.distance;units.distance;units.floor_area;units.floor_area;units.floor_area;units.rent;units.rent;"index";units.flow+" / resident";"% of wage";"index";"index";"utility units";"utility units";units.flow;units.floor_per_resident;units.flow+" / resident";"%"]; % Use physical spatial units only when a geographic-area target identifies their scale.
if units.spatial
    fprintf('Spatial reporting: calibrated km, km^2, and m^2 units from targets.total_urban_area.\n');
else
    fprintf('Spatial reporting: model distance, area, and floor-space units; no physical spatial scale is calibrated.\n');
end
if units.annual, metric(5) = "Average annual wage"; end % Name the observed wage convention when calibrated.
base = zeros(numel(fields),1); % Allocate the baseline column.
for k = 1:numel(fields), base(k) = displayed_base.scalist.(fields{k}); end % Read saved scalars without resolving.
statistics = table(metric,unit,base,'VariableNames',{'Metric','Unit','Baseline'}); % Always provide the baseline.
if ~isempty(counterfactual)
    displayed_next = REPORT_CITY(counterfactual,units); % Reuse the baseline factor; do not normalize away wage changes.
    next = zeros(size(base)); % Allocate counterfactual levels.
    for k = 1:numel(fields), next(k) = displayed_next.scalist.(fields{k}); end % Read the second saved equilibrium.
    change = NaN(size(base)); valid = isfinite(base) & isfinite(next) & base ~= 0; % Identify defined percentage comparisons.
    change(valid) = 100*(next(valid)./base(valid)-1); % Percent change relative to the baseline.
    statistics.Counterfactual = next; % Append counterfactual levels.
    statistics.Change_pct = change; % Append percentage changes; undefined cases remain NaN.
    fprintf('\nABSJ2027: baseline and counterfactual\n'); % Identify comparison mode.
else
    fprintf('\nABSJ2027: baseline city\n'); % Identify baseline-only mode.
end
fprintf('Baseline target fit: population error %.4f%%; labor residual %.4f%%; housing residual %.4f%%.\n',100*baseline.diagnostics.population_error,100*baseline.diagnostics.labor_error,100*baseline.diagnostics.housing_error); % Report actual numerical accuracy.
if units.annual
    fprintf('Monetary values: %s; annual flows. Both scenarios use the baseline wage conversion.\n',char(units.money)); % Explain the reporting scale.
else
    fprintf('No observed wage supplied: monetary values remain in model units; rent denominators follow the reported spatial scale.\n'); % Avoid implying an empirical monetary calibration.
end
fprintf('Height gap is relative to each scenario without height limits, using T; undefined if unrestricted tall development is absent. Under empirical parameterization it is descriptive, not calibrated to the paper height-gap moment.\n'); % Clarify interpretation and missing denominators.
disp(statistics); % Print the reusable MATLAB table.
figures = gobjects(0); % Baseline-only or numerical-only callers receive valid handles or an empty list.
if make_graphs
    figures(1) = GHEIGHT(baseline,counterfactual); % Building-height comparison.
    figures(2) = GBIDRENT(baseline,counterfactual); % Floor-space-rent comparison.
    figures(3) = GLANDRENT(baseline,counterfactual); % Land-rent comparison.
end
end


