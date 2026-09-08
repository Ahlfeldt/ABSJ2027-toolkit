function result = PACK_RESULT(params, fund, options, scalist, varlist, density, iterations)
%PACK_RESULT Preserve one solved city and add reporting-only aggregates.
scalist.GDP = scalist.y*scalist.N/params.alpha_C; % Urban output in units of the numeraire good.
scalist.wage_bill = scalist.y*scalist.N; % Aggregate urban labor income.
scalist.density = scalist.N/scalist.AREA; % Residents per square km of developable urban land.
scalist.DD = scalist.density.^params.beta_dens_R; % Density component of residential amenity (an index).
scalist.urban_share = scalist.N/params.N_bar; % Endogenous urban fraction of the fixed region.
scalist.F = scalist.F_C+scalist.F_R; % Total commercial and residential floor space.
result = struct('params',params,'fund',fund,'options',options,'scalist',scalist,'varlist',varlist); % Store explicit inputs and outputs together.
result.initial = struct('y',scalist.y,'U_bar',scalist.U_bar,'density',density); % Warm start for related equilibria.
result.diagnostics.iterations = iterations; % Equilibrium or outer inversion iteration count, as documented by caller.
result.diagnostics.labor_error = abs(scalist.L/scalist.N-1); % Labor-market residual.
result.diagnostics.housing_error = abs(sum(varlist.n_x,'omitnan')/scalist.N-1); % Housing-market residual in population units.
result.diagnostics.density_error = abs(density/scalist.density-1); % Density fixed-point residual.
end
