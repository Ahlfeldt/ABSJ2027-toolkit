function units = REPORT_UNITS(baseline)
%REPORT_UNITS Define one baseline monetary conversion for all displayed scenarios.
units.reference_density = baseline.scalist.N/baseline.scalist.AREA; % Baseline residents per developable km^2; fixed for all displayed scenarios.
units.factor = 1; % Preserve the monetary numeraire unless an observed wage is supplied.
units.money = "model units"; % Clearly distinguish uncalibrated amounts from currency.
units.flow = "model units"; % The model alone does not identify a calendar period.
units.rent = "model units / m^2"; % Floor-space and land rents always use square metres in displays.
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
    units.rent = units.money + " / m^2 / year"; % Annual rental flow per square metre.
    units.annual = true; % Enable annual wage labels and reporting notes.
end
end
