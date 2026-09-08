function [y, U_bar, scalist, varlist, iter, density] = EQFIND(params, fund, conv_params, initial)
%EQFIND Solve the replication fixed point using explicit optional warm starts.
% The update equations, clipping, and damping are retained from EQFIND.m.
if nargin < 4 || isempty(initial)
    initial = struct('y',1,'U_bar',0.2,'density',1000); % Original starting guesses.
end
y = initial.y; % Initial urban wage.
U_bar = initial.U_bar; % Initial urban utility.
density = initial.density; % Initial residents per square km of developable urban land.
    progress_clock = tic; % Measure reporting intervals without affecting convergence.
    converged = false; % Require the same three convergence tests as the replication.
    iter = 0; % Iteration counter

    % Loop until convergence or max iterations reached
    while iter < conv_params.max_iter
        iter = iter + 1;

        % Call the SOLVER function with explicit y and U_bar inputs
        [y_up, U_bar_up, scalist, varlist, density_up] = SOLVER(params, fund, y, U_bar, density);

        % Using damping sure predicted hat values are not too large or small
        y_up = max(0.9 * y, min(1.1 * y, y_up));
        U_bar_up = max(0.9 * U_bar, min(1.1 * U_bar, U_bar_up));
        density_up = max(0.9 * density, min(1.1 * density, density_up));


        % Check for convergence with relative tolerance.
        rel_y       = norm((y_up - y) ./ max(abs(y), 1e-8));
        rel_U_bar   = norm((U_bar_up - U_bar) ./ max(abs(U_bar), 1e-8));
        rel_density = norm((density_up - density) ./ max(abs(density), 1e-8));

        if toc(progress_clock) >= 5
            STATUS(conv_params,'Solving city equilibrium: iteration %d, largest relative update %.3g (tolerance %.3g).',iter,max([rel_y,rel_U_bar,rel_density]),conv_params.tol); % Report actual solver progress rather than a guessed completion percentage.
            progress_clock = tic; % Avoid flooding the Command Window.
        end
        if rel_y < conv_params.tol && rel_U_bar < conv_params.tol && rel_density < conv_params.tol
            converged = true; % Distinguish genuine convergence from iteration exhaustion.
            break;
        end

        % Update y and U_bar for the next iteration

        % if convergence type is chosen, increase convergence parameter (weight of updated value) for earlier iterations (see BASEDATA.m)
        if conv_params.type == "rich"
            conv_y = conv_params.A+(min(conv_params.conv, rel_y)-conv_params.A)/(1+exp(-conv_params.B*(iter-conv_params.M)))^(1/conv_params.v); 
            conv_U_bar = conv_params.A+(0.05-conv_params.A)/(1+exp(-conv_params.B*(iter-conv_params.M)))^(1/conv_params.v); 
            conv_density = conv_params.A+(0.25-conv_params.A)/(1+exp(-conv_params.B*(iter-conv_params.M)))^(1/conv_params.v); 
        elseif conv_params.type == "jump" & iter <= conv_params.jump_n
            conv_boost = min(1, ((conv_params.jump_m*iter+conv_params.jump_x*conv_params.max_iter)./((1+conv_params.jump_x)*conv_params.max_iter)));
            conv_y = min(conv_params.conv, rel_y).^conv_boost;
            conv_U_bar = 0.05.^conv_boost;
            conv_density = 0.25.^conv_boost;
        else
            conv_y = min(conv_params.conv, rel_y); 
            conv_U_bar = 0.05; 
            conv_density = 0.25; 
        end

        y=y_up.*conv_y+y.*(1-conv_y);
        U_bar=U_bar_up.*conv_U_bar+U_bar.*(1-conv_U_bar);
        density=density_up.*conv_density+density.*(1-conv_density);

        % Updated guesses stay local; callers pass them explicitly when needed.
    end
    if ~converged
        error('ABSJ2027:NoConvergence','Equilibrium did not converge in %d iterations (relative updates: wage %.3g, utility %.3g, density %.3g).',iter,rel_y,rel_U_bar,rel_density); % Never report failure as a solution.
    end
    if ~all(isfinite([scalist.N,scalist.L,scalist.AREA,y,U_bar,density])) || min([scalist.N,scalist.L,scalist.AREA,y,U_bar,density]) <= 0
        error('ABSJ2027:Infeasible','The inputs do not produce a finite, positive urban equilibrium.'); % Reject invalid solutions.
    end
    if ~any(varlist.COM) || ~any(varlist.URBAN & ~varlist.COM)
        error('ABSJ2027:Infeasible','The solution must contain both commercial and residential land.'); % Both markets must exist.
    end
    if scalist.x1 >= max(fund.D) && params.x1_max >= max(fund.D)
        error('ABSJ2027:Domain','The city reaches the numerical grid edge. Increase NUMERICS.radius and recalibrate the baseline.'); % Do not confuse grid truncation with a policy boundary.
    end
end
