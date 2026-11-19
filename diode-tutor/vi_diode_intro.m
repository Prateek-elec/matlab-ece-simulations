%% Diode I-V Characteristic — Shockley Equation
% ================================================
% Parameters (modify these freely)
Is  = 1e-12;   % Reverse saturation current (A)
n   = 1.0;     % Ideality factor (1=ideal, ~2=real silicon)
T   = 300;     % Temperature in Kelvin (room temp = 300 K)

% Physical constants
k  = 1.38e-23; % Boltzmann constant (J/K)
q  = 1.602e-19;% Electron charge (C)
VT = k * T / q;% Thermal voltage (~0.02585 V at 300K)

fprintf('Thermal voltage VT = %.4f V\n', VT);

%% Voltage sweep
V_fwd = linspace(-0.5, 0.85, 1000); % forward + small reverse

%% Shockley equation
I = Is * (exp(V_fwd ./ (n * VT)) - 1);

%% Threshold voltage estimate (I = 1 mA crossover)
V_th = n * VT * log(1e-3 / Is + 1);
fprintf('Threshold voltage V_th ≈ %.3f V\n', V_th);

%% --- PLOT 1: Linear scale ---
figure('Name', 'Diode I-V Characteristic', 'NumberTitle', 'off');

subplot(1, 2, 1);
plot(V_fwd, I * 1000, 'b-', 'LineWidth', 2);
hold on;
xline(V_th, '--', 'Color', [0.9 0.6 0.1], 'LineWidth', 1.2, ...
    'Label', sprintf('V_{th} = %.2f V', V_th), ...
    'LabelHorizontalAlignment', 'left');
yline(0, 'k-', 'LineWidth', 0.5);
xline(0, 'k-', 'LineWidth', 0.5);
hold off;

xlabel('Voltage V (V)');
ylabel('Current I (mA)');
title('I-V Curve — Linear Scale');
xlim([-0.5 0.85]);
ylim([-0.5 max(I)*1000*1.1]);
grid on;
legend(sprintf('n=%.1f, I_s=%.0e A', n, Is), 'Location', 'northwest');

%% --- PLOT 2: Log scale (reveals I_s clearly) ---
subplot(1, 2, 2);
semilogy(V_fwd(I > 0), I(I > 0) * 1000, 'b-', 'LineWidth', 2);
hold on;
xline(V_th, '--', 'Color', [0.9 0.6 0.1], 'LineWidth', 1.2, ...
    'Label', sprintf('V_{th} = %.2f V', V_th), ...
    'LabelHorizontalAlignment', 'left');
hold off;

xlabel('Voltage V (V)');
ylabel('Current I (mA) — log scale');
title('I-V Curve — Log Scale');
xlim([0 0.85]);
grid on;

sgtitle(sprintf('Shockley Diode: I_s = %.0e A,  n = %.1f,  T = %d K', Is, n, T));