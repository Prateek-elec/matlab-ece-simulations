%% =========================================================================
%  Level4_Temperature.m  —  Temperature Effects: The Hot Diode
%  =========================================================================
%  LEARNING OBJECTIVE
%    Understand that a diode's behaviour changes significantly with
%    temperature — two opposite effects in forward and reverse.
%
%  NEW CONCEPT THIS LEVEL
%    Temperature-scaled saturation current (SPICE model):
%
%         IS(T) = IS0 · (T/T0)^3 · exp[−Eg·q/k_B · (1/T − 1/T0)]
%
%    Physical effects:
%      (a) Forward voltage Vf DECREASES ≈ −2 mV/°C
%          Reason: VT = k_B·T/q increases, the exponential shifts left
%      (b) Reverse leakage IS(T) INCREASES roughly ×2 per 10°C
%          Reason: more thermally generated carriers cross the junction
%
%  WHY THIS MATTERS
%    · Precision circuits: Vf shift can look like an erroneous signal
%    · Power circuits: hot devices draw more current → more heat → runaway!
%    · Datasheets always specify ratings at 25°C — derate at high T
%
%  WHAT TO OBSERVE
%    · Forward I-V curve shifts LEFT at high temperature (lower Vf)
%    · Leakage floor rises by orders of magnitude
%    · The two curves cross: at very low voltage the hot diode has MORE current
%
%  COMMON MISCONCEPTIONS
%    ✗ "Higher temperature means higher forward voltage" — WRONG, it is lower!
%    ✗ "IS doubles per 10°C" — actually faster: ~3–4× per 10°C for Si
%    ✗ "Temperature effect is small" — a 50°C rise doubles the junction current
% =========================================================================

function Level4_Temperature()

    p   = diode_params();
    heading(4, 'Temperature Effects', '— Forward voltage drops, leakage soars');

    %% ── Console explanation ─────────────────────────────────────────────
    fprintf('\n  CONCEPT: How Temperature Changes the Diode\n');
    fprintf('  ─────────────────────────────────────────────────────────────\n');
    fprintf('  Temperature enters the Shockley equation through IS(T) and VT(T):\n\n');
    fprintf('    VT(T)  = k_B·T/q     → grows with T (more thermal energy)\n');
    fprintf('    IS(T)  = IS0 · (T/T0)^3 · exp[−Eg·q/k_B · (1/T − 1/T0)]\n\n');

    T_vals = [250, 300, 348, 398];  % K: −23°C, 27°C, 75°C, 125°C
    T_lbl  = {'−23°C', '27°C (T0)', '75°C', '125°C'};

    fprintf('  IS(T) at key temperatures:\n');
    for k = 1:length(T_vals)
        IS_k = IS_T_fn(p.IS0, T_vals(k), p.T0, p.Eg);
        fprintf('    T = %5.0f K (%s):  IS = %.2e A', T_vals(k), T_lbl{k}, IS_k);
        if k > 1
            ratio = IS_k / p.IS0;
            fprintf('  (×%.0f vs T0)', ratio);
        end
        fprintf('\n');
    end

    fprintf('\n  FORWARD VOLTAGE TEMPERATURE COEFFICIENT:\n');
    fprintf('    dVf/dT ≈ −2 mV/°C for silicon diodes at moderate current.\n');
    fprintf('    At I = 10 mA:  ΔT = 100°C  →  ΔVf ≈ −200 mV (significant!)\n\n');

    fprintf('  ENGINEERING RULE OF THUMB:\n');
    fprintf('    Reverse leakage approximately doubles every 10°C.\n');
    fprintf('    (For silicon the actual factor is closer to 2–3× per 10°C)\n');

    %% ── Compute I-V ─────────────────────────────────────────────────────
    V     = linspace(-0.5, 1.1, 3000);
    colors = {[0.4 0.4 1], [0 0.5 1], [1 0.4 0], [0.7 0 0]};
    I_all  = cell(length(T_vals),1);
    Vd_all = cell(length(T_vals),1);
    for k = 1:length(T_vals)
        IS_k = IS_T_fn(p.IS0, T_vals(k), p.T0, p.Eg);
        [I_all{k}, Vd_all{k}] = solveI(V, IS_k, p.n, T_vals(k), ...
                                         p.Rs, p.V_BR, p.IBR0, p.Vz);
    end

    % Find Vf at 10 mA for each temperature
    Vf_10mA = zeros(1,length(T_vals));
    for k = 1:length(T_vals)
        idx = find(I_all{k} >= 10e-3, 1, 'first');
        if ~isempty(idx), Vf_10mA(k) = V(idx); end
    end

    %% ── Figure ──────────────────────────────────────────────────────────
    fig = figure('Name','Level 4 — Temperature Effects', ...
                 'Position',[60 60 1100 540], ...
                 'Color',[0.97 0.97 0.98]);

    % ── Left panel: Forward I-V at multiple temperatures ──────────────────
    ax1 = subplot(1,2,1);
    set(ax1,'Color',[1 1 1]);

    hold on;
    for k = 1:length(T_vals)
        fwd = V > 0.2 & I_all{k} > 0;
        plot(V(fwd), I_all{k}(fwd)*1e3, '-', 'Color', colors{k}, 'LineWidth', 2.2, ...
             'DisplayName', sprintf('%s', T_lbl{k}));
    end

    % Mark Vf at 10 mA with dots and dashed vertical lines
    yline(10, 'k:', 'LineWidth', 1, 'Label', '10 mA reference');
    for k = 1:length(T_vals)
        if Vf_10mA(k) > 0
            scatter(Vf_10mA(k), 10, 50, colors{k}, 'filled');
            xline(Vf_10mA(k), '--', 'Color', colors{k}, 'LineWidth', 1, 'Alpha', 0.5);
        end
    end

    % Show the horizontal shift
    if Vf_10mA(1) > 0 && Vf_10mA(4) > 0
        annotation('doublearrow', ...
            [Vf_10mA(4) Vf_10mA(1)] / 1.6 + 0.37, [0.27 0.27], ...
            'Head1Style','vback2','Head2Style','vback2','Color','k','LineWidth',1.5);
        text(mean([Vf_10mA(1) Vf_10mA(4)]), 13, ...
             sprintf('ΔVf ≈ %.0f mV\nacross 148°C', (Vf_10mA(4)-Vf_10mA(1))*1e3), ...
             'FontSize',9,'FontWeight','bold','HorizontalAlignment','center');
    end

    hold off; grid on; box on;
    xlabel('Applied Voltage  V_{ext}  (V)', 'FontSize', 11);
    ylabel('Current  I  (mA)',              'FontSize', 11);
    title({'Level 4: Forward Bias vs Temperature', '— V_f shifts LEFT as T rises'}, ...
          'FontSize', 12, 'FontWeight','bold');
    legend('Location','nw','FontSize',9);
    xlim([0.2 1.05]); ylim([-2 250]);
    set(ax1,'FontSize',10);

    % ── Right panel: log scale, leakage vs temperature ────────────────────
    ax2 = subplot(1,2,2);
    set(ax2,'Color',[1 1 1]);

    hold on;
    for k = 1:length(T_vals)
        fwd = V > 0.05 & I_all{k} > 1e-15;
        semilogy(V(fwd), I_all{k}(fwd)*1e3, '-', 'Color', colors{k}, ...
                 'LineWidth', 2.2, 'DisplayName', sprintf('%s', T_lbl{k}));
    end

    % Annotate IS values on left side
    V_lbl = 0.07;
    for k = 1:length(T_vals)
        IS_k = IS_T_fn(p.IS0, T_vals(k), p.T0, p.Eg);
        I_at_label = interp1(V(V>0.05 & I_all{k}>0), I_all{k}(V>0.05 & I_all{k}>0), V_lbl, 'linear','extrap');
        if I_at_label > 0
            text(V_lbl+0.01, abs(I_at_label)*1e3*1.5, ...
                 sprintf('IS=%.1e A', IS_k), ...
                 'FontSize', 8, 'Color', colors{k});
        end
    end

    hold off; grid on; box on;
    xlabel('Applied Voltage  V_{ext}  (V)', 'FontSize', 11);
    ylabel('Current  I  (mA)  — log scale', 'FontSize', 11);
    title({'Level 4: Log Scale', '— Leakage floor rises dramatically with T'}, ...
          'FontSize', 12, 'FontWeight','bold');
    legend('Location','nw','FontSize',9);
    xlim([0.05 1.0]);
    set(ax2,'FontSize',10);

    % Inset: IS(T) vs temperature bar chart
    axes('Position', [0.73 0.14 0.22 0.28]);
    IS_vals = arrayfun(@(T) IS_T_fn(p.IS0, T, p.T0, p.Eg)*1e9, T_vals);
    bar(IS_vals, 'FaceColor',[0.9 0.5 0.2]); grid on;
    set(gca,'XTickLabel', T_lbl,'FontSize',7,'XTickLabelRotation',25);
    ylabel('IS (nA)','FontSize',8);
    title('IS(T)','FontSize',8,'FontWeight','bold');

    sgtitle('1N4148  ·  Level 4: Temperature Effects  (−23°C to 125°C)', ...
            'FontWeight','bold','FontSize',12);

    %% ── Learning summary ────────────────────────────────────────────────
    print_separator('LEVEL 4 — LEARNING SUMMARY');
    fprintf('\n  ✅  Forward voltage Vf DECREASES ~2 mV/°C — hot diodes "open" easier.\n');
    fprintf('  ✅  Reverse leakage IS(T) increases exponentially with temperature.\n');
    fprintf('  ✅  IS scales as T^3 × exp(...) — both factors contribute.\n');
    fprintf('  ✅  At 125°C: IS is ×%.0f larger than at 27°C.\n', IS_T_fn(p.IS0,398,p.T0,p.Eg)/p.IS0);
    fprintf('  ✅  Always check diode specs at operating temperature, not just 25°C.\n');
    fprintf('\n  NEXT: Level 5 — The diode heats itself through its own power dissipation.\n');
    fprintf('         Run:  Level5_SelfHeating\n\n');
end

% Local helper (avoid dependency on diode_utils for IS_T name collision)
function IS = IS_T_fn(IS0, T, T0, Eg)
    k_B = 1.38e-23; q = 1.602e-19;
    IS = IS0 .* (T./T0).^3 .* exp(-Eg.*q./k_B .* (1./T - 1/T0));
end
