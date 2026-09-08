function displayed = REPORT_CITY(city, units)
%REPORT_CITY Convert a copy for display; never pass this copy to the model solver.
displayed = city; % Preserve all original model inputs and results in the caller.
displayed.scalist.total_urban_area = pi*city.scalist.x1^2; % Entire area within the urban fringe in calibrated square kilometres or uncalibrated model area units.
displayed.scalist.height_gap_pct=NaN; % Internal trial cities need not compute an unused height-gap benchmark.
if isfield(city.scalist,'height_gap'), displayed.scalist.height_gap_pct=100*city.scalist.height_gap; end % Report the fraction as a percentage; undefined denominators remain NaN.
monetary = {'GDP','wage_bill','y','LV'}; % Monetary totals and wages share the baseline conversion.
for k = 1:numel(monetary)
    field = monetary{k}; % Select the current monetary scalar.
    displayed.scalist.(field) = city.scalist.(field)*units.factor; % Change reporting units only.
end
for field = {'p_R','p_C'}
    displayed.scalist.(field{1}) = city.scalist.(field{1})*units.factor/units.space_factor; % Convert rent per model floor-space unit only when the spatial scale is calibrated.
end
for field = {'p_bar_x_R','p_bar_x_C','r_x_R','r_x_C'}
    displayed.varlist.(field{1}) = city.varlist.(field{1})*units.factor/units.space_factor; % Convert local rents and land bids using the same spatial scale.
end
displayed.params.r_a = city.params.r_a*units.factor/units.space_factor; % Match the agricultural bid to the displayed rent units.
weights = city.varlist.n_x; % Use the same resident weights as average residential rent.
space = city.varlist.f_bar_x_R; % Local floor space per resident, in km^2 of floors.
local_rent = city.varlist.p_bar_x_R; % Local floor-space rent in original units.
residents = sum(weights,'omitnan'); % Normalize by the residents represented in the housing allocation.
displayed.scalist.floor_space_per_resident = sum(weights.*space,'omitnan')/residents*units.space_factor; % Convert to square metres only when a geographic-area target identifies the spatial scale.
displayed.scalist.housing_expenditure = sum(weights.*space.*local_rent,'omitnan')/residents*units.factor; % Average local expenditure, not the product of average rent and space.
commuting_distance = max(0,city.fund.D-city.params.x_core_R); % Use the same flat core as the residential amenity equation.
local_loss_share = -expm1(-city.params.tau_R*commuting_distance); % Equivalent income-loss share, 1-exp(-tau_R*d), stable near zero.
mean_loss_share = sum(weights.*local_loss_share,'omitnan')/residents; % Average local losses across residents, not a transformation of the mean CC index.
displayed.scalist.commuting_income_loss = displayed.scalist.y*mean_loss_share; % Annual currency loss per resident when an observed annual wage defines the scale.
displayed.scalist.commuting_loss_pct = 100*mean_loss_share; % Express the equivalent loss as a percentage of each scenario's wage.
density = city.scalist.N/city.scalist.AREA; % Use the same developable-area density as the reported outcome.
density_loss_share = -expm1(city.params.beta_dens_R*log(density/units.reference_density)); % Unit-invariant income equivalent relative to baseline density.
displayed.scalist.density_income_loss = displayed.scalist.y*density_loss_share; % Use the scenario wage; a negative loss is a density-related benefit.
displayed.scalist.density_loss_pct = 100*density_loss_share; % Baseline is zero; report the loss as a percentage of the scenario wage.
displayed.reporting = units; % Identify the units used in this temporary display copy.
end

