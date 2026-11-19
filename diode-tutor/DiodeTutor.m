%% =========================================================================
%  DiodeTutor.m  —  1N4148 Semiconductor Diode: A Visual Learning Journey
%  =========================================================================
%  A step-by-step educational simulator for electronics engineering students.
%  Each level introduces exactly ONE new physical phenomenon.
%
%  AUDIENCE  : First-year / second-year EE students, no prior device modelling
%  APPROACH  : Build physical intuition before mathematics
%  REFERENCE : 1N4148 small-signal silicon switching diode
%
%  USAGE:
%    DiodeTutor        — show this menu
%    DiodeTutor(N)     — run Level N  (N = 1..7)
%    DiodeTutor('all') — run all levels in sequence
%
%  LEVELS:
%    1 · The Shockley Equation      — what makes a diode a diode?
%    2 · Series Resistance          — why real devices aren't ideal
%    3 · Reverse Breakdown          — avalanche and Zener effect
%    4 · Temperature Effects        — hot diodes behave differently
%    5 · Self-Heating               — the diode heats itself
%    6 · Junction Capacitance       — diodes can store charge
%    7 · Reverse Recovery           — switching isn't instantaneous
%
%  =========================================================================
%  Architecture note
%  -----------------
%  All shared physics live in diode_utils.m (IS(T) scaling, Newton-Raphson
%  solver, shared parameters).  Each LevelN_*.m file is self-contained and
%  can be run independently — it calls diode_utils to avoid copy-pasting
%  physics.
%  =========================================================================

function DiodeTutor(arg)

    if nargin == 0
        print_banner();
        print_menu();
        return
    end

    if ischar(arg) && strcmpi(arg,'all')
        levels = 1:7;
    elseif isnumeric(arg) && isscalar(arg) && arg>=1 && arg<=7
        levels = arg;
    else
        error('DiodeTutor: argument must be 1–7 or ''all''.');
    end

    for lv = levels
        fprintf('\n');
        switch lv
            case 1,  Level1_Shockley();
            case 2,  Level2_SeriesResistance();
            case 3,  Level3_Breakdown();
            case 4,  Level4_Temperature();
            case 5,  Level5_SelfHeating();
            case 6,  Level6_Capacitance();
            case 7,  Level7_ReverseRecovery();
        end
        if lv < max(levels)
            input(sprintf('\n   ── Press Enter to continue to Level %d ──\n', lv+1));
        end
    end
    fprintf('\n🎓  Tutorial complete!  See DiodeTutor_README.md for further reading.\n\n');
end

% ─────────────────────────────────────────────────────────────────────────────
function print_banner()
    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════════════╗\n');
    fprintf('║          1N4148 DIODE  —  VISUAL LEARNING TUTORIAL          ║\n');
    fprintf('║               DiodeTutor.m  ·  v1.0  ·  2025               ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════╝\n');
    fprintf('\n');
    fprintf('  "A diode is the simplest nonlinear device.\n');
    fprintf('   Understanding it deeply unlocks all of semiconductor physics."\n');
    fprintf('\n');
end

function print_menu()
    fprintf('  ┌─────────────────────────────────────────────────────────┐\n');
    fprintf('  │  LEVEL   TOPIC                          NEW CONCEPT      │\n');
    fprintf('  ├─────────────────────────────────────────────────────────┤\n');
    fprintf('  │   1      The Shockley Equation          Ideal I-V curve  │\n');
    fprintf('  │   2      Series Resistance              Real device limit │\n');
    fprintf('  │   3      Reverse Breakdown              Avalanche / Zener │\n');
    fprintf('  │   4      Temperature Effects            Leakage & Vf drop │\n');
    fprintf('  │   5      Self-Heating                   Power → Heat      │\n');
    fprintf('  │   6      Junction Capacitance           RF & switching    │\n');
    fprintf('  │   7      Reverse Recovery               Stored charge     │\n');
    fprintf('  └─────────────────────────────────────────────────────────┘\n');
    fprintf('\n');
    fprintf('  Usage:\n');
    fprintf('    DiodeTutor(1)      %% run Level 1\n');
    fprintf('    DiodeTutor(''all'') %% run all levels\n');
    fprintf('\n');
end
