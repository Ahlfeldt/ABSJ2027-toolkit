function units = REPORT_UNITS(baseline)
%REPORT_UNITS Define one baseline monetary conversion for all displayed scenarios.
units.reference_density = baseline.scalist.N/baseline.scalist.AREA; % Baseline residents per developable area unit; fixed for all displayed scenarios.
units.factor = 1; % Preserve the monetary numeraire unless an observed wage is supplied.
units.money = "model units"; % Clearly distinguish uncalibrated amounts from currency.
units.flow = "model units"; % The model alone does not identify a calendar period.
units.spatial = isfield(baseline,'targets') && isfield(baseline.targets,'total_urban_area') && ~isempty(baseline.targets.total_urban_area); % A geographic-area target identifies the spatial scale.
units.space_factor = 1; % Preserve uncalibrated floor-space quantities in model units.
units.distance = "model distance units"; % Paper parameters alone do not identify kilometres.
units.area = "model area units"; % Paper parameters alone do not identify square kilometres.
units.density = "people / model area unit"; % Match the uncalibrated area denominator.
units.floor_area = "model floor-space units"; % Do not impose a square-metre conversion without a spatial target.
units.floor_per_resident = "model floor-space units / resident"; % Keep housing quantities in their model scale.
units.rent = "model monetary units / model floor-space unit"; % Neither monetary nor spatial levels are calibrated by default.
if units.spatial
    units.space_factor = 1e6; % One square kilometre contains one million square metres.
    units.distance = "km";
    units.area = "km^2";
    units.density = "people / km^2";
    units.floor_area = "km^2 of floors";
    units.floor_per_resident = "m^2 / resident";
    units.rent = "model monetary units / m^2";
end
units.annual = false; % Record whether an annual wage defines the reporting period.
if isfield(baseline,'targets') && isfield(baseline.targets,'wage') && ~isempty(baseline.targets.wage)
    validateattributes(baseline.targets.wage,{'numeric'},{'scalar','real','finite','positive'},mfilename,'targets.wage'); % Require positive annual earnings per worker.
    units.money = "currency units"; % Use a neutral label unless the user names the currency.
    if isfield(baseline.targets,'currency')
        currency = baseline.targets.currency; % Accept a character row or scalar string label.
        if ~(ischar(currency) && isrow(currency) || isstring(currency) && isscalar(currency)) || ismissing(string(currency)) || strlength(strtrim(string(currency))) == 0
            error('ABSJ2027:Currency','targets.currency must be a nonempty currency label, for example USD or EUR.'); % Avoid ambiguous monetary headings.
        end
        units.money = string(currency); % Keep the user's chosen currency label.
    end
    units.factor = baseline.targets.wage/baseline.scalist.y; % Calibrate only against the baseline wage.
    units.flow = units.money + " / year"; % Annual earnings establish the annual period for monetary flows.
    if units.spatial
        units.rent = units.money + " / m^2 / year"; % The area and wage targets jointly identify annual rent per square metre.
    else
        units.rent = units.money + " / model floor-space unit / year"; % Wage calibration alone does not identify physical space.
    end
    units.annual = true; % Enable annual wage labels and reporting notes.
end
end
