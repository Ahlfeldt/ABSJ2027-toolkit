function escaped = TEX_ESCAPE(value)
%TEX_ESCAPE Quote plain table labels safely for use in LaTeX text.
value = char(string(value)); % Normalize MATLAB text to individual characters.
escaped = ''; % Accumulate escaped characters without re-escaping replacements.
for k = 1:numel(value)
    switch value(k)
        case '\', replacement = '\textbackslash{}'; % Print literal backslashes.
        case {'&','%','$','#','_','{','}'}, replacement = ['\' value(k)]; % Protect LaTeX syntax characters.
        case '^', replacement = '\textasciicircum{}'; % Preserve plain-text powers in unit labels.
        case '~', replacement = '\textasciitilde{}'; % Preserve literal tildes.
        otherwise, replacement = value(k); % Leave ordinary text unchanged.
    end
    escaped = [escaped replacement]; %#ok<AGROW> % Labels are short; preserve their exact order.
end
end
