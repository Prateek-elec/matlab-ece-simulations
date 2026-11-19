function diode_utils()
%% =========================================================================
%  diode_utils.m  —  Shared physics for DiodeTutor
%  =========================================================================
%  Provides:
%    p          = diode_params()          — canonical 1N4148 parameters
%    IS         = IS_T(IS0,T,T0,Eg)      — SPICE temperature-scaled Is
%    [I,Vd]     = solveI(Vext,...)       — Newton-Raphson I-V solver
%    print_separator(title)              — pretty console divider
%    heading(level, title, subtitle)     — level header printer
% =========================================================================
%
%  Each helper now lives in its own file (diode_params.m, IS_T.m, solveI.m,
%  print_separator.m, heading.m) so every Level script can call it.
    help diode_utils
end
