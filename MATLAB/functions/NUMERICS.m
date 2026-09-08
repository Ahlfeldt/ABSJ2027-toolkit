function options = NUMERICS()
%NUMERICS Numerical controls, separate from the economic inputs in MASTER.
% The grid and damping defaults reproduce BASEDATA in the replication.
options.verbose = true;           % Show progress in the Command Window; false makes batch runs quiet.
options.radius = 100;             % Fixed regional land-accounting radius, km.
options.spacing = 0.01;           % Radial grid spacing, km (10 metres).
options.conv = 0.01;              % Late-iteration weight for wage updates.
options.conv_U = 0.5;             % Rural-utility inversion damping.
options.tol = 0.001;              % Relative equilibrium tolerance.
options.tol_U = 0.001;            % Relative urban-share matching tolerance.
options.max_iter = 1000;          % Maximum iterations before a visible error.
options.type = "rich";            % Replication's early-iteration acceleration.
options.A = 0.98;                 % Initial equilibrium update weight.
options.B = 1;                    % Transition steepness.
options.v = 1;                    % Transition shape.
options.M = 8;                    % Equilibrium transition midpoint.
options.A_U = 0.99;               % Initial inversion update weight.
options.B_U = 1;                  % Inversion transition steepness.
options.v_U = 1;                  % Inversion transition shape.
options.M_U = 22;                 % Inversion transition midpoint.
options.jump_x = 0.0002;          % Retained alternative damping control.
options.jump_m = 7.5;             % Retained alternative damping control.
options.jump_n = 7;               % Number of accelerated equilibrium steps.
options.jump_x_U = 0.001;         % Retained alternative inversion control.
options.jump_m_U = 0.2;           % Retained alternative inversion control.
options.jump_n_U = 22;            % Number of accelerated inversion steps.
options.hg_tol = 0.01;           % Maximum absolute height-gap matching error.
options.hg_max_iter = 250;       % Maximum height-cap search iterations.
options.hg_max_evals = 300;      % Maximum height-gap objective evaluations.
end
