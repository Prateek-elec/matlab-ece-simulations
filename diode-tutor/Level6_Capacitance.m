%% =========================================================================
%  Level6_Capacitance.m  —  Junction Capacitance: Diodes Store Charge
%  =========================================================================
%  LEARNING OBJECTIVE
%    Understand that the p-n junction behaves like a voltage-controlled
%    capacitor — and why this matters at high frequencies.
%
%  NEW CONCEPT THIS LEVEL
%    Junction (depletion) capacitance:
%
%         Cj(Vd) = Cj0 / (1 − Vd/Vj)^M
%
%    Parameters:
%      Cj0 = zero-bias capacitance  (1N4148: ~4 pF)
%      Vj  = built-in potential     (~0.7 V for Si)
%      M   = grading coefficient    (0.33 for linearly graded, 0.5 for abrupt)
%
%  PHYSICAL PICTURE
%    When you reverse-bias a diode, the depletion region (the charge-free
%    zone at the junction) WIDENS.  This is like pulling apart the plates
%    of a capacitor → capacitance DECREASES.
%
%    When you forward-bias, the depletion region NARROWS → Cj INCREASES.
%
%    At RF and high-speed digital frequencies, Cj limits the diode's
%    switching speed.  Varactor diodes exploit this intentionally!
%
%  TWO CAPACITANCE COMPONENTS
%    Cj  = depletion capacitance  (dominant in reverse bias)
%    Cd  = diffusion capacitance  = τ_F · gm  (dominant in forward bias)
%         where gm = dI/dVd = IS·exp(Vd/nVT)/(n·VT)
%
%  WHAT TO OBSERVE
%    · Cj vs reverse voltage: monotonically decreasing (wider depletion region)
%    · Different M values: M=0.5 gives steeper slope (abrupt junction)
%    · Diffusion cap Cd: rises steeply in forward bias → dominates at high I
%    · Impedance 1/(ω·C): at 100 MHz, even 4 pF = 400 Ω — significant!
%
%  COMMON MISCONCEPTIONS
%    ✗ "Capacitance doesn't matter at low frequencies" — true for <1 MHz
%    ✗ "Cj formula works in forward bias" — only up to ~0.9·Vj; use Cd there
%    ✗ "Smaller diode = smaller Cj" — yes, that is why small-signal diodes exist
% =========================================================================

function Level6_Capacitance()

    p   = diode_params();
    heading(6, 'Junction Capacitance', '— Diodes behave like capacitors at high frequency');

    %% ── Console explanation ─────────────────────────────────────────────
    fprintf('\n  CONCEPT: The p-n Junction as a Capacitor\n');
    fprintf('  ─────────────────────────────────────────────────────────────\n');
    fprintf('  The depletion region is like a capacitor with a voltage-dependent gap.\n');
    fprintf('  Wider depletion → less capacitance (plates farther apart).\n\n');

    fprintf('  JUNCTION CAPACITANCE MODEL:\n\n');
    fprintf('       Cj(Vd)  =  Cj0 / (1 − Vd/Vj)^M\n\n');
    fprintf('    Cj0 = %.0f pF  (zero-bias capacitance, at Vd = 0)\n', p.Cj0*1e12);
    fprintf('    Vj  = %.1f V   (built-in potential, ≈ contact voltage)\n', p.Vj);
    fprintf('    M   = %.2f    (grading: 0.33=linear, 0.5=abrupt junction)\n\n', p.M_cap);

    fprintf('  CAPACITANCE AT KEY BIAS POINTS:\n');
    V_pts = [0, -5, -10, -30, -50];
    for V_pt = V_pts
        Vd_pt = min(V_pt, 0.9*p.Vj);
        Cj_pt = p.Cj0 / (1 - Vd_pt/p.Vj)^p.M_cap;
        fprintf('    Vd = %4.0f V:  Cj = %.1f pF', V_pt, Cj_pt*1e12);
        if V_pt < 0, fprintf('  (%.0f%% of Cj0)', Cj_pt/p.Cj0*100); end
        fprintf('\n');
    end

    fprintf('\n  IMPEDANCE at 100 MHz  (Xc = 1/(2πf·C)):\n');
    f_rf = 100e6;
    for V_pt = [0, -10, -30]
        Vd_pt = min(V_pt, 0.9*p.Vj);
        Cj_pt = p.Cj0 / (1 - Vd_pt/p.Vj)^p.M_cap;
        Xc    = 1 / (2*pi*f_rf*Cj_pt);
        fprintf('    Vd = %4.0f V:  Cj = %.1f pF  →  Xc = %.0f Ω at %.0f MHz\n', ...
                V_pt, Cj_pt*1e12, Xc, f_rf*1e-6);
    end

    fprintf('\n  VARACTOR APPLICATION:\n');
    fprintf('    Tuning range (V=0 to V=−30 V):\n');
    C0  = p.Cj0;
    C30 = p.Cj0 / (1 + 30/p.Vj)^p.M_cap;
    fprintf('    Cj(0) = %.1f pF  →  Cj(−30V) = %.2f pF\n', C0*1e12, C30*1e12);
    fprintf('    Frequency tuning ratio: f_max/f_min = √(Cj0/Cj30) = %.1fx\n', sqrt(C0/C30));

    %% ── Compute capacitance ──────────────────────────────────────────────
    V     = linspace(-50, 1.0, 3000);
    [~, Vd] = solveI(V, p.IS0, p.n, p.T0, p.Rs, p.V_BR, p.IBR0, p.Vz);

    % Depletion capacitance
    Vd_cap = min(Vd, 0.90*p.Vj);
    Cj     = p.Cj0 ./ (1 - Vd_cap/p.Vj).^p.M_cap;

    % Compare different grading coefficients
    M_vals  = [0.33, 0.50, 0.20];
    M_names = {'M=0.33 (linear graded)', 'M=0.50 (abrupt junction)', 'M=0.20 (hyperabrupt varactor)'};
    colors  = {[0 0.4 0.9], [0.8 0.1 0.1], [0 0.6 0.3]};

    % Diffusion capacitance (forward bias)
    VT    = p.k_B * p.T0 / p.q;
    fwd   = V > 0 & V < 0.85;
    I_fwd = p.IS0 * (exp(min(Vd(fwd)/(p.n*VT), 40)) - 1);
    gm    = I_fwd ./ (p.n * VT);
    Cd    = p.tau_F .* gm;

    %% ── Figure ──────────────────────────────────────────────────────────
    fig = figure('Name','Level 6 — Junction Capacitance', ...
                 'Position',[60 60 1150 560], ...
                 'Color',[0.97 0.97 0.98]);

    % ── Top-left: Cj vs reverse voltage, physical annotation ─────────────
    ax1 = subplot(2,2,1);
    set(ax1,'Color',[1 1 1]);

    rev = V >= -50 & V <= 0.6;
    for k = 1:length(M_vals)
        Cj_k = p.Cj0 ./ (1 - min(Vd(rev),0.9*p.Vj)/p.Vj).^M_vals(k);
        plot(V(rev), Cj_k*1e12, '-', 'Color', colors{k}, ...
             'LineWidth', 2.2, 'DisplayName', M_names{k}); hold on
    end

    yline(p.Cj0*1e12, 'k:', 'LineWidth', 1.5, ...
          'Label', sprintf('C_{j0} = %.0f pF', p.Cj0*1e12));
    xline(0, 'k:', 'LineWidth', 1);
    hold off; grid on; box on;
    xlabel('Voltage  V_{ext}  (V)',  'FontSize', 10);
    ylabel('C_j  (pF)',              'FontSize', 10);
    title({'Depletion Capacitance', 'C_j decreases as reverse bias increases'}, ...
          'FontSize', 10, 'FontWeight','bold');
    legend('Location','ne','FontSize',8);
    xlim([-50 0.6]); ylim([0 14]);
    set(ax1,'FontSize',9);

    % ── Top-right: Zoom on −10 to 0 V, show varactor tuning ──────────────
    ax2 = subplot(2,2,2);
    set(ax2,'Color',[1 1 1]);

    z = V >= -10 & V <= 0.5;
    Cj_z = p.Cj0 ./ (1 - min(Vd(z),0.9*p.Vj)/p.Vj).^p.M_cap;
    plot(V(z), Cj_z*1e12, 'b-', 'LineWidth', 2.5); hold on

    % Shade tuning range
    fill([V(z) fliplr(V(z))], [Cj_z*1e12 zeros(1,sum(z))], ...
         [0.7 0.8 1], 'EdgeColor','none','FaceAlpha',0.4);

    % Mark endpoints
    scatter([0 -10], [p.Cj0*1e12, interp1(V(z), Cj_z*1e12, -10)], 60, 'r', 'filled');

    text(-1.5, p.Cj0*1e12+0.3, sprintf('C_{j0} = %.0f pF\n(V = 0)', p.Cj0*1e12), ...
         'FontSize', 9, 'Color','r', 'HorizontalAlignment','right');
    text(-8, interp1(V(z),Cj_z*1e12,-10)-0.5, ...
         sprintf('%.1f pF\nat −10V', interp1(V(z),Cj_z*1e12,-10)), ...
         'FontSize', 9, 'Color','r');

    hold off; grid on; box on;
    xlabel('Voltage  V_{ext}  (V)', 'FontSize', 10);
    ylabel('C_j  (pF)',             'FontSize', 10);
    title({'Zoom: Varactor Tuning Range', 'Bias voltage tunes capacitance'}, ...
          'FontSize', 10, 'FontWeight','bold');
    xlim([-10 0.5]); ylim([0 10]);

    % ── Bottom-left: Diffusion cap in forward bias ────────────────────────
    ax3 = subplot(2,2,3);
    set(ax3,'Color',[1 1 1]);

    Vfwd = V(fwd);
    plot(Vfwd, Cd*1e12, 'g-', 'LineWidth', 2.2); hold on
    plot(Vfwd, p.Cj0 ./ (1 - min(Vd(fwd),0.9*p.Vj)/p.Vj).^p.M_cap * 1e12, ...
         'b--', 'LineWidth', 1.8);

    text(0.6, max(Cd)*0.8e12, {'Cd = τ_F · gm', '(grows with I)'}, ...
         'Color', [0 0.5 0], 'FontSize', 9, 'FontWeight','bold');
    text(0.3, 5.5, {'Cj (depletion)', '(nearly constant)'}, ...
         'Color', 'b', 'FontSize', 9);

    hold off; grid on; box on;
    xlabel('Voltage V_{ext} (V)', 'FontSize', 10);
    ylabel('Capacitance (pF)',    'FontSize', 10);
    title({'Forward Bias: Diffusion vs Depletion Cap', 'C_d dominates at high forward current'}, ...
          'FontSize', 10, 'FontWeight','bold');
    legend('C_d diffusion  (τ_F·g_m)', 'C_j depletion', 'Location','nw', 'FontSize', 8);
    xlim([0 0.85]); ylim([0 200]);

    % ── Bottom-right: Impedance vs frequency ─────────────────────────────
    ax4 = subplot(2,2,4);
    set(ax4,'Color',[1 1 1]);

    f = logspace(5, 10, 500);    % 100 kHz to 10 GHz
    V_bias_vals = [0, -5, -30];
    bias_colors = {[0.8 0.2 0.2], [0.1 0.5 0.1], [0.1 0.1 0.8]};

    for k = 1:length(V_bias_vals)
        Vd_b  = min(V_bias_vals(k), 0.9*p.Vj);
        Cj_b  = p.Cj0 / (1 - Vd_b/p.Vj)^p.M_cap;
        Xc_b  = 1 ./ (2*pi.*f.*Cj_b);
        loglog(f*1e-6, Xc_b, '-', 'Color', bias_colors{k}, 'LineWidth', 2.0, ...
               'DisplayName', sprintf('V_{bias} = %d V  (C_j=%.1fpF)', V_bias_vals(k), Cj_b*1e12));
        hold on
    end

    xline(100, 'k:', 'LineWidth', 1, 'Label','100 MHz','FontSize',8);
    xline(1000,'k:', 'LineWidth', 1, 'Label','1 GHz',  'FontSize',8);
    hold off; grid on; box on;
    xlabel('Frequency (MHz)', 'FontSize', 10);
    ylabel('Impedance  X_c = 1/(2πfC)  (Ω)', 'FontSize', 10);
    title({'Capacitive Impedance vs Frequency', 'Cj creates a short-circuit path at RF'}, ...
          'FontSize', 10, 'FontWeight','bold');
    legend('Location','sw', 'FontSize', 8);
    xlim([0.1 1e4]);

    sgtitle('1N4148  ·  Level 6: Junction Capacitance  C_{j0} = 4 pF  |  V_j = 0.7 V  |  M = 0.33', ...
            'FontWeight','bold','FontSize',11);

    %% ── Learning summary ────────────────────────────────────────────────
    print_separator('LEVEL 6 — LEARNING SUMMARY');
    fprintf('\n  ✅  Depletion capacitance Cj = Cj0/(1−Vd/Vj)^M: decreases with reverse bias.\n');
    fprintf('  ✅  Wider depletion region = more distance between "capacitor plates".\n');
    fprintf('  ✅  Grading coefficient M controls how steeply Cj varies with voltage.\n');
    fprintf('  ✅  Diffusion capacitance Cd = τ_F·gm dominates in forward bias.\n');
    fprintf('  ✅  At 100 MHz, even 4 pF has ~400 Ω impedance — significant in RF circuits.\n');
    fprintf('  ✅  Varactors exploit this: tune resonant frequency by changing bias.\n');
    fprintf('\n  NEXT: Level 7 — Why does current still flow after you switch a diode OFF?\n');
    fprintf('         Run:  Level7_ReverseRecovery\n\n');
end
