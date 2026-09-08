function baseline = QUANTIFY(params, fund, targets, options)
%QUANTIFY Match city moments and optional physical targets.
if nargin < 4, options = NUMERICS(); end % Use default numerical controls.
fields = {'floor_space_per_resident','residential_rent','total_urban_area','cbd_far'}; % Optional positive targets.
active = false(1,4); % Omitted fields preserve compatibility with older inputs.
for k = 1:numel(fields)
    active(k) = isfield(targets,fields{k}) && ~isempty(targets.(fields{k})); % Empty disables this moment.
    if active(k), validateattributes(targets.(fields{k}),{'numeric'},{'scalar','real','finite','positive'},mfilename,fields{k}); end % Reject invalid moments before solving.
end
if all(active(1:2)), error('ABSJ2027:HousingTargets','Choose either floor_space_per_resident or residential_rent, not both.'); end % Avoid conflicting housing targets.
if active(2) && (~isfield(targets,'wage') || isempty(targets.wage))
    error('ABSJ2027:RentUnits','A residential_rent target requires targets.wage: rent is annual currency per m^2, in the same currency as annual wages.'); % Define the monetary scale explicitly.
end
if active(3) && targets.total_urban_area > pi*min(options.radius,params.x1_max)^2
    error('ABSJ2027:AreaTarget','Total urban area exceeds the grid or urban growth boundary. The target is geographic km^2, including non-developable land.'); % Reject an impossible geographic target.
end
if ~isempty(targets.height_gap) && isinf(params.S_bar_C) && isinf(params.S_bar_R) && (any(active) || ~IS_PAPER_PARAMETERS(params))
    error('ABSJ2027:HeightGapParameterization','Height-gap calibration is only supported under the paper parameterization because T is calibrated for that model. Set targets.height_gap=[] for empirical quantification; the height gap is still reported as an outcome relative to T.'); % Do not fit a paper height gap after re-estimating physical parameters.
end
if active(4) && (params.tau_R<=0 || params.tau_C<=0)
    error('ABSJ2027:CBDTarget','CBD FAR calibration requires positive starting tau_R and tau_C to preserve their ratio.'); % A common scale cannot move a zero decay parameter.
end
if active(4) && isfinite(params.S_bar_C) && targets.cbd_far>=params.S_bar_C
    error('ABSJ2027:CBDTarget','The CBD FAR target must be below the manual commercial FAR cap; at the cap the tau scale is not identified.'); % Reject an impossible or capped central-height target.
end
if active(2) || active(3) || active(4)
    baseline = MATCH_CITY_TARGETS(params,fund,targets,options,active); % Jointly adjust construction costs and/or agricultural rent.
elseif active(1)
    baseline = MATCH_FLOORSPACE(params,fund,targets,options); % Preserve the existing floor-space-only calibration.
else
    baseline = QUANTIFY_CITY(params,fund,targets,options); % Paper baseline: retain supplied costs and agricultural rent.
end
baseline = ADD_HEIGHT_GAP(baseline); % Compute the reported outcome once, after all optional calibration has finished.

end
