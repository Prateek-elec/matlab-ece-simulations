function p = diode_params()
% Returns a struct with all 1N4148 model parameters and physical constants.
    % Physical constants
    p.k_B   = 1.38e-23;     % Boltzmann constant  (J/K)
    p.q     = 1.602e-19;    % Electron charge      (C)

    % Core Shockley parameters
    p.IS0   = 2.52e-9;      % Saturation current at T0  (A)
    p.n     = 1.752;        % Ideality factor  (dimensionless)
    p.T0    = 300;          % Reference temperature      (K)
    p.Eg    = 1.11;         % Silicon bandgap            (eV)

    % Series resistance
    p.Rs        = 0.5;      % Series resistance at T0    (Ω)
    p.alpha_Rs  = 0.004;    % Temperature coefficient    (1/K)

    % Reverse breakdown
    p.V_BR  = 100;          % Breakdown voltage          (V)
    p.IBR0  = 1e-4;         % Breakdown knee current     (A)
    p.Vz    = 2.0;          % Softness factor            (V)

    % Thermal
    p.Rth   = 300;          % Junction-to-ambient        (°C/W)
    p.Ta    = 300;          % Ambient temperature        (K)
    p.I_rated = 300e-3;     % Rated continuous current   (A)

    % Junction capacitance
    p.Cj0   = 4e-12;        % Zero-bias cap              (F)
    p.Vj    = 0.7;          % Built-in potential         (V)
    p.M_cap = 0.33;         % Grading coefficient

    % Reverse recovery
    p.tau_F = 1e-9;         % Forward transit time       (s)
    p.tau_R = 6e-9;         % Reverse recovery time const(s)
end

% ─────────────────────────────────────────────────────────────────────────────
