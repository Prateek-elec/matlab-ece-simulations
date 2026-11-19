function heading(level, title, subtitle)
    fprintf('\n');
    fprintf('┌────────────────────────────────────────────────────────────┐\n');
    fprintf('│  LEVEL %d  ·  %-50s│\n', level, title);
    if nargin > 2 && ~isempty(subtitle)
        fprintf('│  %-60s│\n', subtitle);
    end
    fprintf('└────────────────────────────────────────────────────────────┘\n');
end
