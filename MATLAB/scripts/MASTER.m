%% ABSJ2027: Default entry point
% Run MASTER_PAPER for the paper parameterization, or MASTER_EMPIRICAL to fit observed city moments.
run(fullfile(fileparts(mfilename('fullpath')),'MASTER_PAPER.m')); % Preserve the original entry point with the paper baseline as default.
