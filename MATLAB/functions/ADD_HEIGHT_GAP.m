function city = ADD_HEIGHT_GAP(city)
%ADD_HEIGHT_GAP Measure lost tall floor space relative to the same city's unrestricted-height equilibrium.
if isfield(city.diagnostics,'height_gap_identified') && isfield(city.diagnostics,'height_gap')
    identified=city.diagnostics.height_gap_identified; gap=city.diagnostics.height_gap; % Reuse the calibrated benchmark when already computed.
else
    free=city.params; free.S_bar_R=Inf; free.S_bar_C=Inf; % Remove only vertical limits; retain the scenario's other fundamentals and growth boundary.
    if isinf(city.params.S_bar_R) && isinf(city.params.S_bar_C)
        unrestricted=city.scalist; % An already unrestricted city is its own benchmark.
    else
        STATUS(city.options,'Measuring height gap against the same city without height limits.'); % Explain the additional equilibrium solve.
        [~,~,unrestricted]=EQFIND(free,city.fund,city.options,city.initial); % Keep rural utility and regional population fixed in the comparison.
    end
    identified=unrestricted.F_tallE>1e-10; % A positive unrestricted quantity above T is required for a defined ratio.
    gap=NaN; % Undefined is not a zero gap when no tall development is possible.
    if identified, gap=1-city.scalist.F_tallE/unrestricted.F_tallE; end % Use excess floor space above T, consistent with the paper's inversion.
end
if ~identified, gap=NaN; end % Override the inversion's zero-gap shortcut for an undefined reported statistic.
city.scalist.height_gap=gap; % Save the realized fraction for tables and machine-readable results.
city.diagnostics.height_gap_identified=identified; % Retain the denominator diagnostic.
city.diagnostics.height_gap_outcome=gap; % Distinguish the outcome from any calibration shortcut.
end
