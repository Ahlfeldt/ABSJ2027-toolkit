function [params, y, U_bar, scalist, varlist, iter, density] = FINDUtilde(params, fund, conv_params, mu, initial)
%FINDUTILDE Recover the rural-utility primitive for a target urban share.
if nargin < 5, initial = []; end % Use original equilibrium guesses if unspecified.
progress_clock = tic; % Time progress updates independently of the numerical iteration.
for iter = 1:conv_params.max_iter % Bound the number of outer inversion steps.
    [y,U_bar,scalist,varlist,~,density] = EQFIND(params,fund,conv_params,initial); % Solve for the current rural primitive.
    initial = struct('y',y,'U_bar',U_bar,'density',density); % Explicitly carry forward the solved state.
    rel_error = abs((scalist.N/params.N_bar-mu)/max(abs(mu),1e-8)); % Relative urban-share mismatch.
    if toc(progress_clock) >= 5
        STATUS(conv_params,'Matching urbanization: iteration %d, current %.2f%%, target %.2f%%.',iter,100*scalist.N/params.N_bar,100*mu); % Reassure users during long moment matching.
        progress_clock = tic; % Limit output to approximately one update every five seconds.
    end
    if rel_error < conv_params.tol_U
        return; % Return the actual primitive used in this equilibrium, without a final unmatched update.
    end
    U_tilde_up = U_bar.^params.zeta .* ((1-mu)/mu); % Invert the rural/urban population-choice equation.
    conv_U = conv_params.conv_U ./ (1+exp(-1000.*abs(U_tilde_up-params.U_tilde)+1)); % Replication damping.
    if conv_params.type == "rich"
        conv_U = conv_params.A_U+(conv_U-conv_params.A_U)/(1+exp(-conv_params.B_U*(iter-conv_params.M_U)))^(1/conv_params.v_U); % Replication early acceleration.
    elseif conv_params.type == "jump" && iter <= conv_params.jump_n_U
        conv_boost = min(1,(conv_params.jump_m_U*iter+conv_params.jump_x_U*conv_params.max_iter)./((1+conv_params.jump_x_U)*conv_params.max_iter)); % Alternative acceleration exponent.
        conv_U = conv_U.^conv_boost; % Apply the chosen early weight.
    end
    params.U_tilde = conv_U*U_tilde_up+(1-conv_U)*params.U_tilde; % Update only the rural primitive.
end
error('ABSJ2027:Inversion','Rural-utility inversion did not match urbanization after %d iterations (relative error %.3g).',iter,rel_error); % Surface failure.
end
