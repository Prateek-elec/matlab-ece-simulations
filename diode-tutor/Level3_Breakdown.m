%% =========================================================================
%  Level3_Breakdown.m  —  Reverse Breakdown: Avalanche and Zener
%  =========================================================================
%  LEARNING OBJECTIVE
%    Understand that diodes DO conduct in reverse — but only beyond a
%    threshold voltage called the breakdown voltage (V_BR).
%    Learn the difference between avalanche and Zener mechanisms.
%
%  NEW CONCEPT THIS LEVEL
%    Soft reverse breakdown model:
%
%         I_brk = −IBR0 · exp( (−V − V_BR) / Vz )    when  V < −V_BR
%
%    Parameters:
%      V_BR  = breakdown voltage (1N4148: ~100 V)
%      IBR0  = knee current      (amount of current at the knee)
%      Vz    = softness factor   (larger = more gradual transition)
%
%  THE TWO PHYSICS MECHANISMS:
%    AVALANCHE  (high V_BR, > ~6 V)
%      · Strong electric field accelerates carriers
%      · Carriers collide and create more carrier pairs  (impact ionization)
%      · A chain reaction "avalanches" — current multiplies rapidly
%      · V_BR INCREASES with temperature  (more phonon scattering)
%
%    ZENER  (low V_BR, < ~5 V)
%      · Very thin depletion region in heavily doped diodes
%      · Quantum tunneling pulls electrons directly through the barrier
%      · V_BR DECREASES with temperature
%
%  WHAT TO OBSERVE
%    · Forward bias: same as Level 2 (curve unchanged there)
%    · At V = −V_BR: current suddenly rises sharply
%    · The "softness" Vz controls how sharp the knee is
%    · 1N4148 breaks down at −100 V — much safer than a 5 V Zener
%
%  COMMON MISCONCEPTIONS
%    ✗ "Breakdown means the diode is destroyed" — not if current is limited!
%    ✗ "Zener diodes break down at high voltage" — no, they use quantum tunneling
%    ✗ "The 1N4148 is a Zener diode" — no, it is an avalanche device at 100 V
% =========================================================================

function Level3_Breakdown()

    p   = diode_params();
    heading(3, 'Reverse Breakdown', '— Avalanche and Zener effect');

    %% ── Console explanation ─────────────────────────────────────────────
    fprintf('\n  CONCEPT: Reverse Breakdown\n');
    fprintf('  ─────────────────────────────────────────────────────────────\n');
    fprintf('  At low reverse voltages: depletion layer widens, almost no current.\n');
    fprintf('  But at V_BR = −%.0f V: the electric field is so strong\n', p.V_BR);
    fprintf('  that carriers gain enough energy to rip apart silicon bonds.\n');
    fprintf('  Each new carrier pair creates more — an "avalanche" of current.\n\n');

    fprintf('  SOFT BREAKDOWN MODEL:\n\n');
    fprintf('       I_brk = −IBR0 · exp( (−V − V_BR) / Vz )\n\n');
    fprintf('    V_BR = %.0f V   — breakdown voltage\n', p.V_BR);
    fprintf('    IBR0 = %.1e A  — knee current\n', p.IBR0);
    fprintf('    Vz   = %.1f V   — softness (larger = more gradual)\n\n', p.Vz);

    fprintf('  AVALANCHE vs ZENER:\n');
    fprintf('    Avalanche (> ~6 V breakdown): impact ionization chain reaction\n');
    fprintf('      → V_BR RISES with temperature (+2 mV/°C)\n');
    fprintf('    Zener    (< ~5 V breakdown): quantum tunneling through thin barrier\n');
    fprintf('      → V_BR FALLS with temperature (−2 mV/°C)\n\n');
    fprintf('  The 1N4148 breaks down at −100 V → avalanche mechanism.\n');

    %% ── Compute I-V ─────────────────────────────────────────────────────
    V = linspace(-115, 1.1, 4000);

    % No breakdown (L2)
    [I_L2, ~] = solveI(V, p.IS0, p.n, p.T0, p.Rs, 1e9, 0,      p.Vz);

    % With breakdown (L3)
    [I_L3, ~] = solveI(V, p.IS0, p.n, p.T0, p.Rs, p.V_BR, p.IBR0, p.Vz);

    % Vary softness for educational comparison
    [I_sharp, ~] = solveI(V, p.IS0, p.n, p.T0, p.Rs, p.V_BR, p.IBR0, 0.5);
    [I_soft,  ~] = solveI(V, p.IS0, p.n, p.T0, p.Rs, p.V_BR, p.IBR0, 5.0);

    %% ── Figure ──────────────────────────────────────────────────────────
    fig = figure('Name','Level 3 — Reverse Breakdown', ...
                 'Position',[60 60 1100 520], ...
                 'Color',[0.97 0.97 0.98]);

    % ── Left panel: Full I-V curve ────────────────────────────────────────
    ax1 = subplot(1,2,1);
    set(ax1,'Color',[1 1 1]);

    plot(V, I_L2*1e3, '--', 'Color',[0.75 0.75 0.75], 'LineWidth', 1.8); hold on
    plot(V, I_L3*1e3, 'b-',  'LineWidth', 2.5);

    % Shade regions
    fill([-115 -p.V_BR -p.V_BR -115], [-150 -150 5 5], ...
         [1 0.9 0.9], 'EdgeColor','none','FaceAlpha',0.4);
    fill([-p.V_BR 0 0 -p.V_BR], [-5 -5 5 5], ...
         [0.92 0.92 1], 'EdgeColor','none','FaceAlpha',0.5);

    % Breakdown voltage marker
    xline(-p.V_BR, 'r--', 'LineWidth', 1.8, ...
          'Label', sprintf('V_{BR} = −%.0f V', p.V_BR), ...
          'LabelVerticalAlignment','bottom','FontSize',10);

    % Annotation: mechanism
    text(-108, -80, {'AVALANCHE', 'breakdown', 'region'}, ...
         'Color',[0.7 0.1 0.1],'FontSize',9,'FontWeight','bold', ...
         'HorizontalAlignment','center');
    text(-50, -2, {'Reverse bias:', 'tiny leakage ~nA'}, ...
         'Color',[0.3 0.3 0.7],'FontSize',9,'HorizontalAlignment','center');

    % Forward knee
    text(0.7, 40, {'Forward', 'bias →'}, 'FontSize',9,'Color',[0.1 0.5 0.1]);

    yline(0,'k-','LineWidth',0.8);
    hold off; grid on; box on;
    xlabel('Applied Voltage  V  (V)',   'FontSize', 11);
    ylabel('Current  I  (mA)',          'FontSize', 11);
    title({'Level 3: Full I-V Curve', '— Revealing reverse breakdown'}, ...
          'FontSize', 12, 'FontWeight','bold');
    legend('L2: No breakdown', 'L3: With avalanche breakdown', ...
           'Location','sw', 'FontSize', 9);
    xlim([-115 1.1]); ylim([-150 80]);
    set(ax1,'FontSize',10);

    % ── Right panel: zoom on breakdown knee, vary Vz ─────────────────────
    ax2 = subplot(1,2,2);
    set(ax2,'Color',[1 1 1]);

    mask = V >= -110 & V <= -85;
    plot(V(mask), I_sharp(mask)*1e3, 'r-',  'LineWidth', 2.0); hold on
    plot(V(mask), I_L3(mask)*1e3,   'b-',  'LineWidth', 2.5);
    plot(V(mask), I_soft(mask)*1e3,  'g--', 'LineWidth', 2.0);

    % Add lines to show softness concept
    text(-97, -120, {'Vz = 0.5 V', '(sharp, Zener-like)'}, ...
         'Color','r','FontSize',9,'FontWeight','bold');
    text(-101, -60, {'Vz = 2.0 V', '(nominal 1N4148)'}, ...
         'Color','b','FontSize',9,'FontWeight','bold');
    text(-103, -15, {'Vz = 5.0 V', '(soft, graded junction)'}, ...
         'Color',[0 0.5 0],'FontSize',9,'FontWeight','bold');

    xline(-p.V_BR,'k:','LineWidth',1.5,'Label',sprintf('V_{BR} = −%.0f V',p.V_BR));
    yline(0,'k-','LineWidth',0.8);

    hold off; grid on; box on;
    xlabel('Applied Voltage  V  (V)',     'FontSize', 11);
    ylabel('Reverse Current  I  (mA)',    'FontSize', 11);
    title({'Level 3: Breakdown Knee Detail', '— Effect of softness factor Vz'}, ...
          'FontSize', 12, 'FontWeight','bold');
    legend('Sharp (Vz=0.5)', 'Nominal (Vz=2.0)', 'Soft (Vz=5.0)', ...
           'Location','sw', 'FontSize', 9);
    xlim([-110 -85]); ylim([-150 5]);
    set(ax2,'FontSize',10);

    sgtitle(sprintf('1N4148  ·  Level 3: Reverse Breakdown  V_{BR} = %.0f V  |  Vz = %.1f V', ...
            p.V_BR, p.Vz), 'FontWeight','bold','FontSize',12);

    %% ── Learning summary ────────────────────────────────────────────────
    print_separator('LEVEL 3 — LEARNING SUMMARY');
    fprintf('\n  ✅  Reverse breakdown is NOT destruction — it is a design feature.\n');
    fprintf('  ✅  Two mechanisms: Avalanche (high V) and Zener (low V, quantum).\n');
    fprintf('  ✅  1N4148 avalanche breakdown at V_BR = −100 V.\n');
    fprintf('  ✅  Softness factor Vz controls sharpness of the breakdown knee.\n');
    fprintf('  ✅  Temperature sign is key: Avalanche V_BR rises; Zener V_BR falls.\n');
    fprintf('\n  NEXT: Level 4 — How does temperature change everything?\n');
    fprintf('         Run:  Level4_Temperature\n\n');
end
