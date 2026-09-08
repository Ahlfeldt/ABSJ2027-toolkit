function STATUS(options, message, varargin)
%STATUS Display readable progress; set options.verbose=false for quiet runs.
if isfield(options,'verbose') && ~options.verbose, return; end % Honor optional batch-mode silence.
fprintf('[ABSJ2027] '); % Distinguish toolkit progress from other Command Window output.
fprintf(message,varargin{:}); % Insert current targets, fit, or elapsed time.
fprintf('\n'); % Keep each update readable in saved logs as well as MATLAB.
drawnow limitrate; % Refresh the desktop while longer calculations are running.
end
