function [params, fund, changed] = APPLY_CHANGES(baseline, changes)
%APPLY_CHANGES Apply absolute or percentage overrides to the saved baseline.
params = baseline.params; fund = baseline.fund; changed = false; % Always start from an independent baseline copy.
if isempty(changes), return; end % Support an omitted/empty counterfactual.
if ~isstruct(changes) || ~isscalar(changes), error('ABSJ2027:Changes','changes must be a scalar structure.'); end % Require documented syntax.
if any(~ismember(fieldnames(changes),{'set','pct'})), error('ABSJ2027:Changes','Use changes.set or changes.pct.'); end % Catch misspelled operations.
absolute = struct(); relative = struct(); % Empty operation lists are valid.
if isfield(changes,'set'), absolute = changes.set; end % Read absolute replacements.
if isfield(changes,'pct'), relative = changes.pct; end % Read percentage changes.
if ~isstruct(absolute) || ~isscalar(absolute) || ~isstruct(relative) || ~isscalar(relative)
    error('ABSJ2027:Changes','Both set and pct must be scalar structures.'); % Avoid ambiguous overrides.
end
if ~isempty(intersect(fieldnames(absolute),fieldnames(relative)))
    error('ABSJ2027:Changes','A variable cannot appear in both changes.set and changes.pct.'); % Reject conflicting instructions.
end
operations = {absolute,relative}; % Evaluate independent operations from the same baseline.
for operation = 1:2
    names = fieldnames(operations{operation}); % Select the requested variables.
    for k = 1:numel(names)
        name = names{k}; value = operations{operation}.(name); % Read the named override.
        is_spatial = ismember(name,{'a_rand_C','a_rand_R'}); % Only these grid fields are user fundamentals.
        if isfield(params,name), old = params.(name); elseif is_spatial, old = fund.(name); else
            error('ABSJ2027:Changes','Unknown parameter or fundamental: %s.',name); % Catch typos before solving.
        end
        validateattributes(value,{'numeric'},{'real','nonempty','nonnan'},'ABSJ2027',name); % Disallow missing or non-numeric changes.
        if operation == 2
            if any(~isfinite(old(:))) || any(old(:)==0) || any(~isfinite(value(:)))
                error('ABSJ2027:Changes','Use changes.set for %s: percentages require finite, nonzero baseline values and finite changes.',name); % Avoid Inf and zero percentage ambiguities.
            end
            value = old.*(1+value/100); % X means X percent, not a fractional rate.
        end
        if is_spatial
            if isscalar(value), value = repmat(value,size(fund.D)); end % Uniform spatial multipliers are convenient.
            fund.(name) = value; % Retain location-specific fundamentals if supplied.
        else
            params.(name) = value; % Change only the explicitly named scalar parameter.
        end
        changed = true; % Distinguish a specified zero shock from no counterfactual.
    end
end
VALIDATE_INPUTS(params,fund); % Check the joint resulting parameterization.
end
