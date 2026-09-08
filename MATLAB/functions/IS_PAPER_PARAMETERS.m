function matches = IS_PAPER_PARAMETERS(params)
%IS_PAPER_PARAMETERS Check the structural parameterization associated with the paper's T.
reference = struct('alpha_R',.66,'alpha_C',.85,'beta_R',0,'beta_dens_R',-.10535545480050244,'beta_C',.03,'tau_R',.016,'tau_C',.014,'x_core_R',1,'x_core_C',1,'omega_R',.07,'omega_C',.03,'theta_R',.55,'theta_C',.5,'c_R',150,'c_C',150,'a_bar_R',2,'a_bar_C',2,'r_a',50,'ell',.5,'zeta',6.4,'T',2.9605069278556773); % Exclude city moments, inferred rural utility and policy limits.
fields = fieldnames(reference); matches = true; % Accept only the paper structural values, allowing floating-point roundoff.
for k=1:numel(fields)
    name=fields{k}; matches=matches && isfield(params,name) && isscalar(params.(name)) && abs(params.(name)-reference.(name))<=1e-10*max(1,abs(reference.(name))); % Check every structural parameter.
end
end
