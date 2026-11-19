%% =========================================================================
%  Level2_SeriesResistance.m  —  Series Resistance: Real Diodes Have Limits
%  =========================================================================
%  LEARNING OBJECTIVE
%    Understand why the current in a real diode cannot grow exponentially
%    forever, and how a small resistor fundamentally changes the I-V curve.
%
%  NEW CONCEPT THIS LEVEL  (only one!)
%    Series resistance  Rs:
%      The diode junction is reached through bulk semiconductor material.
%      That material has resistance.  The external voltage now splits:
%
%           V_ext  =  Vd  +  I · Rs
%                     ↑           ↑
%                 junction    resistive
%                  voltage      drop
%
%      So the junction "sees" less voltage than you apply — and at high
%      currents the resistor dominates, turning the curve nearly linear.
%
%  WHAT TO OBSERVE (3 clear effects)
%    1. High-current "knee" — curve bends and linearises above ~100 mA
%    2. Slope at high current = 1/Rs  (the resistor, not the junction)
%    3. Below ~10 mA the two curves are nearly identical  (Rs not visible)
%
%  COMMON MISCONCEPTIONS
%    ✗ "Rs is external — I can ignore it" — no, it is inside the diode package
%    ✗ "Rs limits reverse current too" — yes, but reverse I is so tiny it does not matter
%    ✗ "Once I add Rs the model is complete" — still no breakdown, no T effects
% =========================================================================

function Level2_SeriesResistance()

    p   = diode_params();
    heading(2, 'Series Resistance', '— Real diodes are not ideal');

    %% ── Console explanation ─────────────────────────────────────────────
    fprintf('\n  CONCEPT: Series Resistance Rs\n');
    fprintf('  ─────────────────────────────────────────────────────────────\n');
    fprintf('  Inside the diode package, electrons must travel through:\n');
    fprintf('    · the bulk silicon  (not a perfect conductor)\n');
    fprintf('    · the metal contacts and bond wires\n');
    fprintf('  All of this adds a small resistance IN SERIES with the junction.\n\n');
    fprintf('  For the 1N4148:\n');
    fprintf('    Rs = %.1f Ω  (surprisingly small, but very important at high I)\n\n', p.Rs);

    fprintf('  MODIFIED EQUATION  (Newton-Raphson must be used — no closed form):\n\n');
    fprintf('       V_ext  =  Vd  +  I · Rs\n');
    fprintf('       I      =  IS · [ exp(Vd / (n·VT)) − 1 ]\n\n');

    fprintf('  FEEL IT  — at different current levels:\n');
    I_examples = [1e-3, 10e-3, 100e-3, 300e-3];
    for I_ex = I_examples
        Vdrop = I_ex * p.Rs;
        fprintf('    I = %5.0f mA  →  Rs drop = %.0f × %.1f = %.1f mV  (%.0f%% of Vd)\n', ...
                I_ex*1e3, I_ex*1e3, p.Rs, Vdrop*1e3, Vdrop/0.7*100);
    end

    %% ── Compute I-V ─────────────────────────────────────────────────────
    V    = linspace(-0.1, 1.4, 3000);
    VT   = p.k_B * p.T0 / p.q;

    % Level 1: ideal  (no Rs — use enormous Rs trick: set Rs=1e-6 Ω)
    [I_ideal, Vd_ideal] = solveI(V, p.IS0, p.n, p.T0, 1e-6, 1e9, 0, p.Vz);

    % Level 2: with Rs
    [I_real,  Vd_real ] = solveI(V, p.IS0, p.n, p.T0, p.Rs, 1e9, 0, p.Vz);

    % Ohmic line: slope = 1/Rs through the operating point at 200 mA
    V_op   = 0.9;
    I_op   = interp1(V, I_real, V_op);
    V_ohm  = linspace(0.5, 1.35, 100);
    I_ohm  = I_op + (V_ohm - V_op) / p.Rs;

    %% ── Figure ──────────────────────────────────────────────────────────
    fig = figure('Name','Level 2 — Series Resistance', ...
                 'Position',[60 60 1050 500], ...
                 'Color',[0.97 0.97 0.98]);

    % ── Left panel: linear, emphasis on high current ─────────────────────
    ax1 = subplot(1,2,1);
    set(ax1,'Color',[1 1 1]);

    plot(V, I_ideal*1e3, '--', 'Color',[0.7 0.7 0.7], 'LineWidth', 2.0); hold on
    plot(V, I_real *1e3, 'b-',                         'LineWidth', 2.5);

    % Ohmic tangent
    ok = I_ohm > 0 & I_ohm < 450;
    plot(V_ohm(ok), I_ohm(ok)*1e3, 'r-.', 'LineWidth', 1.5);
    text(1.15, 350, sprintf('Slope = 1/R_s\n= %.0f S', 1/p.Rs), ...
         'Color','r','FontSize',9,'FontWeight','bold');

    % Rated current line
    yline(p.I_rated*1e3, 'k:', 'LineWidth', 1.2, ...
          'Label','I_{rated} = 300 mA','FontSize',9);

    % Arrow showing divergence
    arrow_x = [0.88 0.96];
    arrow_y = [interp1(V,I_ideal,0.88)*1e3, interp1(V,I_ideal,0.96)*1e3];
    plot(arrow_x, arrow_y, 'Color',[0.7 0.7 0.7], 'LineWidth',3);
    text(0.92, 370, {'Ideal: keeps', 'rising steeply'}, ...
         'Color',[0.5 0.5 0.5],'FontSize',8,'HorizontalAlignment','center');

    text(0.80, 200, {'Real: Rs bends', 'curve toward linear'}, ...
         'Color','b','FontSize',8.5,'FontWeight','bold');

    hold off; grid on; box on;
    xlabel('Applied Voltage  V_{ext}  (V)', 'FontSize', 11);
    ylabel('Current  I  (mA)',              'FontSize', 11);
    title({'Level 2: Effect of Series Resistance', '— Linear scale, focus on high current'}, ...
          'FontSize', 12, 'FontWeight','bold');
    legend('L1: Ideal (no Rs)', 'L2: Real (Rs = 0.5 Ω)', 'Ohmic tangent', ...
           'Location','nw', 'FontSize', 9);
    xlim([-0.1 1.4]); ylim([-5 450]);
    set(ax1,'FontSize',10);

    % ── Right panel: log scale, low-current region ────────────────────────
    ax2 = subplot(1,2,2);
    set(ax2,'Color',[1 1 1]);

    fwd_i = V > 0.1 & I_ideal > 0;
    fwd_r = V > 0.1 & I_real  > 0;
    semilogy(V(fwd_i), I_ideal(fwd_i)*1e3, '--','Color',[0.7 0.7 0.7],'LineWidth',2.0); hold on
    semilogy(V(fwd_r), I_real (fwd_r)*1e3, 'b-','LineWidth',2.5);

    % Mark where curves begin to diverge (> 1% difference)
    [~,sep_idx] = max(abs(I_ideal - I_real) ./ (abs(I_ideal)+1e-12) > 0.01);
    if sep_idx > 1
        text(V(sep_idx), I_real(sep_idx)*1e3*1.5, ...
             sprintf('←  Diverge here\n    (I ≈ %.0f mA)', I_real(sep_idx)*1e3), ...
             'FontSize',9,'Color','m');
    end

    % Annotate Rs voltage drop at two points
    for V_pt = [0.7 0.9]
        I_pt  = interp1(V, I_real, V_pt);
        Vd_pt = interp1(V, Vd_real, V_pt);
        drop  = (V_pt - Vd_pt)*1e3;
        if I_pt > 1e-5
            scatter(V_pt, I_pt*1e3, 40, 'r', 'filled');
            text(V_pt+0.01, I_pt*1e3*0.6, ...
                 sprintf('Rs drop\n= %.0f mV', drop), ...
                 'FontSize',8,'Color','r');
        end
    end

    hold off; grid on; box on;
    xlabel('Applied Voltage  V_{ext}  (V)', 'FontSize', 11);
    ylabel('Current  I  (mA)  — log scale', 'FontSize', 11);
    title({'Level 2: Log Scale', '— Identical at low I, diverge at high I'}, ...
          'FontSize', 12, 'FontWeight','bold');
    legend('L1: Ideal', 'L2: +R_s', 'Location','nw','FontSize',9);
    xlim([0.1 1.2]);
    set(ax2,'FontSize',10);

    sgtitle('1N4148  ·  Level 2: Series Resistance  Rs = 0.5 Ω', ...
            'FontWeight','bold','FontSize',12);

    %% ── Learning summary ────────────────────────────────────────────────
    print_separator('LEVEL 2 — LEARNING SUMMARY');
    fprintf('\n  ✅  Rs is a parasitic resistance inside every real diode.\n');
    fprintf('  ✅  At low current: Rs drop is tiny → ideal and real curves match.\n');
    fprintf('  ✅  At high current: Rs drop is large → curve goes LINEAR.\n');
    fprintf('  ✅  High-current slope = 1/Rs = %.0f A/V.\n', 1/p.Rs);
    fprintf('  ✅  Rs prevents infinite current — a natural current limiter.\n');
    fprintf('\n  NEXT: Level 3 — What happens below −100 V?\n');
    fprintf('         Run:  Level3_Breakdown\n\n');
end
