%% =========================================================================
%  Level7_ReverseRecovery.m  —  Reverse Recovery: Switching Isn't Instant
%  =========================================================================
%  LEARNING OBJECTIVE
%    Understand why a diode continues to conduct briefly AFTER you apply
%    reverse voltage — and why this matters for power converters and logic.
%
%  NEW CONCEPT THIS LEVEL
%    When a diode is forward-biased, minority carriers are injected into
%    both sides of the junction.  These carriers do NOT disappear instantly
%    when you reverse the voltage.  They must:
%      (a) Recombine naturally     (time constant τ_R)
%      (b) Be swept out by the reversed electric field
%
%    Stored charge model:
%
%         dQ/dt = I_applied − Q/τ_R
%         Diode conducts while Q > 0
%
%    Reverse recovery time trr: time for Q to reach zero.
%
%  THE TIMELINE OF SWITCHING (draw this mental picture):
%
%    t < 0   : Diode ON, forward current I_F flows, charge Q builds up
%    t = 0   : Voltage reversed, current steps to I_R (reverse)
%    t < trr : Stored charge is draining, diode still "on" (passes I_R)
%    t = trr : Q = 0, depletion region reforms, diode snaps off
%    t > trr : Diode blocks, only tiny IS leakage remains
%
%  WHY IT MATTERS
%    · In a switching power supply at 1 MHz: trr = 4 ns = 0.4% of the period
%      → small but not zero; causes switching loss and EMI spikes
%    · In rectifiers: the reverse current spike heats the diode
%    · Fast-recovery diodes (e.g. UF4004) have trr < 50 ns
%    · Schottky diodes have essentially NO minority storage → trr ≈ 0
%
%  KEY PARAMETERS
%    τ_F = forward transit time  (how long carriers take to cross junction)
%          Sets steady-state stored charge Q_ss = τ_F · I_F
%    τ_R = reverse recovery time constant  (decay rate of Q)
%          Controls how fast the stored charge drains
%
%  COMMON MISCONCEPTIONS
%    ✗ "trr is when the diode turns fully off" — trr is when Q=0, current snaps
%    ✗ "All diodes have the same trr" — Schottky << fast-recovery << standard
%    ✗ "This only matters for slow diodes" — at 10 MHz even 4 ns matters
% =========================================================================

function Level7_ReverseRecovery()

    p   = diode_params();
    heading(7, 'Reverse Recovery', '— Stored charge delays switching');

    %% ── Console explanation ─────────────────────────────────────────────
    fprintf('\n  CONCEPT: Minority Carrier Stored Charge\n');
    fprintf('  ─────────────────────────────────────────────────────────────\n');
    fprintf('  When a diode conducts forward current, minority carriers are\n');
    fprintf('  injected across the junction and "pile up" near the depletion region.\n\n');
    fprintf('  These carriers take time to recombine — even AFTER the voltage reverses.\n');
    fprintf('  During that time, the diode appears to be a short circuit!\n\n');

    fprintf('  STORED CHARGE MODEL:\n\n');
    fprintf('       dQ/dt  =  I_applied  −  Q / τ_R\n\n');
    fprintf('    τ_F = %.0f ns  (forward transit time: sets Q_steady = τ_F·I_F)\n', p.tau_F*1e9);
    fprintf('    τ_R = %.0f ns  (reverse recovery time constant: decay rate of Q)\n\n', p.tau_R*1e9);

    % Show case studies
    I_F_cases = [1e-3, 10e-3, 100e-3];
    fprintf('  STEADY-STATE STORED CHARGE before switching:\n');
    for I_F = I_F_cases
        Q_ss = p.tau_F * I_F;
        fprintf('    I_F = %5.0f mA  →  Q_ss = τ_F · I_F = %.0f pC\n', I_F*1e3, Q_ss*1e12);
    end

    %% ── Simulate reverse recovery for multiple forward currents ─────────
    dt    = 0.05e-9;
    t_end = 80e-9;
    t     = 0 : dt : t_end;
    N     = numel(t);

    I_R   = -1e-3;    % Applied reverse current step

    results = struct();
    colors  = {[0 0.5 0.9], [0.9 0.4 0], [0.6 0 0.6]};
    for k = 1:length(I_F_cases)
        I_F = I_F_cases(k);
        Q   = zeros(1,N);
        Id  = zeros(1,N);
        Q(1) = p.tau_F * I_F;   % initial stored charge

        for i = 1:N-1
            dQdt  = I_R - Q(i)/p.tau_R;
            Q(i+1) = Q(i) + dt * dQdt;
            Id(i)  = (Q(i) > 0) * I_R;   % still conducts while Q > 0
        end
        Id(end) = 0;

        trr_idx = find(Q <= 0, 1, 'first');
        trr     = t(max(trr_idx,1));

        results(k).Q   = Q;
        results(k).Id  = Id;
        results(k).trr = trr;
        results(k).I_F = I_F;
        fprintf('  I_F = %5.0f mA:  trr = %.1f ns  (datasheet ≈ 4 ns at 10mA)\n', ...
                I_F*1e3, trr*1e9);
    end

    %% ── Figure ──────────────────────────────────────────────────────────
    fig = figure('Name','Level 7 — Reverse Recovery', ...
                 'Position',[60 60 1150 600], ...
                 'Color',[0.97 0.97 0.98]);

    % ── Top-left: Current vs time (main story) ───────────────────────────
    ax1 = subplot(2,2,[1 2]);
    set(ax1,'Color',[1 1 1]);

    hold on
    for k = 1:length(I_F_cases)
        plot(t*1e9, results(k).Id*1e3, '-', 'Color', colors{k}, 'LineWidth', 2.2, ...
             'DisplayName', sprintf('I_F = %.0f mA', results(k).I_F*1e3));
    end

    % Annotations for the nominal case (k=2, 10 mA)
    trr_nom = results(2).trr;
    xline(0, 'k--', 'LineWidth', 1.5, 'Label', 't = 0 (voltage reversed)');
    xline(trr_nom*1e9, 'r--', 'LineWidth', 1.8, ...
          'Label', sprintf('t_{rr} = %.1f ns', trr_nom*1e9));

    % Phase annotations
    text(trr_nom*1e9*0.4, I_R*0.85e3, ...
         {'← Diode still ON', '  (stored charge draining)'}, ...
         'FontSize',9,'Color',[0.5 0 0],'FontWeight','bold');
    text(trr_nom*1e9*1.3, I_R*0.3e3, ...
         {'Diode OFF →', '(Q = 0, junction reforms)'}, ...
         'FontSize',9,'Color',[0 0.4 0],'FontWeight','bold');

    % Show I_R level
    yline(I_R*1e3, 'k:', 'LineWidth', 1, 'Label', 'I_R = −1 mA (applied reverse)');
    yline(0, 'k-', 'LineWidth', 0.8);

    hold off; grid on; box on;
    xlabel('Time  t  (ns)', 'FontSize', 11);
    ylabel('Diode current  I_d  (mA)', 'FontSize', 11);
    title({'Level 7: Reverse Recovery Current', ...
           'Diode continues conducting reverse current until stored charge Q = 0'}, ...
          'FontSize', 11, 'FontWeight','bold');
    legend('Location','ne','FontSize',9);
    xlim([0 t_end*1e9]); ylim([-1.5 0.5]);
    set(ax1,'FontSize',10);

    % ── Bottom-left: Stored charge Q vs time ─────────────────────────────
    ax2 = subplot(2,2,3);
    set(ax2,'Color',[1 1 1]);

    hold on
    for k = 1:length(I_F_cases)
        plot(t*1e9, results(k).Q*1e12, '-', 'Color', colors{k}, 'LineWidth', 2.0, ...
             'DisplayName', sprintf('I_F = %.0f mA', results(k).I_F*1e3));
        % Mark trr
        xline(results(k).trr*1e9, '--', 'Color', colors{k}, 'LineWidth', 1, 'Alpha', 0.7);
    end
    yline(0, 'k-', 'LineWidth', 1.5, 'Label', 'Q = 0 → diode blocks');

    hold off; grid on; box on;
    xlabel('Time  t  (ns)', 'FontSize', 10);
    ylabel('Stored charge  Q  (pC)', 'FontSize', 10);
    title({'Stored Charge Decay', 'trr = time for Q to reach zero'}, ...
          'FontSize', 10, 'FontWeight','bold');
    legend('Location','ne','FontSize',8);
    xlim([0 t_end*1e9]); ylim([-2 15]);

    % ── Bottom-right: trr vs I_F and diode comparison ─────────────────────
    ax3 = subplot(2,2,4);
    set(ax3,'Color',[1 1 1]);

    I_F_sweep = logspace(-4, -1, 80);   % 0.1 mA to 100 mA
    trr_sweep = zeros(size(I_F_sweep));

    for j = 1:length(I_F_sweep)
        Q_j  = zeros(1,N);
        Q_j(1) = p.tau_F * I_F_sweep(j);
        for i = 1:N-1
            Q_j(i+1) = Q_j(i) + dt*(I_R - Q_j(i)/p.tau_R);
        end
        idx = find(Q_j <= 0, 1, 'first');
        trr_sweep(j) = t(max(idx,1));
    end

    semilogx(I_F_sweep*1e3, trr_sweep*1e9, 'b-', 'LineWidth', 2.5); hold on

    % Mark our three example points
    for k = 1:length(I_F_cases)
        scatter(results(k).I_F*1e3, results(k).trr*1e9, 60, colors{k}, 'filled');
        text(results(k).I_F*1e3*1.2, results(k).trr*1e9+0.3, ...
             sprintf('%.1f ns', results(k).trr*1e9), 'FontSize',8,'Color',colors{k});
    end

    % Datasheet reference point
    scatter(10, 4, 80, 'k', 'd', 'LineWidth', 2);
    text(11, 4.3, 'Datasheet:\n4 ns at 10 mA', 'FontSize', 8, 'Color','k');

    hold off; grid on; box on;
    xlabel('Forward current I_F  (mA)  — log scale', 'FontSize', 10);
    ylabel('Reverse recovery time  t_{rr}  (ns)', 'FontSize', 10);
    title({'t_{rr} vs Forward Pre-bias Current', 'More charge → longer recovery'}, ...
          'FontSize', 10, 'FontWeight','bold');
    xlim([0.1 150]);

    sgtitle(sprintf('1N4148  ·  Level 7: Reverse Recovery  |  τ_F = %.0f ns  |  τ_R = %.0f ns', ...
            p.tau_F*1e9, p.tau_R*1e9), 'FontWeight','bold','FontSize',11);

    %% ── Learning summary ────────────────────────────────────────────────
    print_separator('LEVEL 7 — LEARNING SUMMARY');
    fprintf('\n  ✅  Forward bias injects minority carriers; they take time to recombine.\n');
    fprintf('  ✅  Stored charge Q decays as dQ/dt = I_applied − Q/τ_R.\n');
    fprintf('  ✅  Diode continues conducting reverse current until Q = 0 (time = trr).\n');
    fprintf('  ✅  Higher I_F = more stored charge = longer trr.\n');
    fprintf('  ✅  1N4148 datasheet trr ≈ 4 ns at 10 mA — good for MHz switching.\n');
    fprintf('  ✅  Schottky diodes avoid minority storage entirely (majority carrier device).\n');
    fprintf('\n');
    print_separator('TUTORIAL COMPLETE');
    fprintf('\n  🎓  You have completed all 7 levels of the DiodeTutor!\n\n');
    fprintf('  What you now understand about the 1N4148:\n');
    fprintf('    L1: Exponential I-V → the Shockley equation\n');
    fprintf('    L2: Rs linearises high-current region\n');
    fprintf('    L3: Avalanche breakdown at −100 V\n');
    fprintf('    L4: IS rises, Vf falls with temperature\n');
    fprintf('    L5: Self-heating creates a thermal feedback loop\n');
    fprintf('    L6: Depletion capacitance limits RF performance\n');
    fprintf('    L7: Stored charge causes reverse recovery delay\n\n');
    fprintf('  FURTHER READING: See DiodeTutor_README.md\n\n');
end
