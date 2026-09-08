function VALIDATE_INPUTS(params, fund)
%VALIDATE_INPUTS Check economic parameter domains before entering the solver.
positive = {'c_R','c_C','a_bar_R','a_bar_C','r_a','zeta','U_tilde','N_bar'}; % Strictly positive finite primitives.
for k = 1:numel(positive)
    name = positive{k}; % Select the next named primitive.
    validateattributes(params.(name),{'numeric'},{'scalar','real','finite','positive'},'ABSJ2027',name); % Check with its visible name.
end
for name = {'alpha_R','alpha_C'}
    validateattributes(params.(name{1}),{'numeric'},{'scalar','real','finite','>',0,'<',1},'ABSJ2027',name{1}); % Cobb-Douglas shares.
end
validateattributes(params.ell,{'numeric'},{'scalar','real','finite','>',0,'<=',1},'ABSJ2027','ell'); % Developable land fraction.
for name = {'tau_R','tau_C','omega_R','omega_C','T','x_core_R','x_core_C'}
    validateattributes(params.(name{1}),{'numeric'},{'scalar','real','finite','nonnegative'},'ABSJ2027',name{1}); % Supported non-negative parameters.
end
for name = {'beta_R','beta_C','beta_dens_R','theta_R','theta_C'}
    validateattributes(params.(name{1}),{'numeric'},{'scalar','real','finite'},'ABSJ2027',name{1}); % Finite elasticities.
end
if params.theta_R <= params.omega_R || params.theta_C <= params.omega_C
    error('ABSJ2027:Parameters','Each theta must exceed the corresponding omega for an interior optimal height.'); % Developer second-order condition.
end
for name = {'S_bar_R','S_bar_C','x1_max'}
    validateattributes(params.(name{1}),{'numeric'},{'scalar','real','positive','nonnan'},'ABSJ2027',name{1}); % Positive caps or Inf.
end
if params.tau_C/(1-params.alpha_C) <= params.tau_R/(1-params.alpha_R)
    error('ABSJ2027:Parameters','The commercial demand gradient must be steeper than the residential gradient: tau_C/(1-alpha_C) > tau_R/(1-alpha_R).'); % Preserve the paper's monocentric ordering restriction.
end
for name = {'a_rand_C','a_rand_R'}
    values = fund.(name{1}); % Retrieve optional spatial multipliers.
    validateattributes(values,{'numeric'},{'column','real','finite','positive','numel',numel(fund.D)},'ABSJ2027',name{1}); % Match every spatial cell.
end
end
