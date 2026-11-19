%% =========================================================================
%  Level1_Shockley.m  —  The Ideal Diode: Shockley Equation
%  =========================================================================
%  LEARNING OBJECTIVE
%    Understand why the diode I-V curve is exponential, not linear.
%    Connect the equation to physical intuition (energy barrier).
%
%  NEW CONCEPT THIS LEVEL
%    The Shockley diode equation:
%
%         I = IS * [ exp(V / (n * VT)) − 1 ]
%
%    where:
%      IS  = saturation current  — tiny leakage (~nA) set by doping & temperature
%      n   = ideality factor     — how "ideal" the junction is  (1 = perfect)
%      VT  = thermal voltage     — k_B*T/q ≈ 26 mV at 300 K
%
%  WHAT TO OBSERVE
%    · Current is nearly zero for V < ~0.5 V  (energy barrier not overcome)
%    · Current rises steeply near 0.6–0.7 V   (threshold / "turn-on" voltage)
%    · Below zero volts, current ≈ −IS        (tiny leakage, almost nothing)
%    · The curve is NOT symmetric: diodes strongly prefer one direction!
%
%  COMMON MISCONCEPTIONS
%    ✗ "The 0.7 V threshold is a hard wall" — it is a soft exponential knee
%    ✗ "IS is the reverse current" — IS is a model parameter, not measured directly
%    ✗ "n = 1 always" — real silicon diodes have n ≈ 1.5–2 due to recombination
% =========================================================================

function Level1_Shockley()

    p   = diode_params();
    heading(1, 'The Shockley Equation', '— What makes a diode a diode?');

    %% ── Console explanation ─────────────────────────────────────────────
    fprintf('\n  CONCEPT: The Ideal Diode\n');
    fprintf('  ─────────────────────────────────────────────────────────────\n');
    fprintf('  A diode is a one-way valve for electric current.\n');
    fprintf('  Inside, a p-n junction creates an energy barrier.\n\n');
    fprintf('  When you apply a POSITIVE voltage (forward bias):\n');
    fprintf('    → You push electrons over the barrier.\n');
    fprintf('    → Current rises exponentially with voltage.\n\n');
    fprintf('  When you apply a NEGATIVE voltage (reverse bias):\n');
    fprintf('    → The barrier grows even taller.\n');
    fprintf('    → Only a tiny leakage current flows (~nA).\n\n');

    fprintf('  THE SHOCKLEY EQUATION:\n\n');
    fprintf('       I  =  IS · [ exp( V / (n · VT) ) − 1 ]\n\n');

    VT = p.k_B * p.T0 / p.q;
    fprintf('  Parameters (1N4148 at 27°C / 300 K):\n');
    fprintf('    IS  = %.2e A   (saturation current — sets the leakage floor)\n', p.IS0);
    fprintf('    n   = %.3f       (ideality factor   — 1 = ideal, >1 = recombination)\n', p.n);
    fprintf('    VT  = %.1f mV   (thermal voltage   = k_B·T/q = 25.9 mV at 300K)\n', VT*1e3);
    fprintf('    n·VT= %.1f mV   (effective slope voltage)\n', p.n*VT*1e3);

    fprintf('\n  KEY INSIGHT — The exponential:\n');
    fprintf('    At V = 0.60 V:  exp(0.60 / %.4f) = %.1e\n', p.n*VT, exp(0.60/(p.n*VT)));
    fprintf('    At V = 0.70 V:  exp(0.70 / %.4f) = %.1e\n', p.n*VT, exp(0.70/(p.n*VT)));
    fprintf('    → Adding only 100 mV multiplies current by %.0fx!\n', exp(0.70/(p.n*VT))/exp(0.60/(p.n*VT)));

    %% ── Compute I-V ─────────────────────────────────────────────────────
    V   = linspace(-0.5, 1.0, 2000);
    I   = p.IS0 * (exp(V ./ (p.n * VT)) - 1);

    % Find threshold: where I first exceeds 1 mA
    V_thresh_idx = find(I >= 1e-3, 1, 'first');
    V_thresh     = V(V_thresh_idx);

    %% ── Figure ──────────────────────────────────────────────────────────
    fig = figure('Name','Level 1 — Shockley Equation', ...
                 'Position',[60 60 1000 520], ...
                 'Color',[0.97 0.97 0.98]);

    % ── Left panel: Linear scale ─────────────────────────────────────────
    ax1 = subplot(1,2,1);
    set(ax1,'Color',[1 1 1]);

    plot(V, I*1e3, 'b-', 'LineWidth', 2.5); hold on

    % Shade "OFF" and "ON" regions
    x_off = [-0.5 0.5 0.5 -0.5];
    y_off = [-0.5 -0.5 50 50];
    fill(x_off, y_off, [1 0.93 0.93], 'EdgeColor','none','FaceAlpha',0.5);

    x_on = [0.5 1.0 1.0 0.5];
    y_on = [-0.5 -0.5 50 50];
    fill(x_on, y_on, [0.9 1 0.9], 'EdgeColor','none','FaceAlpha',0.5);

    % Threshold marker
    plot([V_thresh V_thresh], [0 I(V_thresh_idx)*1e3], 'r--', 'LineWidth', 1.5);
    scatter(V_thresh, I(V_thresh_idx)*1e3, 60, 'r', 'filled');
    text(V_thresh+0.02, I(V_thresh_idx)*1e3+2, ...
         sprintf('Knee ≈ %.2f V\n(I = 1 mA)', V_thresh), ...
         'Color','r','FontSize',9,'FontWeight','bold');

    % Region labels
    text(-0.25, 30, {'REVERSE', 'BIAS', '(blocked)'}, ...
         'HorizontalAlignment','center','Color',[0.7 0.2 0.2], ...
         'FontSize',9,'FontWeight','bold');
    text(0.75, 30, {'FORWARD', 'BIAS', '(conducting)'}, ...
         'HorizontalAlignment','center','Color',[0.1 0.5 0.1], ...
         'FontSize',9,'FontWeight','bold');

    % Equation annotation
    annotation_box(ax1, 0.04, 0.68, ...
        {sprintf('I = IS · [exp(V/nVT) − 1]'), ...
         sprintf('IS = %.1e A', p.IS0), ...
         sprintf('n  = %.3f', p.n), ...
         sprintf('VT = %.1f mV', VT*1e3)});

    hold off; grid on; box on;
    xlabel('Applied Voltage  V  (V)', 'FontSize', 11);
    ylabel('Current  I  (mA)',        'FontSize', 11);
    title({'Level 1: Ideal Shockley Diode', '— Linear Scale'}, ...
          'FontSize', 12, 'FontWeight','bold');
    xlim([-0.5 1.0]); ylim([-0.5 50]);
    set(ax1,'FontSize',10);

    % ── Right panel: Log scale ───────────────────────────────────────────
    ax2 = subplot(1,2,2);
    set(ax2,'Color',[1 1 1]);

    fwd = V > 0.05 & I > 0;
    semilogy(V(fwd), I(fwd)*1e3, 'b-', 'LineWidth', 2.5); hold on

    % Show the slope triangle (one decade)
    V_s1 = 0.3; V_s2 = V_s1 + p.n*VT*log(10);   % one decade = n·VT·ln(10)
    I_s1 = p.IS0 * exp(V_s1/(p.n*VT)) * 1e3;
    plot([V_s1 V_s2 V_s2], [I_s1 I_s1 I_s1*10], 'r-', 'LineWidth', 2);
    text(V_s2+0.01, sqrt(I_s1*I_s1*10), ...
         sprintf('×10 per\n%.0f mV', p.n*VT*log(10)*1e3), ...
         'Color','r','FontSize',9);

    % Highlight leakage floor
    yline(p.IS0*1e3, 'k:', 'LineWidth', 1.5, ...
          'Label', sprintf('IS = %.1e A (leakage floor)', p.IS0));

    hold off; grid on; box on;
    xlabel('Applied Voltage  V  (V)', 'FontSize', 11);
    ylabel('Current  I  (mA)  — log scale', 'FontSize', 11);
    title({'Level 1: Ideal Shockley Diode', '— Log Scale (reveals exponential slope)'}, ...
          'FontSize', 12, 'FontWeight','bold');
    xlim([0.05 0.9]);
    set(ax2,'FontSize',10);

    sgtitle(sprintf('1N4148  ·  Level 1: The Shockley Equation\nIS = %.2e A  |  n = %.3f  |  VT = %.1f mV at 300 K', ...
            p.IS0, p.n, VT*1e3), 'FontWeight','bold','FontSize',12);

    %% ── Learning summary ────────────────────────────────────────────────
    print_separator('LEVEL 1 — LEARNING SUMMARY');
    fprintf('\n  ✅  The Shockley equation I = IS·[exp(V/nVT)−1] governs ideal diodes.\n');
    fprintf('  ✅  Current is EXPONENTIAL in voltage — not linear like a resistor.\n');
    fprintf('  ✅  The "0.7 V threshold" is the knee of the exponential, not a wall.\n');
    fprintf('  ✅  Reverse current ≈ −IS ≈ nanoamps — the junction blocks current.\n');
    fprintf('  ✅  Log scale reveals the straight-line slope = 1/(n·VT).\n');
    fprintf('\n  NEXT: Level 2 — Why can''t current grow to infinity?\n');
    fprintf('         Run:  Level2_SeriesResistance\n\n');
end

% ─────────────────────────────────────────────────────────────────────────────
function annotation_box(ax, x, y, lines)
    % Place a text box at normalized axes position
    str = strjoin(lines, newline);
    text(ax, x, y, str, 'Units','normalized', ...
         'FontSize', 9, 'FontName','Courier', ...
         'BackgroundColor', [0.95 0.95 1], ...
         'EdgeColor', [0.5 0.5 0.7], ...
         'Margin', 4, 'VerticalAlignment','top');
end
