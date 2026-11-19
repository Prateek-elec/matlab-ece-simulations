function [I_out, Vd_out] = solveI(V_ext, Is, n_val, T, Rs, V_BR, IBR0, Vz)
% Newton-Raphson solver for diode I-V including series resistance and
% optional soft breakdown.
%   Solves: V_ext = Vd + I*Rs    subject to  I = Is*(exp(Vd/nVT)-1) + I_brk
    k_B = 1.38e-23;
    q   = 1.602e-19;
    VT  = k_B * T / q;

    I_out  = zeros(size(V_ext));
    Vd_out = zeros(size(V_ext));

    for idx = 1:numel(V_ext)
        Vext = V_ext(idx);
        Vd   = Vext;           % initial guess

        for iter = 1:150
            % Clamp exp argument to prevent overflow
            arg   = min(Vd / (n_val * VT), 40);
            expVd = exp(arg);

            I_fwd = Is * (expVd - 1);

            % Soft breakdown
            if Vd < -V_BR
                I_brk  = -IBR0 * exp((-Vd - V_BR) / Vz);
                dI_brk = -(IBR0 / Vz) * exp((-Vd - V_BR) / Vz);
            else
                I_brk  = 0;
                dI_brk = 0;
            end

            I_tot = I_fwd + I_brk;
            f     = I_tot - (Vext - Vd) / Rs;
            dfd   = Is * expVd / (n_val * VT) + dI_brk + 1/Rs;

            step = f / dfd;
            Vd   = Vd - step;
            if abs(step) < 1e-13, break; end
        end

        I_out(idx)  = (Vext - Vd) / Rs;
        Vd_out(idx) = Vd;
    end
end

% ─────────────────────────────────────────────────────────────────────────────
