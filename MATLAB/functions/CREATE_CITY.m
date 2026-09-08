function fund = CREATE_CITY(params, options)
%CREATE_CITY Build the radial land grid; do not calibrate or solve the city.
% params is accepted to keep the master workflow explicit. Land supply ell
% remains in params and is applied inside SOLVER, including in counterfactuals.
if nargin < 2, options = NUMERICS(); end % Supply documented numerical defaults.
validateattributes(params.ell, {'numeric'}, {'scalar','real','finite','positive','<=',1}); % Check developable share.
validateattributes(options.radius, {'numeric'}, {'scalar','real','finite','positive'}); % Check regional extent.
validateattributes(options.spacing, {'numeric'}, {'scalar','real','finite','positive'}); % Check resolution.
cells = round(options.radius / options.spacing); % Count intervals on one radius.
if cells < 2 || abs(cells*options.spacing-options.radius) > 1e-8
    error('ABSJ2027:Grid','The radius must be an integer multiple of spacing, with at least two intervals.'); % Avoid an ambiguous grid.
end
fund.x = (-cells:cells)' .* options.spacing; % Symmetric coordinates retained for compatibility.
fund.D = fund.x(fund.x >= 0); % Solve only the non-negative radius.
width = (max(fund.x)-min(fund.x))/numel(fund.x); % Preserve replication quadrature exactly.
fund.GEOLAND_x = width*2*pi*(fund.D+0.5*width); % Geographic area of each annulus.
fund.a_rand_C = ones(size(fund.D)); % Optional location-specific productivity multipliers.
fund.a_rand_R = ones(size(fund.D)); % Optional location-specific amenity multipliers.
fund.grid_spacing = options.spacing; % Retain resolution for domain diagnostics.
end
