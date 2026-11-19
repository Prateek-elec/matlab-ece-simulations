function IS = IS_T(IS0, T, T0, Eg)
% SPICE temperature scaling of saturation current.
%   IS(T) = IS0 * (T/T0)^3 * exp(-Eg*q/k_B * (1/T - 1/T0))
    k_B = 1.38e-23;
    q   = 1.602e-19;
    IS  = IS0 .* (T./T0).^3 .* exp(-Eg.*q./k_B .* (1./T - 1/T0));
end

% ─────────────────────────────────────────────────────────────────────────────
