function print_separator(title)
    n = 64;
    line = repmat('─', 1, n);
    if nargin == 0 || isempty(title)
        fprintf('  %s\n', line);
    else
        pad = max(0, n - length(title) - 4);
        fprintf('\n  ── %s %s\n', title, repmat('─', 1, pad));
    end
end

% ─────────────────────────────────────────────────────────────────────────────
