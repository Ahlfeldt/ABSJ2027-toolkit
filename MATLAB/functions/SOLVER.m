function [y_up, U_bar_up, scalist,varlist, density_up] = SOLVER(params, fund, y, U_bar, density)
%SOLVER Replication equations, with an optional urban growth boundary.
% Source: QuantitativeModel/Functions/SOLVER.m; see SOURCE_MAP.md.
    % Unpack parameters
    alpha_R = params.alpha_R; % Non-housing expenditure share.
    beta_R = params.beta_R; % Additional population elasticity of residential amenity; zero in the paper.
    beta_dens_R = params.beta_dens_R; % Density elasticity of residential amenity, corresponding to beta^R in the paper.
    tau_R = params.tau_R; % Residential amenity decay per km.
    omega_R = params.omega_R; % Residential height elasticity of floor-space rent.
    theta_R = params.theta_R; % Residential height elasticity of unit construction cost.
    c_R = params.c_R; % Residential construction-cost scale.
    a_bar_R = params.a_bar_R; % Fundamental residential amenity.

    alpha_C = params.alpha_C; % Labor share in commercial production.
    beta_C = params.beta_C; % Population agglomeration elasticity in production.
    tau_C = params.tau_C; % Commercial productivity decay per km.
    omega_C = params.omega_C; % Commercial height elasticity of floor-space rent.
    theta_C = params.theta_C; % Commercial height elasticity of unit construction cost.
    c_C = params.c_C; % Commercial construction-cost scale.
    a_bar_C = params.a_bar_C; % Fundamental commercial productivity.

    r_a = params.r_a; % Agricultural outside bid for land.
    S_bar_C = params.S_bar_C;  % Permitted commercial effective height.
    S_bar_R = params.S_bar_R; % Permitted residential effective height.

    % Built-up area share
    ell = params.ell; % Developable share of geographic land.

    % Migration elasticity
    zeta = params.zeta ; % Preference dispersion parameter governing migration.

    % Height threshold
    T = params.T; % Effective tall-height threshold used in aggregation.

    % Height limits
    S_bar_C = params.S_bar_C ; % Sector height cap, possibly Inf.
    S_bar_R = params.S_bar_R ; % Sector height cap, possibly Inf.

    % Rural utility
    U_tilde = params.U_tilde; % Rural utility raised to the power zeta.

    % Regional population
    N_bar = params.N_bar; % Population of the city plus its hinterland.

    % Unpack variables
    a_rand_C = fund.a_rand_C; % Spatial commercial productivity multiplier.
    a_rand_R = fund.a_rand_R;  % Spatial residential amenity multiplier.
    D = fund.D; % Non-negative radial distances, km.
    x = fund.x; % Symmetric plotting coordinates retained from the replication.
    GEOLAND_x = fund.GEOLAND_x; % Geographic annulus area, before applying ell.

    % Initialize variables - clear any pre-existing value
    A_tilde_x_C = NaN(size(D));
    A_tilde_x_R = NaN(size(D));
    a_x_C = NaN(size(D)); 
    a_x_R = NaN(size(D)); 
    r_x_C = NaN(size(D));  
    r_x_R = NaN(size(D)); 
    U = NaN(size(D));
    S_x_C = NaN(size(D)); 
    S_x_R = NaN(size(D)); 
    p_bar_x_C = NaN(size(D)); 
    p_bar_x_R = NaN(size(D)); 
    L_x_C = NaN(size(D)); 
    f_bar_x_R = NaN(size(D));
    n_x = NaN(size(D));
    S_x = NaN(size(D));


% Compute area per spatial unit
    LAND_x = ell * GEOLAND_x; % Developable land is ell fraction of geogrpahic land

% Compute number of people in city for U_bar guess
    N = U_bar.^zeta / (U_bar.^zeta+U_tilde).*N_bar;

% Compute amenities    
    % Compute A_tilde_x_C
    A_tilde_x_C = a_rand_C .* a_bar_C .* N.^beta_C .* exp(-tau_C .* max(0, (D - params.x_core_C)));
    % Compute A_tilde_x_R
    A_tilde_x_R = a_rand_R .* a_bar_R .* (N).^beta_R .* (density).^beta_dens_R .* exp(-tau_R .* max(0, (D - params.x_core_R))); % Density disamenity is already included here.
    % Compute a_x_C
    a_x_C = A_tilde_x_C.^(1 ./ (1 - alpha_C)) .* y.^(alpha_C ./ (alpha_C - 1));
    % Compute a_x_R
    a_x_R = A_tilde_x_R.^(1 ./ (1 - alpha_R)) .* y.^(1 ./ (1 - alpha_R)) .* U_bar.^(-1 ./ (1 - alpha_R));

% Profit-maximizing height
    % Compute S_star_x_C
    S_star_x_C = (a_x_C ./ (c_C * (1 + theta_C))).^(1 ./ (theta_C - omega_C));
    % Compute S_star_x_R
    S_star_x_R = (a_x_R ./ (c_R * (1 + theta_R))).^(1 ./ (theta_R - omega_R));

% Realized height, conditional on height limits
    % Compute S_tilde_x_C (element-wise min between S_star_x_C and S_bar_C)
    S_tilde_x_C = min(S_star_x_C, S_bar_C);
    % Compute S_tilde_x_R (element-wise min between S_star_x_R and S_bar_R)
    S_tilde_x_R = min(S_star_x_R, S_bar_R);

% Land rent
    % Compute r_x_C
    r_x_C = (a_x_C ./ (1 + omega_C)) .* S_tilde_x_C.^(1 + omega_C) - c_C .* S_tilde_x_C.^(1 + theta_C);
    % Compute r_x_R
    r_x_R = (a_x_R ./ (1 + omega_R)) .* S_tilde_x_R.^(1 + omega_R) - c_R .* S_tilde_x_R.^(1 + theta_R);

% Land use allocation
    % Initialize U as NaN 
    U = NaN(size(D));
    % Define land use based on rent comparisons
    U(r_a > r_x_C & r_a > r_x_R) = 3;  % Agricultural land (r_a highest)
    U(r_x_R > r_x_C & r_x_R > r_a) = 2;  % Residential land (r_x_R highest)
    U(r_x_C > r_x_R & r_x_C > r_a) = 1;  % Commercial land (r_x_C highest)  
    U(D > params.x1_max) = 3; % Toolkit extension: prohibit urban use beyond the growth boundary.
    % Find the outermost residential grid point (urban fringe).
    x1_indices = find(U == 2 & D >= 0);
    if ~isempty(x1_indices)
        x1 = max(D(x1_indices));  % Outermost residential radius in km.
    else
        x1 = NaN;  % Handle case where no valid x is found
    end
    % Find x0: Minimum x where U != 1 and x >= 0
    x0_indices = find(U ~= 1 & D >= 0);
    if ~isempty(x0_indices)
        x0 = min(D(x0_indices));  % Get minimum x for non-commercial land
    else
        x0 = NaN;  % Handle case where no valid x is found
    end

% Assign heights to actual land use
    S_x_C = S_tilde_x_C; % Replace values in S_x_C where U == 1
    S_x_C(U ~= 1) = NaN; 
    S_x_R = S_tilde_x_R; % Replace values in S_x_R where U == 2
    S_x_R(U~=2) = NaN;
% Compute total floor space
    F_x_C = S_x_C.*LAND_x;
    F_x_R = S_x_R.*LAND_x;
    F_C = nansum((S_x_C) .* LAND_x);
    F_R = nansum((S_x_R) .* LAND_x);    
    F_C_tall = nansum((S_x_C .* (S_x_C > T)) .* LAND_x);
    F_R_tall = nansum((S_x_R .* (S_x_R > T)) .* LAND_x);
    F_tall = F_C_tall + F_R_tall; % Total height of tall buildings
    F = F_C + F_R; % Total height
    F_tallE = nansum((max(S_x_C-T,0)) .* LAND_x) + nansum((max(S_x_R-T,0)) .* LAND_x); 
% Floor space rent
    p_bar_x_C = NaN(size(D));                           % Initialize variable
    p_bar_x_C = a_x_C .* 1/(1+omega_C).*S_x_C.^omega_C; % assign values
    p_bar_x_C(U ~= 1) = NaN;                            % Keep for land use
    p_bar_x_R = NaN(size(x));                           % Initialize variable
    p_bar_x_R = a_x_R .* 1/(1+omega_R).*S_x_R.^omega_R; % assign values
    p_bar_x_R(U ~= 2) = NaN;                            % Keep for land use

% Compute local workplace employment
	L_x_C = NaN(size(D));                           % Initialize variable
    L_x_C = alpha_C ./(1-alpha_C).*p_bar_x_C ./ y .* S_x_C .* LAND_x ;
    L_x_C(U ~= 1) = NaN; 
    L=nansum(L_x_C);

% Compute local floor space consumption per worker
  	f_bar_x_R = NaN(size(D));                           % Initialize variable
    f_bar_x_R = (1-alpha_R) ./ p_bar_x_R .* y;
    f_bar_x_R(U ~= 2) = NaN;
% compute local number of workers
    n_x = F_x_R ./ f_bar_x_R;

% Labor-market clearing predicts the wage that rationalizes labor supply.
% This will be used to update the guess
    product = p_bar_x_C .* F_x_C;  % Element-wise multiplication
    product(isnan(product)) = 0;   % Replace NaN values with 0
    y_up = (alpha_C ./ (1 - alpha_C) .* sum(product)) ./ N;
    clear product;

% Predict urban utility for given values
    AS_x_R = NaN(size(D));                           % Initialize variable
    AS_x_R = A_tilde_x_R.^(1./(1 - alpha_R)) .* S_x_R.^(1 + omega_R) .* LAND_x;
    AS_x_R(U ~= 2) = NaN; 
    AS_x_R(isnan(AS_x_R)) = 0;
	U_bar_up = [1./(1+omega_R)*y.^(1/(1-alpha_R)).*sum(AS_x_R)].^(1-alpha_R) ./ [(1-alpha_R).*y.*N].^(1-alpha_R);

% Finalize some land use variables for use in plotting functions	
    URBAN = U < 3;  % Update indicator for urban use
    COM = U == 1;   % Update indicator for commercial use    

% Compute expected utility
    V = (params.U_tilde + U_bar.^zeta).^(1./zeta);
% Compute total area 
    AREA = pi.*x1^2.*params.ell;
% Compute commuting cost
    CC = exp(params.tau_R .* D);  % Element-wise exponentiation
    CC = nansum(CC .* n_x) / nansum(n_x);  % Weighted mean formula
% Compute residential rent
    p_R = nansum(p_bar_x_R .* n_x) / nansum(n_x);  % Weighted mean of p_bar_x_R
% Compute commercial rent
    p_C = nansum(p_bar_x_C .* L_x_C) / nansum(L_x_C);  % Weighted mean of p_bar_x_C
% Productivity
    A_tilde_C = nansum(A_tilde_x_C .* L_x_C) / nansum(L_x_C);
% Aggregate land rent over the fixed regional domain (including agriculture).
   LV = nansum(LAND_x(U == 1) .* r_x_C(U == 1)) + nansum(LAND_x(U == 2) .* r_x_R(U == 2)) + nansum(LAND_x(U == 3) .* params.r_a);
% Height amenity
   HA_x = S_x_R.^(params.omega_R.*(1-params.alpha_R));
   HA = nansum(HA_x .* n_x) / nansum(n_x);  % Weighted mean

  % Creating variable list required for graphs and addional functions
  varlist = struct('LAND_x', LAND_x, 'S_x_C', S_x_C, 'S_x_R', S_x_R, 'URBAN', URBAN, 'COM', COM, 'p_bar_x_C', p_bar_x_C, 'p_bar_x_R', p_bar_x_R, 'r_x_C', r_x_C, 'r_x_R', r_x_R, 'L_x_C', L_x_C, 'f_bar_x_R',f_bar_x_R,'n_x',n_x);
  % Creating scalar list required for further analysis
  scalist = struct('N',N,'L',L,'AREA',AREA,'CC',CC,'p_R', p_R,'p_C', p_C,'A_tilde_C',A_tilde_C,'y',y,'LV',LV,'U_bar',U_bar,'V',V , 'x0',x0,'x1',x1,'F_C',F_C,'F_R',F_R,'F_C_tall',F_C_tall,'F_R_tall',F_R_tall,'F_tall',F_tall,'F_tallE',F_tallE,'HA',HA);

% Return the implied density for the next fixed-point iteration.
    new_density = scalist.N ./ scalist.AREA;  
    if isnumeric(new_density) && isfinite(new_density)
        density_up = new_density;
    else 
        density_up = density;
    end
% Function ends
end
