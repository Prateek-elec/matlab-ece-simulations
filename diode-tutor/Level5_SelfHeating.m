%% =========================================================================
%  Level5_SelfHeating.m  —  Self-Heating: The Diode Warms Itself
%  =========================================================================
%  LEARNING OBJECTIVE
%    Understand the thermal feedback loop inside a real operating diode:
%    current generates power, power creates heat, heat changes the device.
%
%  NEW CONCEPT THIS LEVEL
%    Self-heating couples the electrical and thermal domains:
%
%         P   = Vd · I          (power dissipated IN THE JUNCTION)
%         Tj  = Ta + P · Rth   (junction temperature rise above ambient)
%
%    At each voltage point, we must solve these simultaneously because:
%      · Tj depends on P
%      · P depends on I
%      · I depends on Tj  (through IS(Tj) and nVT(Tj))
%
%    Also adds B2: Rs(T) = Rs · [1 + α·(Tj − T0)]
%      Series resistance increases with temperature (reduced carrier mobility).
%
%  THE THERMAL CHAIN (important mental model)
%
%      Voltage  →  Current  →  Power  →  Heat  →  Temperature
%         V           I       P=Vd·I   ΔT=P·Rth     Tj=Ta+ΔT
%                     ↑                                  |
%                     └──────────── feedback ────────────┘
%                          (higher T → more I → more P → ...)
%
%  WHAT TO OBSERVE
%    · Junction temperature Tj rises steeply above ~0.8 V
%    · Rs(T) curve: resistance increases with junction temperature
%    · Self-heated curve bends more than the fixed-T curves
%    · At Tj = 150°C the device reaches its thermal limit
%
%  COMMON MISCONCEPTIONS
%    ✗ "Use P = V·I for power" — must use P = Vd·I (junction voltage, not applied)
%    ✗ "Self-heating is only for power diodes" — even 1N4148 at 300 mA heats up
%    ✗ "Rth doesn't matter for small signals" — it does at DC or low-frequency
% =========================================================================

function Level5_SelfHeating()

    p   = diode_params();
    heading(5, 'Self-Heating', '— The diode heats itself');

    %% ── Console explanation ─────────────────────────────────────────────
    fprintf('\n  CONCEPT: Thermal Feedback Loop\n');
    fprintf('  ─────────────────────────────────────────────────────────────\n');
    fprintf('  Every diode dissipates power  P = Vd · I  at its junction.\n');
    fprintf('  That heat must flow to the ambient through thermal resistance:\n\n');
    fprintf('       Tj  =  Ta  +  P · Rth\n\n');
    fprintf('    Ta   = %.0f K (ambient = %.0f°C)\n', p.Ta, p.Ta-273);
    fprintf('    Rth  = %d °C/W  (junction-to-ambient, 1N4148 in free air)\n\n', p.Rth);
    fprintf('  KEY NUMBERS:\n');
    for I_ex = [10e-3, 100e-3, 300e-3]
        Vd_ex = 0.72;   % approximate
        P_ex  = Vd_ex * I_ex;
        Tj_ex = p.Ta + P_ex * p.Rth;
        fprintf('    I = %5.0f mA, Vd ≈ %.2f V:  P = %.0f mW,  Tj = %.0f°C\n', ...
                I_ex*1e3, Vd_ex, P_ex*1e3, Tj_ex-273);
    end
    fprintf('\n  ⚠  Maximum junction temperature for 1N4148:  Tj,max = 150°C\n');
    fprintf('     Exceeded power = (150 − 25) / 300 = %.0f mW\n', (150-25)/p.Rth*1e3);

    fprintf('\n  [B2] TEMPERATURE-DEPENDENT Rs:\n');
    fprintf('       Rs(T) = Rs · [1 + α · (Tj − T0)]\n');
    fprintf('       Rs at T0 = %.1f Ω,  α = %.4f /K\n', p.Rs, p.alpha_Rs);
    fprintf('       Rs at 150°C: Rs × (1 + %.4f × 125) = %.2f Ω\n', ...
            p.alpha_Rs, p.Rs*(1 + p.alpha_Rs*125));

    %% ── Compute I-V  ─────────────────────────────────────────────────────
    V = linspace(-0.1, 1.2, 2000);

    % L3 reference: no self-heating, fixed T0
    [I_L3, ~] = solveI(V, p.IS0, p.n, p.T0, p.Rs, p.V_BR, p.IBR0, p.Vz);

    % L5: self-heating loop
    I_L5   = zeros(size(V));
    Vd_L5  = zeros(size(V));
    Tj_L5  = zeros(size(V));
    Rs_L5  = zeros(size(V));
    P_L5   = zeros(size(V));

    for idx = 1:numel(V)
        Tj_est = p.T0;
        for therm_iter = 1:60
            IS_tj = IS_T_fn(p.IS0, Tj_est, p.T0, p.Eg);
            Rs_T  = p.Rs * (1 + p.alpha_Rs * (Tj_est - p.T0));
            [I_tmp, Vd_tmp] = solveI(V(idx), IS_tj, p.n, Tj_est, Rs_T, ...
                                     p.V_BR, p.IBR0, p.Vz);
            P_tmp   = abs(Vd_tmp * I_tmp);
            Tj_new  = p.Ta + P_tmp * p.Rth;
            if abs(Tj_new - Tj_est) < 0.005, break; end
            Tj_est  = 0.4*Tj_est + 0.6*Tj_new;
        end
        I_L5(idx)  = I_tmp;
        Vd_L5(idx) = Vd_tmp;
        Tj_L5(idx) = Tj_est;
        Rs_L5(idx) = p.Rs * (1 + p.alpha_Rs * (Tj_est - p.T0));
        P_L5(idx)  = abs(Vd_tmp * I_tmp);
    end

    %% ── Figure ──────────────────────────────────────────────────────────
    fig = figure('Name','Level 5 — Self-Heating', ...
                 'Position',[60 60 1150 620], ...
                 'Color',[0.97 0.97 0.98]);

    mf = V >= 0 & V <= 1.2;
    Vf = V(mf);

    % ── Top-left: I vs V with self-heating comparison ─────────────────────
    ax1 = subplot(2,2,1);
    set(ax1,'Color',[1 1 1]);
    plot(Vf, I_L3(mf)*1e3, 'b--', 'LineWidth', 1.8); hold on
    plot(Vf, I_L5(mf)*1e3, 'm-',  'LineWidth', 2.5);
    yline(p.I_rated*1e3,'k:','Label','I_{rated} = 300 mA','FontSize',9);
    hold off; grid on; box on;
    xlabel('V_{ext} (V)','FontSize',10);
    ylabel('I (mA)','FontSize',10);
    title({'Current vs Voltage', '(L3 fixed T  vs  L5 self-heated)'}, 'FontSize',10,'FontWeight','bold');
    legend('L3: Fixed T_0 = 27°C','L5: Self-heated','Location','nw','FontSize',9);
    xlim([0 1.2]); ylim([-5 450]);

    % ── Top-right: Junction temperature ───────────────────────────────────
    ax2 = subplot(2,2,2);
    set(ax2,'Color',[1 1 1]);
    yyaxis left
    plot(Vf, I_L5(mf)*1e3, 'm-', 'LineWidth', 2.2);
    ylabel('Current I (mA)','FontSize',10,'Color','m');
    ylim([-5 500]);

    yyaxis right
    plot(Vf, Tj_L5(mf)-273, 'r-', 'LineWidth', 2.2); hold on
    yline(150, 'r:', 'LineWidth', 1.5, 'Label', 'T_{j,max} = 150°C');
    yline(p.Ta-273, 'b:', 'LineWidth', 1, 'Label', sprintf('T_a = %.0f°C', p.Ta-273));
    hold off; grid on; box on;
    ylabel('Junction Temperature T_j (°C)','FontSize',10,'Color','r');
    xlabel('V_{ext} (V)','FontSize',10);
    title({'Junction Temperature', '(rises steeply with current)'}, 'FontSize',10,'FontWeight','bold');
    ylim([p.Ta-273-10 200]);

    % ── Bottom-left: Power dissipation ────────────────────────────────────
    ax3 = subplot(2,2,3);
    set(ax3,'Color',[1 1 1]);
    area(Vf, P_L5(mf)*1e3, 'FaceColor',[1 0.85 0.7], 'EdgeColor',[0.8 0.4 0],'LineWidth',1.5);
    hold on
    % Max power line
    P_max = (150-25) / p.Rth;
    yline(P_max*1e3, 'r--', 'LineWidth', 1.5, ...
          'Label', sprintf('P_{max} = %.0f mW  (T_{j,max}=150°C)', P_max*1e3));
    hold off; grid on; box on;
    xlabel('V_{ext} (V)','FontSize',10);
    ylabel('Junction Power  P = V_d · I  (mW)','FontSize',10);
    title({'Power Dissipation', '→ The heat source inside the junction'}, 'FontSize',10,'FontWeight','bold');
    xlim([0 1.2]); ylim([0 600]);

    % ── Bottom-right: Rs(T) effective resistance ───────────────────────────
    ax4 = subplot(2,2,4);
    set(ax4,'Color',[1 1 1]);
    plot(Vf, Rs_L5(mf)*1000, 'k-', 'LineWidth', 2.2);
    hold on
    yline(p.Rs*1000, 'b:', 'LineWidth', 1.5, ...
          'Label', sprintf('Rs(T_0) = %.0f mΩ', p.Rs*1000));
    hold off; grid on; box on;
    xlabel('V_{ext} (V)','FontSize',10);
    ylabel('R_s(T_j)  (mΩ)','FontSize',10);
    title({'Effective Series Resistance', '[B2] R_s increases as junction heats'}, ...
          'FontSize',10,'FontWeight','bold');
    xlim([0 1.2]);

    sgtitle('1N4148  ·  Level 5: Self-Heating  |  Voltage → Current → Power → Heat → Temperature', ...
            'FontWeight','bold','FontSize',11);

    %% ── Learning summary ────────────────────────────────────────────────
    print_separator('LEVEL 5 — LEARNING SUMMARY');
    fprintf('\n  ✅  Power dissipated is P = Vd·I (junction voltage × current).\n');
    fprintf('  ✅  Thermal resistance Rth converts power to temperature rise.\n');
    fprintf('  ✅  Feedback loop: T↑ → IS↑ → I↑ → P↑ → T↑ (thermal runaway risk).\n');
    fprintf('  ✅  Rs(T) also increases — mobility decreases in hotter silicon.\n');
    fprintf('  ✅  Max power for 1N4148 in free air: %.0f mW (Tj,max = 150°C).\n', (150-25)/p.Rth*1e3);
    fprintf('\n  NEXT: Level 6 — Diodes are also capacitors at high frequencies.\n');
    fprintf('         Run:  Level6_Capacitance\n\n');
end

function IS = IS_T_fn(IS0, T, T0, Eg)
    k_B = 1.38e-23; q = 1.602e-19;
    IS = IS0 .* (T./T0).^3 .* exp(-Eg.*q./k_B .* (1./T - 1/T0));
end
