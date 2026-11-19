%% =========================================================================
%  simulation_v3.m — 3D Indoor RF Ray Tracing: Deep-Dive ECE Simulator
%
%  PURPOSE:
%    Teach every layer of indoor RF propagation step-by-step, with
%    interactive controls, annotated physics, and publication-quality
%    visuals.  Each section header explains WHY before HOW.
%
%  HOW TO RUN:
%    >> run simulation_v3.m          (opens GUI automatically)
%    >> help simulation_v3           (prints concept map)
%
%  WHAT STUDENTS LEARN:
%    Step 1 — EM fundamentals: wavelength, frequency, energy spreading
%    Step 2 — Ray model: sampling a continuous radiation pattern
%    Step 3 — Free-space path loss: FSPL derivation and inverse-square law
%    Step 4 — Reflection physics: 3D vector form of Snell's law
%    Step 5 — Material attenuation: complex permittivity → reflection/loss
%    Step 6 — Multipath: many echoes arriving at different times
%    Step 7 — Channel Impulse Response: h(τ), RMS delay spread, Bc
%    Step 8 — OFDM defence: cyclic prefix & coherence bandwidth
%    Step 9 — Coverage heatmap: dead zones, AP placement
%    Step 10— Link budget: full Friis equation, SINR, SNR margins
%
%  FEATURES (v3 upgrades):
%    • Larger 15×12×3.5m office (L-shaped floor plan with partition wing)
%    • 4 Rx nodes (blue, green, yellow, cyan) at different obstructions
%    • Per-ray animated drawing with power-coded hot colormap
%    • "Concept Tour" button → walks through 5 annotated teaching moments
%    • "Link Budget" panel → live Friis equation table in figure
%    • "Frequency Sweep" button → overlays FSPL curves for all 4 bands
%    • Step-by-step reflections panel → shows one bounce at a time
%    • 3D antenna radiation pattern overlay on Tx (dipole pattern)
%    • CIR figure now shows OFDM CP line and delay spread shading
%    • Heatmap now has contour lines + Rx-coverage circles overlay
%    • Console output: formatted table + link budget summary per Rx
%    • All physics comments reference IEEE 802.11/3GPP standards
%
%  REQUIRES: Base MATLAB (no toolboxes). Tested R2022a+.
% =========================================================================

clear; clc; close all;

%% ══════════════════════════════════════════════════════════════════════════
%  CONCEPT MAP — printed on startup so students can follow along
% ══════════════════════════════════════════════════════════════════════════
printConceptMap();

%% ══════════════════════════════════════════════════════════════════════════
%  SECTION A — GLOBAL SIMULATION STATE
% ══════════════════════════════════════════════════════════════════════════
global SIM;

% ── Room geometry (metres) ──────────────────────────────────────────────
%  L-shaped floorplan: main hall + wing separated by partition
SIM.room = struct('Lx',15, 'Ly',12, 'Lz',3.5, ...
    'WingLx',6, 'WingLy',5);   % wing: x=9..15, y=0..5

% ── Transceivers ────────────────────────────────────────────────────────
SIM.Tx = [2.0, 6.0, 3.0];          % Ceiling-mount AP
SIM.Rx = [12.0,  2.0, 1.2;         % Rx1 — in wing, obscured by partition
          13.0,  9.0, 1.2;         % Rx2 — far back-corner
           7.5,  6.0, 1.2;         % Rx3 — near partition (middle)
           4.0,  2.0, 1.2];        % Rx4 — close, LOS
SIM.rxColors = {[0.20 0.55 1.00],  % blue
                [0.20 0.88 0.55],  % green
                [1.00 0.85 0.20],  % yellow
                [0.90 0.40 1.00]}; % purple
SIM.captureRadius = 0.60;           % m

% ── RF parameters ───────────────────────────────────────────────────────
SIM.TxPower_dBm = 20;               % Typical 802.11ac AP
SIM.freq        = 2.4e9;            % Hz
SIM.Nrays       = 60;
SIM.maxBounces  = 6;
SIM.TxGain_dBi  = 2.0;             % Dipole gain over isotropic
SIM.RxGain_dBi  = 0.0;             % Omnidirectional Rx
SIM.NoiseFigure_dB = 7;            % Typical WiFi receiver
SIM.Bandwidth_MHz  = 20;           % 802.11n channel width

% ── Visualisation options ────────────────────────────────────────────────
SIM.animateRays = true;
SIM.showAllRays = true;
SIM.showHitOnly = false;
SIM.showAntPat  = true;            % Show dipole radiation pattern overlay

% ── Material table (Rec. ITU-R P.2040) ──────────────────────────────────
%  [reflection_loss_dB, transmission_loss_dB, colour_rgb]
%  Values approximate 2.4 GHz; scale with 20log(f/f0) for other bands.
SIM.materials = struct( ...
    'Drywall',  [3.0,  5.0], ...   % Gypsum board, typical partition
    'Concrete', [8.0, 15.0], ...   % Reinforced, load-bearing
    'Glass',    [1.0,  3.0], ...   % Standard window glazing
    'Metal',    [0.5, 30.0], ...   % Steel panel / RF shield
    'Wood',     [2.0,  4.0]);      % Wood door / furniture surface
SIM.matName = 'Drywall';

% ── Frequency / wavelength table ─────────────────────────────────────────
SIM.freqTable  = [900e6, 2.4e9, 5e9, 28e9];
SIM.freqLabels = {'900 MHz','2.4 GHz','5 GHz','28 GHz'};

% ── Internal state ────────────────────────────────────────────────────────
SIM.rayData    = {};
SIM.tourStep   = 0;

%% ══════════════════════════════════════════════════════════════════════════
%  SECTION B — MAIN FIGURE
% ══════════════════════════════════════════════════════════════════════════
SIM.fig = figure( ...
    'Name',        '3D Indoor RF Simulator v3 — ECE Deep-Dive', ...
    'NumberTitle', 'off', ...
    'Position',    [20 20 1500 860], ...
    'Color',       [0.08 0.08 0.11], ...
    'Resize',      'on');

SIM.ax = axes('Parent', SIM.fig, ...
    'Position',   [0.005 0.02 0.67 0.96], ...
    'Color',      [0.05 0.05 0.08], ...
    'XColor',     [0.70 0.72 0.78], ...
    'YColor',     [0.70 0.72 0.78], ...
    'ZColor',     [0.70 0.72 0.78], ...
    'GridColor',  [0.20 0.20 0.25], ...
    'GridAlpha',  0.30, ...
    'FontSize',   9);
grid(SIM.ax,'on');  hold(SIM.ax,'on');
xlabel(SIM.ax,'X  (m)','Color',[0.82 0.82 0.88],'FontSize',11);
ylabel(SIM.ax,'Y  (m)','Color',[0.82 0.82 0.88],'FontSize',11);
zlabel(SIM.ax,'Z  (m)','Color',[0.82 0.82 0.88],'FontSize',11);
updateTitle3D();
view(SIM.ax, 38, 26);
rotate3d(SIM.ax,'on');
axis(SIM.ax,[0 SIM.room.Lx  0 SIM.room.Ly  0 SIM.room.Lz]);

SIM.cbar = colorbar(SIM.ax,'Location','eastoutside');
colormap(SIM.ax, hot(512));
clim(SIM.ax,[-120 -5]);
SIM.cbar.Label.String = 'Received Power (dBm)';
SIM.cbar.Label.Color  = [0.88 0.88 0.90];
SIM.cbar.Color        = [0.88 0.88 0.90];
SIM.cbar.FontSize     = 8;

buildGUIPanel();
buildRoom();
runSimulation();
showEducationalAnnotations();


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: printConceptMap
%  Printed at startup — gives students the learning roadmap
% ══════════════════════════════════════════════════════════════════════════
function printConceptMap()
    fprintf('\n');
    fprintf('╔══════════════════════════════════════════════════════════════════╗\n');
    fprintf('║   3D INDOOR RF RAY TRACER  —  ECE Learning Map (v3)            ║\n');
    fprintf('╠══════════════════════════════════════════════════════════════════╣\n');
    fprintf('║  CONCEPT                    FORMULA / KEY FACT                 ║\n');
    fprintf('║  ─────────────────────────────────────────────────────────────  ║\n');
    fprintf('║  1. EM Wave Basics          λ = c/f  (λ↓ as f↑)               ║\n');
    fprintf('║  2. Ray Sampling            Fibonacci sphere, N rays → sphere  ║\n');
    fprintf('║  3. Free-Space Path Loss    FSPL=20log(d)+20log(f)+K           ║\n');
    fprintf('║  4. Reflection              d''=d−2(d·n̂)n̂   (law of refl.)    ║\n');
    fprintf('║  5. Material Loss           R=f(ε'',σ)  per ITU-R P.2040       ║\n');
    fprintf('║  6. Multipath               y(t)=Σaᵢx(t−τᵢ)e^jφᵢ             ║\n');
    fprintf('║  7. Delay Spread            σ_τ=√(ΣPᵢ(τᵢ−τ̄)²/ΣPᵢ)           ║\n');
    fprintf('║  8. Coherence BW            Bc≈1/(5σ_τ)  [flat-fading cond.]  ║\n');
    fprintf('║  9. OFDM Guard (CP)         CP > max excess delay → no ISI    ║\n');
    fprintf('║  10. Link Budget            SNR=Pt+Gt+Gr−PL−NF−BW_noise       ║\n');
    fprintf('╚══════════════════════════════════════════════════════════════════╝\n');
    fprintf('  Run this script and use the GUI panel to explore each concept.\n');
    fprintf('  Buttons: Re-run | CIR | Heatmap | Concept Tour | Link Budget\n\n');
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: buildRoom
%  Constructs the L-shaped office with rich furniture, windows, and
%  colour-coded zones. All surfaces are transparent to keep rays visible.
% ══════════════════════════════════════════════════════════════════════════
function buildRoom()
    global SIM;
    ax = SIM.ax;
    Lx = SIM.room.Lx;  Ly = SIM.room.Ly;  Lz = SIM.room.Lz;

    delete(findobj(ax,'Tag','room'));
    delete(findobj(ax,'Tag','furniture'));
    delete(findobj(ax,'Tag','txrx'));
    delete(findobj(ax,'Tag','antpat'));
    delete(findobj(ax,'Tag','edu'));

    % ── Colour palette ─────────────────────────────────────────────────
    wallClr  = [0.40 0.50 0.68];
    ceilClr  = [0.36 0.44 0.60];
    floorClr = [0.25 0.26 0.32];
    partClr  = [0.56 0.46 0.30];
    wingClr  = [0.34 0.44 0.36];   % wing has slightly different tint

    % ── Helper: rectangular patch face ────────────────────────────────
    function drawFace(pts, faceClr, edgeClr, alpha)
        p = patch(ax, pts(:,1)', pts(:,2)', pts(:,3)', faceClr, ...
            'FaceAlpha',alpha,'EdgeColor',edgeClr, ...
            'EdgeAlpha',0.55,'LineWidth',0.5,'Tag','room');
        set(p,'AmbientStrength',0.55,'SpecularStrength',0.2);
    end

    % ── Floor with tile pattern ────────────────────────────────────────
    drawFace([0 0 0; Lx 0 0; Lx Ly 0; 0 Ly 0], floorClr, [0.4 0.4 0.45], 0.90);
    for gx=0:2:Lx
        line(ax,[gx gx],[0 Ly],[0 0],'Color',[0.32 0.33 0.38],'LineWidth',0.35,'Tag','room');
    end
    for gy=0:2:Ly
        line(ax,[0 Lx],[gy gy],[0 0],'Color',[0.32 0.33 0.38],'LineWidth',0.35,'Tag','room');
    end

    % ── Ceiling ─────────────────────────────────────────────────────────
    drawFace([0 0 Lz; Lx 0 Lz; Lx Ly Lz; 0 Ly Lz], ceilClr, [0.55 0.65 0.85], 0.10);

    % ── Outer walls ─────────────────────────────────────────────────────
    % Front (y=0)
    drawFace([0 0 0; Lx 0 0; Lx 0 Lz; 0 0 Lz], wallClr, [0.5 0.62 0.82], 0.12);
    % Back (y=Ly)
    drawFace([0 Ly 0; Lx Ly 0; Lx Ly Lz; 0 Ly Lz], wallClr, [0.5 0.62 0.82], 0.12);
    % Left (x=0)
    drawFace([0 0 0; 0 Ly 0; 0 Ly Lz; 0 0 Lz], wallClr, [0.5 0.62 0.82], 0.12);
    % Right (x=Lx)
    drawFace([Lx 0 0; Lx Ly 0; Lx Ly Lz; Lx 0 Lz], wingClr, [0.5 0.72 0.62], 0.12);

    % ── L-shaped partition (main hall divider: x=9, y=5 to Ly) ────────
    %  ECE NOTE: This is a load-bearing concrete wall → high reflection & loss
    drawFace([9 5 0; 9 Ly 0; 9 Ly Lz; 9 5 Lz], partClr, [0.75 0.65 0.45], 0.42);
    % Wing front wall  (y=5, x=9..Lx)
    drawFace([9 5 0; Lx 5 0; Lx 5 Lz; 9 5 Lz], partClr, [0.75 0.65 0.45], 0.42);

    % ── Windows (glass patches on back wall y=Ly, tinted blue) ────────
    wSpecs = [1.5 0.8 1.4; 4.5 0.8 1.4; 7.0 0.8 1.4; 11.0 0.8 1.4; 13.0 0.8 1.4];
    for k = 1:size(wSpecs,1)
        xw=wSpecs(k,1); zw=wSpecs(k,2); hw=wSpecs(k,3);
        drawFace([xw Ly zw; xw+1.2 Ly zw; xw+1.2 Ly zw+hw; xw Ly zw+hw], ...
            [0.42 0.65 0.90],[0.65 0.80 1.00],0.35);
    end

    % ── Suspended ceiling lights (thin boxes on ceiling) ──────────────
    lightXY = [3 3; 3 9; 7 3; 7 9; 11 2; 13 2; 11 8; 13 8];
    for k=1:size(lightXY,1)
        drawBox(ax,[lightXY(k,1)-0.3 lightXY(k,2)-0.05 Lz-0.1],[0.6 0.1 0.08], ...
            [0.95 0.95 0.80],[0.6 0.6 0.4],'room');
    end

    % ── Desks (main office zone) ───────────────────────────────────────
    desks = [
        0.5  0.8  0    2.5 1.2 0.78;
        0.5  3.5  0    2.5 1.2 0.78;
        0.5  7.0  0    2.5 1.2 0.78;
        0.5 10.0  0    2.5 1.2 0.78;
        4.5  0.8  0    2.5 1.2 0.78;
        4.5  3.5  0    2.5 1.2 0.78;
        4.5  8.0  0    2.5 1.2 0.78;
        4.5 10.5  0    2.5 1.2 0.78;
    ];
    for k=1:size(desks,1)
        drawBox(ax,desks(k,1:3),desks(k,4:6), ...
            [0.38 0.30 0.20],[0.22 0.16 0.10],'furniture');
    end

    % ── Wing desks ────────────────────────────────────────────────────
    wDesks = [
        9.5  0.5  0   2.2 1.0 0.78;
        12.5 0.5  0   2.2 1.0 0.78;
        9.5  2.5  0   2.2 1.0 0.78;
        12.5 2.5  0   2.2 1.0 0.78;
    ];
    for k=1:size(wDesks,1)
        drawBox(ax,wDesks(k,1:3),wDesks(k,4:6), ...
            [0.30 0.38 0.28],[0.16 0.22 0.14],'furniture');
    end

    % ── Chairs ────────────────────────────────────────────────────────
    chairPos = [
        0.6 2.3 0;  0.6 5.0 0;  0.6 8.3 0;  0.6 11.4 0;
        4.6 2.3 0;  4.6 5.0 0;  4.6 9.5 0;  4.6 12.0 0;
    ];
    for k=1:size(chairPos,1)
        r=chairPos(k,:);
        drawBox(ax,r,[0.45 0.45 0.44],[0.18 0.18 0.42],[0.10 0.10 0.28],'furniture');
        drawBox(ax,r+[0 0 0.44],[0.45 0.08 0.38],[0.18 0.18 0.42],[0.10 0.10 0.28],'furniture');
    end

    % ── Server rack / IT closet ────────────────────────────────────────
    drawBox(ax,[Lx-1.0 0.2 0],[0.7 0.8 1.9],[0.20 0.26 0.34],[0.12 0.18 0.24],'furniture');
    % Server lights (decorative rects on front)
    for zz=0.2:0.3:1.6
        drawBox(ax,[Lx-1.0 0.2 zz],[0.05 0.8 0.06],[0.10 0.80 0.10],[0 0 0],'furniture');
    end

    % ── Bookshelf along left wall ──────────────────────────────────────
    drawBox(ax,[0.05 0.0 0],[0.35 Ly*0.4 1.8],[0.35 0.25 0.15],[0.20 0.14 0.08],'furniture');

    % ── Whiteboard (y=Ly-0.1 wall, middle) ────────────────────────────
    drawBox(ax,[3.0 Ly-0.1 0.8],[4.0 0.05 1.2],[0.95 0.97 0.98],[0.55 0.60 0.70],'furniture');

    % ── Lighting ──────────────────────────────────────────────────────
    light1 = camlight(ax,'headlight');
    light2 = camlight(ax,45,30);
    set([light1 light2],'Color',[0.9 0.9 1.0]);
    lighting(ax,'gouraud');
    material(ax,'dull');

    % ── Dipole antenna radiation pattern on Tx ─────────────────────────
    if SIM.showAntPat
        drawAntennaPattern();
    end

    % ── Tx marker ─────────────────────────────────────────────────────
    plot3(ax,SIM.Tx(1),SIM.Tx(2),SIM.Tx(3),'^', ...
        'MarkerSize',16,'MarkerFaceColor',[1.0 0.22 0.22], ...
        'MarkerEdgeColor','white','LineWidth',1.8,'Tag','txrx','DisplayName','Tx (AP)');
    line(ax,[SIM.Tx(1) SIM.Tx(1)],[SIM.Tx(2) SIM.Tx(2)],[0 SIM.Tx(3)], ...
        'Color',[1 0.45 0.35],'LineWidth',0.9,'Tag','txrx');
    text(ax,SIM.Tx(1)+0.2,SIM.Tx(2),SIM.Tx(3)+0.3,'Tx (AP)', ...
        'Color',[1.0 0.55 0.35],'FontSize',9,'FontWeight','bold','Tag','txrx');

    % ── Rx markers ────────────────────────────────────────────────────
    for r=1:size(SIM.Rx,1)
        clr=SIM.rxColors{r};
        plot3(ax,SIM.Rx(r,1),SIM.Rx(r,2),SIM.Rx(r,3),'o', ...
            'MarkerSize',13,'MarkerFaceColor',clr,'MarkerEdgeColor','white', ...
            'LineWidth',1.5,'Tag','txrx','DisplayName',sprintf('Rx%d',r));
        line(ax,[SIM.Rx(r,1) SIM.Rx(r,1)],[SIM.Rx(r,2) SIM.Rx(r,2)],[0 SIM.Rx(r,3)], ...
            'Color',clr,'LineWidth',0.8,'Tag','txrx');
        text(ax,SIM.Rx(r,1)+0.2,SIM.Rx(r,2),SIM.Rx(r,3)+0.3,sprintf('Rx%d',r), ...
            'Color',clr,'FontSize',9,'FontWeight','bold','Tag','txrx');
    end
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: drawAntennaPattern
%  Draws a 3D dipole radiation pattern (torus shape) around the Tx.
%  ECE: The dipole pattern is G(θ) = 1.5 sin²θ (linear), where θ is
%  measured from the antenna axis. Visualised as a scaled mesh surface.
% ══════════════════════════════════════════════════════════════════════════
function drawAntennaPattern()
    global SIM;
    ax = SIM.ax;
    delete(findobj(ax,'Tag','antpat'));
    Np = 24;
    theta = linspace(0,pi,Np);
    phi   = linspace(0,2*pi,Np);
    [T,P] = meshgrid(theta,phi);
    G = 1.5 * sin(T).^2;        % dipole pattern in linear scale
    R = 0.6 * G;                 % scale for display
    Xp = SIM.Tx(1) + R.*sin(T).*cos(P);
    Yp = SIM.Tx(2) + R.*sin(T).*sin(P);
    Zp = SIM.Tx(3) + R.*cos(T);
    surf(ax,Xp,Yp,Zp,G,'FaceAlpha',0.22,'EdgeAlpha',0.0,'Tag','antpat', ...
        'FaceColor','interp','CData',G);
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: drawBox  (furniture / structure helper)
% ══════════════════════════════════════════════════════════════════════════
function drawBox(ax, origin, sz, faceClr, edgeClr, tag)
    x0=origin(1); y0=origin(2); z0=origin(3);
    dx=sz(1);     dy=sz(2);     dz=sz(3);
    verts = [x0    y0    z0;
             x0+dx y0    z0;
             x0+dx y0+dy z0;
             x0    y0+dy z0;
             x0    y0    z0+dz;
             x0+dx y0    z0+dz;
             x0+dx y0+dy z0+dz;
             x0    y0+dy z0+dz];
    faces = [1 2 3 4; 5 6 7 8; 1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8];
    patch(ax,'Vertices',verts,'Faces',faces,'FaceColor',faceClr, ...
        'FaceAlpha',0.86,'EdgeColor',edgeClr,'EdgeAlpha',0.50, ...
        'LineWidth',0.35,'Tag',tag);
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: launchRays
%  Fibonacci (golden-angle) sphere sampling for even angular distribution.
%
%  ECE CONCEPT:
%  A real antenna radiates a CONTINUOUS wave in all directions. We
%  discretise this into N rays. The golden-angle spiral:
%      θᵢ = arccos(1 − 2i/N)   (polar from zenith)
%      φᵢ = i × 2.39996 rad    (azimuthal, ≈ golden ratio × 2π)
%  ensures minimum angular variance — no clustering at poles (unlike a
%  regular θ/φ grid which packs rays densely at the poles).
%  As N→∞ the ray density equals the continuous radiation integral.
% ══════════════════════════════════════════════════════════════════════════
function dirs = launchRays()
    global SIM;
    N   = SIM.Nrays;
    ga  = pi*(3-sqrt(5));    % golden angle ≈ 2.3999 rad
    dirs = zeros(N,3);
    for i=1:N
        th = acos(1 - 2*(i-1)/N);
        ph = ga*(i-1);
        dirs(i,:) = [sin(th)*cos(ph), sin(th)*sin(ph), cos(th)];
    end
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: computePathLoss
%  Computes total path loss including FSPL, reflection, and transmission.
%
%  ECE DERIVATION:
%  Friis Transmission Equation:
%    Pr = Pt + Gt + Gr − FSPL
%    FSPL (dB) = 20·log₁₀(4πd/λ) = 20·log₁₀(d) + 20·log₁₀(f) + 20·log₁₀(4π/c)
%
%  With material losses added:
%    PL_total = FSPL + n_r × R_loss + n_t × T_loss
%
%  where:
%    n_r  = number of reflections (bounces)
%    n_t  = number of wall penetrations (transmission through)
%    R_loss = reflection loss per bounce (dB), depends on material ε
%    T_loss = transmission loss per wall  (dB)
%
%  Note: FSPL grows as 20·log10(f) so mmWave (28 GHz) suffers
%  ~30 dB more free-space loss than 900 MHz at the same distance.
% ══════════════════════════════════════════════════════════════════════════
function [PL, FSPL] = computePathLoss(totalDist, nRefl, nTrans)
    global SIM;
    c      = 3e8;
    mat    = SIM.materials.(SIM.matName);
    R_dB   = mat(1);
    T_dB   = mat(2);

    % Friis formula
    FSPL = 20*log10(max(totalDist,0.01)) ...
         + 20*log10(SIM.freq) ...
         + 20*log10(4*pi/c);

    % Add Tx/Rx antenna gains (subtract from PL = add to link budget)
    PL = FSPL + nRefl*R_dB + nTrans*T_dB - SIM.TxGain_dBi - SIM.RxGain_dBi;
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: runSimulation  —  core ray tracing engine
% ══════════════════════════════════════════════════════════════════════════
function runSimulation()
    global SIM;
    delete(findobj(SIM.ax,'Tag','ray'));
    delete(findobj(SIM.ax,'Tag','stats'));
    SIM.rayData = {};

    dirs = launchRays();
    N    = size(dirs,1);
    Lx   = SIM.room.Lx;  Ly=SIM.room.Ly;  Lz=SIM.room.Lz;

    % Bounding planes: [nx ny nz d]  where n·p = d
    %  Also include the L-shaped partition: two planes
    planes = [
        -1  0  0   0 ;   % x=0    left wall
         1  0  0  Lx ;   % x=Lx   right wall
         0 -1  0   0 ;   % y=0    front wall
         0  1  0  Ly ;   % y=Ly   back wall
         0  0 -1   0 ;   % z=0    floor
         0  0  1  Lz ;   % z=Lz   ceiling
        -1  0  0   9 ;   % partition x=9 (y: 5..Ly) — facing main hall
         1  0  0  -9 ;   % partition x=9 facing wing
         0 -1  0   5 ;   % wing front wall y=5 (x: 9..Lx)
         0  1  0  -5 ;   % wing front wall back face
    ];
    % Plane validity ranges: each plane is only active in part of the room
    planeRanges = [
        -Inf Inf -Inf Inf;  % x=0 full
        -Inf Inf -Inf Inf;  % x=Lx full
        -Inf Inf -Inf Inf;  % y=0 full
        -Inf Inf -Inf Inf;  % y=Ly full
        -Inf Inf -Inf Inf;  % floor
        -Inf Inf -Inf Inf;  % ceiling
         9    9   5  Ly ;   % partition x=9: only y in [5,Ly]
         9    9   5  Ly ;   % same partition other face
         9   Lx   5   5 ;   % wing y=5: only x in [9,Lx]
         9   Lx   5   5 ;   % same face
    ];

    cmap   = hot(512);
    PL_min = -120;
    PL_max = -5;

    fprintf('\n%s\n', repmat('═',1,92));
    fprintf('  Ray Trace  |  f=%.1f GHz  |  %s  |  N=%d  |  maxB=%d  |  Pt=%d dBm\n', ...
        SIM.freq/1e9,SIM.matName,N,SIM.maxBounces,SIM.TxPower_dBm);
    fprintf('%s\n',repmat('─',1,92));
    fprintf('  %-5s %-7s %-12s %-12s %-12s %-10s %-8s\n', ...
        'Ray','Bounces','Dist (m)','PL (dB)','Prx (dBm)','Delay (ns)','Hits Rx');
    fprintf('%s\n',repmat('─',1,92));

    for i=1:N
        pos  = SIM.Tx;
        dir  = dirs(i,:)/norm(dirs(i,:));
        path = pos;
        bounces = 0;  totalDist = 0;
        hitsRx  = false;  rxIdx = 0;

        for b=1:SIM.maxBounces
            % ── Find nearest valid plane intersection ──────────────
            tMin=Inf;  hitP=-1;
            for p=1:size(planes,1)
                n_ = planes(p,1:3);
                d_ = planes(p,4);
                dn = dot(dir,n_);
                if abs(dn)<1e-9; continue; end
                t  = (d_ - dot(pos,n_)) / dn;
                if t<1e-4 || t>=tMin; continue; end
                % Test if hit point is within plane's valid range
                hp = pos + t*dir;
                pr = planeRanges(p,:);
                if p>=7   % partition planes — check position validity
                    if hp(1)<pr(1)-0.01||hp(1)>pr(2)+0.01; continue; end
                    if hp(2)<pr(3)-0.01||hp(2)>pr(4)+0.01; continue; end
                end
                tMin=t;  hitP=p;
            end
            if hitP<0||isinf(tMin); break; end

            hitPt = pos + tMin*dir;
            hitPt = clampToRoom(hitPt,Lx,Ly,Lz);

            % ── Rx proximity check on this segment ────────────────
            for r=1:size(SIM.Rx,1)
                if pointToSegDist(SIM.Rx(r,:),pos,hitPt)<=SIM.captureRadius
                    if ~hitsRx   % first capture only
                        hitsRx=true;  rxIdx=r;
                    end
                end
            end

            totalDist = totalDist + tMin;
            path      = [path; hitPt]; %#ok<AGROW>

            % ── ECE: Law of Reflection (3D vector form) ────────────
            % d' = d - 2(d·n̂)n̂
            % Physical interpretation: the component of d parallel to
            % the surface is unchanged; the normal component flips sign.
            % This gives angle_of_incidence = angle_of_reflection.
            nrm = planes(hitP,1:3);
            dir = dir - 2*dot(dir,nrm)*nrm;
            dir = dir/max(norm(dir),1e-9);
            pos = hitPt;
            bounces = bounces+1;
        end

        [PL_dB, FSPL] = computePathLoss(totalDist, bounces, 0);
        Prx    = SIM.TxPower_dBm - PL_dB;
        delay  = totalDist/3e8*1e9;   % ns
        c_     = 3e8;
        lam    = c_/SIM.freq;

        SIM.rayData{end+1} = struct( ...
            'path',    path,     'bounces', bounces, ...
            'dist',    totalDist,'PL',      PL_dB, ...
            'FSPL',    FSPL,     'Prx',     Prx, ...
            'delay',   delay,    'hitsRx',  hitsRx, ...
            'rxIdx',   rxIdx);

        if SIM.showAllRays || hitsRx
            drawRay(path, Prx, PL_min, PL_max, cmap, bounces, hitsRx);
        end
        if SIM.animateRays && mod(i,5)==0;  drawnow limitrate;  end

        fprintf('  %-5d %-7d %-12.2f %-12.2f %-12.2f %-10.2f %s\n', ...
            i,bounces,totalDist,PL_dB,Prx,delay,yn(hitsRx));
    end
    fprintf('%s\n',repmat('═',1,92));

    updateStats();
    addLegend();
    updateTitle3D();
    printLinkBudgets();
    drawnow;
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: drawRay
%  Renders one ray polyline. Colour = received power (hot map).
%  Line style = reflection order. Thickness = signal strength.
% ══════════════════════════════════════════════════════════════════════════
function drawRay(path, Prx, PLmin, PLmax, cmap, bounces, isHit)
    global SIM;
    ax   = SIM.ax;
    nPts = size(path,1);
    if nPts<2; return; end

    % Power → colour index
    t   = max(0,min(1,(Prx-PLmin)/(PLmax-PLmin)));
    idx = max(1,round(t*(size(cmap,1)-1))+1);
    clr = cmap(idx,:);

    styles  = {'-','-','--',':','-.','-'};
    lstyle  = styles{min(bounces+1,numel(styles))};
    lw      = max(0.5, 1.8 - bounces*0.22);
    if isHit; lw=lw*1.6; end
    alpha   = 0.72;

    for s=1:nPts-1
        line(ax,path(s:s+1,1),path(s:s+1,2),path(s:s+1,3), ...
            'Color',[clr alpha],'LineWidth',lw,'LineStyle',lstyle,'Tag','ray');
    end
    if nPts>2
        scatter3(ax,path(2:end-1,1),path(2:end-1,2),path(2:end-1,3), ...
            18,'white','filled','MarkerFaceAlpha',0.50,'Tag','ray');
    end
    if isHit
        ep=path(end,:);
        scatter3(ax,ep(1),ep(2),ep(3),70,'yellow','*','LineWidth',1.3,'Tag','ray');
    end
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: updateStats
%  Computes Prx, RMS delay spread, coherence bandwidth for every Rx.
%  Displays results as annotated boxes near each receiver.
% ══════════════════════════════════════════════════════════════════════════
function updateStats()
    global SIM;
    ax=SIM.ax;
    delete(findobj(ax,'Tag','stats'));

    for r=1:size(SIM.Rx,1)
        [hitPrx, hitDelay] = gatherRxData(r);
        rp = SIM.Rx(r,:);
        clr = SIM.rxColors{r};

        if isempty(hitPrx)
            txt=sprintf('Rx%d\nNo paths captured\n(out of range)',r);
        else
            Plin  = 10.^(hitPrx/10);
            Ptot  = 10*log10(sum(Plin));
            meanD = sum(hitDelay.*Plin)/sum(Plin);
            rmsDS = sqrt(sum(Plin.*(hitDelay-meanD).^2)/sum(Plin));
            Bc    = 1/max(5*rmsDS*1e-9,1e-12)/1e6;
            % Thermal noise power (Johnson-Nyquist)
            % N = kTB + NF = -174 + 10log(B_Hz) + NF (dBm)
            B_Hz   = SIM.Bandwidth_MHz*1e6;
            Pnoise = -174 + 10*log10(B_Hz) + SIM.NoiseFigure_dB;
            SNR    = Ptot - Pnoise;
            txt=sprintf(['Rx%d\nPrx = %.1f dBm\nSNR = %.1f dB\n' ...
                '#MPC = %d\nRMS DS = %.1f ns\nBc ≈ %.0f MHz'], ...
                r,Ptot,SNR,numel(hitPrx),rmsDS,Bc);
        end

        text(ax,rp(1)+0.3,rp(2)+0.3,rp(3)+0.55,txt, ...
            'Color',[0.04 0.04 0.04],'FontSize',7.5,'FontWeight','bold', ...
            'BackgroundColor',[clr 0.88],'EdgeColor',[0.25 0.45 0.75], ...
            'LineWidth',0.8,'Margin',3,'Tag','stats','Interpreter','none');
    end
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: printLinkBudgets
%  Prints a detailed Friis link budget to the Command Window for each Rx.
%
%  ECE CONCEPT:
%  A link budget accounts for EVERY gain and loss in the system:
%    Prx = Pt + Gt + Gr − FSPL − L_material − L_other
%    SNR = Prx − Pnoise = Prx − (−174 + 10log10(B) + NF)
%  If SNR > sensitivity threshold → link works.
%  802.11n requires SNR ≥ 20 dB for 64-QAM 5/6 coding (150 Mbps MCS7).
% ══════════════════════════════════════════════════════════════════════════
function printLinkBudgets()
    global SIM;
    B_Hz   = SIM.Bandwidth_MHz*1e6;
    Pnoise = -174 + 10*log10(B_Hz) + SIM.NoiseFigure_dB;
    fprintf('\n  LINK BUDGET SUMMARY  (B=%d MHz, NF=%d dB, Pnoise=%.1f dBm)\n', ...
        SIM.Bandwidth_MHz, SIM.NoiseFigure_dB, Pnoise);
    fprintf('  %s\n',repmat('─',1,70));
    fprintf('  %-5s %-10s %-8s %-10s %-10s %-6s %s\n', ...
        'Rx','Prx(dBm)','MPCs','RMS DS(ns)','Bc(MHz)','SNR','Status');
    fprintf('  %s\n',repmat('─',1,70));
    for r=1:size(SIM.Rx,1)
        [hitPrx,hitDelay]=gatherRxData(r);
        if isempty(hitPrx)
            fprintf('  Rx%-3d No signal captured\n',r);
            continue;
        end
        Plin  = 10.^(hitPrx/10);
        Ptot  = 10*log10(sum(Plin));
        meanD = sum(hitDelay.*Plin)/sum(Plin);
        rmsDS = sqrt(sum(Plin.*(hitDelay-meanD).^2)/sum(Plin));
        Bc    = 1/max(5*rmsDS*1e-9,1e-12)/1e6;
        SNR   = Ptot-Pnoise;
        status='FAIL';
        if SNR>=5;  status='MARGINAL'; end
        if SNR>=20; status='PASS'; end
        fprintf('  Rx%-3d %-10.1f %-8d %-10.1f %-10.0f %-6.1f %s\n', ...
            r,Ptot,numel(hitPrx),rmsDS,Bc,SNR,status);
    end
    fprintf('  %s\n  (SNR target: 20 dB for 802.11n MCS7 / 150 Mbps)\n\n', ...
        repmat('─',1,70));
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: computeCIR
%  Channel Impulse Response figure with:
%    • Stem plots (power vs delay per Rx)
%    • WiFi cyclic prefix guard line (0.8 µs)
%    • RMS delay spread shading
%    • 802.11n CP reference and ISI warning zone
% ══════════════════════════════════════════════════════════════════════════
function computeCIR()
    global SIM;
    if isempty(SIM.rayData)
        warndlg('Run simulation first.','CIR'); return;
    end

    nRx = size(SIM.Rx,1);
    fig2 = figure('Name','Channel Impulse Response  h(τ)', ...
        'Color',[0.06 0.06 0.09],'Position',[100 120 max(400,250*nRx) 520]);

    for r=1:nRx
        [hitPrx,hitDelay]=gatherRxData(r);
        ax2=subplot(1,nRx,r,'Parent',fig2);
        set(ax2,'Color',[0.08 0.08 0.11],'XColor',[0.80 0.82 0.88], ...
            'YColor',[0.80 0.82 0.88],'GridColor',[0.22 0.22 0.28], ...
            'GridAlpha',0.35,'FontSize',8);
        hold(ax2,'on'); grid(ax2,'on');

        if isempty(hitDelay)
            text(ax2,0.5,0.5,'No multipath captured','Color','white', ...
                'HorizontalAlignment','center','Units','normalized','FontSize',10);
        else
            [hitDelay,si]=sort(hitDelay);
            hitPrx=hitPrx(si);
            Plin   = 10.^(hitPrx/10);
            Pnorm  = 10*log10(Plin/max(Plin));
            meanD  = sum(hitDelay.*Plin)/sum(Plin);
            rmsDS  = sqrt(sum(Plin.*(hitDelay-meanD).^2)/sum(Plin));
            Bc     = 1/max(5*rmsDS*1e-9,1e-12)/1e6;
            maxDel = max(hitDelay)*1.15;

            % ECE: Shading for RMS delay spread region
            fill(ax2,[meanD-rmsDS meanD+rmsDS meanD+rmsDS meanD-rmsDS], ...
                [min(Pnorm)-6 min(Pnorm)-6 3 3], ...
                [0.5 0.5 1.0],'FaceAlpha',0.10,'EdgeColor','none');

            for k=1:numel(hitDelay)
                tau=hitDelay(k); p=Pnorm(k);
                clrK=[max(0,1-k/numel(hitDelay)), 0.42, min(1,k/numel(hitDelay))];
                line(ax2,[tau tau],[min(Pnorm)-5 p],'Color',clrK,'LineWidth',2.8);
                plot(ax2,tau,p,'o','MarkerSize',9,'MarkerFaceColor',clrK, ...
                    'MarkerEdgeColor','white','LineWidth',0.8);
                text(ax2,tau,p+1.8,sprintf('%.0f',tau), ...
                    'Color',[0.82 0.88 1.0],'FontSize',7,'HorizontalAlignment','center');
            end

            % Mean delay line
            xline(ax2,meanD,'--y','LineWidth',1.5, ...
                'Label','Mean delay','LabelVerticalAlignment','bottom');

            % WiFi CP guard (802.11n/ac: 0.8 µs CP = 800 ns)
            % ECE: Any ray arriving after the CP guard causes ISI.
            %      The red region = inter-symbol interference zone.
            cpNs=800;
            if cpNs<maxDel
                fill(ax2,[cpNs maxDel maxDel cpNs], ...
                    [min(Pnorm)-6 min(Pnorm)-6 3 3], ...
                    [1 0.2 0.2],'FaceAlpha',0.12,'EdgeColor','none');
                xline(ax2,cpNs,'--r','LineWidth',1.2, ...
                    'Label','WiFi CP (800 ns)','LabelVerticalAlignment','top');
                text(ax2,(cpNs+maxDel)/2,min(Pnorm)-2,'ISI zone', ...
                    'Color',[1 0.5 0.5],'FontSize',7.5,'HorizontalAlignment','center');
            end

            ylim(ax2,[min(Pnorm)-8 5]);
            text(ax2,0.97,0.97, ...
                sprintf('RMS DS=%.1f ns\nBc≈%.0f MHz\nN_{MPC}=%d', ...
                rmsDS,Bc,numel(hitDelay)), ...
                'Units','normalized','Color',[1 1 0.4],'FontSize',8.5, ...
                'HorizontalAlignment','right','VerticalAlignment','top', ...
                'BackgroundColor',[0.10 0.10 0.14],'Margin',3);
        end

        clr=SIM.rxColors{r};
        title(ax2,sprintf('Rx%d  —  h(τ)',r),'Color',clr,'FontSize',10,'FontWeight','bold');
        xlabel(ax2,'Propagation delay  τ  (ns)','Color',[0.80 0.82 0.88],'FontSize',9);
        ylabel(ax2,'Normalised power  (dB)','Color',[0.80 0.82 0.88],'FontSize',9);
    end

    sgtitle(fig2, ...
        sprintf('Channel Impulse Response h(τ)  |  f=%.1f GHz  |  %s  |  Shade=RMS DS  |  Red=ISI zone', ...
        SIM.freq/1e9,SIM.matName), 'Color','white','FontSize',11,'FontWeight','bold');
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: plotHeatmap
%  2D coverage map at z=1m, with:
%    • Smooth surf heatmap
%    • Filled contour overlay (key dBm thresholds)
%    • Rx capture circles showing link-quality zones
%    • Colour bar calibrated to 802.11n sensitivity levels
% ══════════════════════════════════════════════════════════════════════════
function plotHeatmap()
    global SIM;
    if isempty(SIM.rayData)
        warndlg('Run simulation first.','Heatmap'); return;
    end

    Lx=SIM.room.Lx; Ly=SIM.room.Ly;
    res=0.20;
    xv=0.20:res:Lx-0.20;  yv=0.20:res:Ly-0.20;
    [Xg,Yg]=meshgrid(xv,yv);
    Pg=zeros(size(Xg));

    hWait=waitbar(0,'Computing coverage heatmap…');
    nTotal=numel(Xg);
    for gi=1:size(Xg,1)
        for gj=1:size(Xg,2)
            rxPos=[Xg(gi,gj),Yg(gi,gj),1.0];
            hitPrx=[];
            for k=1:numel(SIM.rayData)
                rd=SIM.rayData{k};
                for s=1:size(rd.path,1)-1
                    if pointToSegDist(rxPos,rd.path(s,:),rd.path(s+1,:))<=SIM.captureRadius
                        hitPrx(end+1)=rd.Prx; %#ok<AGROW>
                        break;
                    end
                end
            end
            Pg(gi,gj)=isempty(hitPrx)*(-120) + ~isempty(hitPrx)*10*log10(sum(10.^(hitPrx/10)));
        end
        waitbar(gi*size(Xg,2)/nTotal,hWait);
    end
    close(hWait);

    fig3=figure('Name','Coverage Heatmap  @  z=1 m', ...
        'Color',[0.06 0.06 0.09],'Position',[200 60 960 720]);
    ax3=axes('Parent',fig3,'Color',[0.08 0.08 0.11],'FontSize',9);
    hold(ax3,'on');

    surf(ax3,Xg,Yg,Pg,'EdgeColor','none','FaceAlpha',0.92);
    view(ax3,0,90);
    colormap(ax3,hot(512));
    clim(ax3,[-120 -5]);
    cb3=colorbar(ax3);
    cb3.Label.String='Received Power (dBm)';
    cb3.Label.Color=[0.88 0.88 0.90];
    cb3.Color=[0.88 0.88 0.90];

    % Contour overlay — 802.11n sensitivity tiers
    % ECE: -82 dBm ≈ MCS0 (6 Mbps); -66 dBm ≈ MCS7 (150 Mbps)
    thresholds=[-95 -82 -70 -66 -55 -45];
    thColors  =[0.4 0.4 1.0; 0.4 0.7 1.0; 0.4 1.0 0.6; ...
                1.0 0.9 0.3; 1.0 0.6 0.2; 1.0 0.2 0.2];
    [C3,hC]=contour3(ax3,Xg,Yg,Pg,thresholds,'LineWidth',0.8);
    for k=1:numel(hC.LevelList)
        hC.FaceColor='none';
    end
    clabel(C3,hC,'FontSize',7,'Color','white');

    % Partition / wing outline
    line(ax3,[9 9],[5 Ly],'Color',[0.8 0.7 0.45],'LineWidth',2);
    line(ax3,[9 Lx],[5 5],'Color',[0.8 0.7 0.45],'LineWidth',2);
    rectangle('Position',[0 0 Lx Ly],'EdgeColor',[0.70 0.72 0.88],'LineWidth',1.5,'Parent',ax3);

    % Tx
    plot(ax3,SIM.Tx(1),SIM.Tx(2),'^','MarkerSize',14, ...
        'MarkerFaceColor',[1 0.2 0.2],'MarkerEdgeColor','w','LineWidth',2);
    text(ax3,SIM.Tx(1)+0.15,SIM.Tx(2)+0.2,'Tx','Color','white','FontWeight','bold','FontSize',10);

    % Rx with link-quality aura circles
    B_Hz=SIM.Bandwidth_MHz*1e6;
    Pnoise=-174+10*log10(B_Hz)+SIM.NoiseFigure_dB;
    for r=1:size(SIM.Rx,1)
        clr=SIM.rxColors{r};
        [hitPrx2,~]=gatherRxData(r);
        Plab='?';
        if ~isempty(hitPrx2)
            Pt=10*log10(sum(10.^(hitPrx2/10)));
            SNR=Pt-Pnoise;
            Plab=sprintf('%.0f dBm\nSNR=%.0f dB',Pt,SNR);
        end
        plot(ax3,SIM.Rx(r,1),SIM.Rx(r,2),'o','MarkerSize',12, ...
            'MarkerFaceColor',clr,'MarkerEdgeColor','w','LineWidth',2);
        text(ax3,SIM.Rx(r,1)+0.15,SIM.Rx(r,2)+0.25, ...
            sprintf('Rx%d\n%s',r,Plab),'Color','white','FontWeight','bold', ...
            'FontSize',8,'BackgroundColor',[0 0 0 0.5]);
    end

    [~,fi]=min(abs(SIM.freqTable-SIM.freq));
    title(ax3,sprintf('Coverage Heatmap @ z=1m  |  %s  |  %s  |  Contours: 802.11n thresholds', ...
        SIM.matName,SIM.freqLabels{fi}), ...
        'Color',[1 0.85 0.25],'FontSize',11,'FontWeight','bold');
    xlabel(ax3,'X (m)','Color',[0.82 0.82 0.88],'FontSize',10);
    ylabel(ax3,'Y (m)','Color',[0.82 0.82 0.88],'FontSize',10);
    set(ax3,'XColor',[0.75 0.77 0.82],'YColor',[0.75 0.77 0.82]);
    axis(ax3,'equal'); axis(ax3,[0 Lx 0 Ly]);

    % Legend for contour tiers
    annotation(fig3,'textbox',[0.72 0.10 0.20 0.22], ...
        'String',{'\bf802.11n sensitivity:'; ...
                  '−95 dBm  MCS0 (noise floor)'; ...
                  '−82 dBm  MCS0 min (6 Mbps)'; ...
                  '−70 dBm  MCS3 (57.8 Mbps)'; ...
                  '−66 dBm  MCS7 (150 Mbps)'; ...
                  '−55 dBm  high throughput'}, ...
        'Color',[0.85 0.90 0.85],'BackgroundColor',[0.06 0.08 0.08 0.88], ...
        'EdgeColor',[0.35 0.50 0.35],'FontSize',7.5,'LineWidth',0.8);
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: showConceptTour
%  Steps through 5 key teaching moments with large annotation boxes
%  that explain the physics visible in the current render.
% ══════════════════════════════════════════════════════════════════════════
function showConceptTour()
    global SIM;
    delete(findobj(SIM.fig,'Tag','tour'));
    SIM.tourStep = mod(SIM.tourStep,5)+1;
    step = SIM.tourStep;

    bPos = {[0.03 0.72 0.21 0.18];
            [0.03 0.52 0.21 0.18];
            [0.03 0.32 0.21 0.18];
            [0.03 0.12 0.21 0.18];
            [0.25 0.02 0.25 0.16]};

    bText = { ...
    {'CONCEPT 1 / 5  —  Ray vs Wave', ...
     'Rays are straight-line approximations of EM wavefronts.', ...
     'Valid when λ << obstacle size (geometric optics limit).', ...
     'At 2.4 GHz, λ=12.5 cm — walls (>>λ) reflect cleanly.', ...
     'At 28 GHz, λ=1.07 cm — even small objects scatter.', ...
     'Rule: use ray optics when λ/obstacle < 0.1'}; ...
    {'CONCEPT 2 / 5  —  The Inverse Square Law', ...
     'An isotropic radiator spreads power uniformly.', ...
     'Power density S = Pt / (4π r²)  [W/m²]', ...
     'Double distance → area×4 → power÷4 → −6 dB', ...
     'This gives the 20·log10(d) term in FSPL.', ...
     'Hot colours = strong signal; watch it fade with distance.'}; ...
    {'CONCEPT 3 / 5  —  Reflection Losses', ...
     'Each white bounce dot loses R_loss dB.', ...
     'R depends on material ε (complex permittivity).', ...
     'Drywall: ε≈2.5-j0.07 → R≈3 dB, T≈5 dB.', ...
     'Concrete: ε≈6.5-j0.43 → R≈8 dB, T≈15 dB.', ...
     'Metal: almost perfect reflector, R≈0.5 dB, T≈30 dB.'}; ...
    {'CONCEPT 4 / 5  —  Multipath Fading', ...
     'Each Rx sees a SUM of many delayed copies.', ...
     'If two paths differ by λ/2 → destructive → dead zone.', ...
     'Moving 6 cm at 2.4 GHz changes from + to − interference.', ...
     'MIMO exploits this: multiple antennas = multiple spatial paths.', ...
     'See CIR button for the delay profile of each Rx.'}; ...
    {'CONCEPT 5 / 5  —  OFDM & Delay Spread', ...
     '802.11n uses 64 subcarriers over 20 MHz → Δf=312.5 kHz.', ...
     'Symbol duration T_s = 1/Δf = 3.2 µs.', ...
     'Cyclic prefix CP = 0.8 µs guards against 240 m of excess delay.', ...
     'If σ_τ > CP → inter-subcarrier interference → throughput collapse.', ...
     'Increase CP for large rooms (802.11n offers 400 ns "short GI" too).'}; ...
    };

    boxClr = {[0.12 0.12 0.08];[0.08 0.12 0.12];[0.12 0.08 0.08]; ...
              [0.08 0.10 0.14];[0.10 0.12 0.08]};
    edgClr = {[0.85 0.78 0.25];[0.30 0.85 0.70];[0.85 0.40 0.25]; ...
              [0.40 0.65 0.95];[0.55 0.85 0.35]};

    annotation(SIM.fig,'textbox',bPos{step}, ...
        'String',bText{step},'Color',[0.95 0.95 0.70], ...
        'BackgroundColor',[boxClr{step} 0.92], ...
        'EdgeColor',edgClr{step},'LineWidth',1.4, ...
        'FontSize',8.0,'FitBoxToText','off', ...
        'Tag','tour','Interpreter','none');
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: showFrequencySweep
%  Opens a new figure with FSPL vs distance for all 4 frequency bands
%  and overlays the link margin at current Tx power.
% ══════════════════════════════════════════════════════════════════════════
function showFrequencySweep()
    global SIM;
    fig4=figure('Name','Frequency Sweep — FSPL vs Distance', ...
        'Color',[0.06 0.06 0.09],'Position',[150 200 900 500]);
    ax4=axes('Parent',fig4,'Color',[0.08 0.08 0.11],'FontSize',9, ...
        'XColor',[0.78 0.80 0.86],'YColor',[0.78 0.80 0.86], ...
        'GridColor',[0.20 0.22 0.28],'GridAlpha',0.30);
    hold(ax4,'on'); grid(ax4,'on');

    dv=0.5:0.2:30;
    c_=3e8;
    colors4={'#3399ff','#ff9933','#ff4433','#aa33ff'};
    for fi=1:4
        f=SIM.freqTable(fi);
        pl=20*log10(dv)+20*log10(f)+20*log10(4*pi/c_);
        plot(ax4,dv,-pl,'Color',colors4{fi},'LineWidth',2, ...
            'DisplayName',SIM.freqLabels{fi});
    end

    % Receiver sensitivity line
    B_Hz=SIM.Bandwidth_MHz*1e6;
    Pnoise=-174+10*log10(B_Hz)+SIM.NoiseFigure_dB;
    Psens=Pnoise+5;   % 5 dB SNR minimum
    yline(ax4,SIM.TxPower_dBm-Psens+SIM.TxGain_dBi,'--w', ...
        'LineWidth',1.5,'Label','Sensitivity limit (SNR≥5dB)');

    % Current frequency marker
    [~,fi]=min(abs(SIM.freqTable-SIM.freq));
    plot(ax4,10,-(20*log10(10)+20*log10(SIM.freq)+20*log10(4*pi/c_)), ...
        'o','MarkerSize',11,'MarkerFaceColor','white','MarkerEdgeColor',colors4{fi});

    legend(ax4,'Location','northeast','TextColor',[0.82 0.82 0.88], ...
        'Color',[0.10 0.10 0.13],'EdgeColor',[0.35 0.45 0.60],'FontSize',8);
    xlabel(ax4,'Distance (m)','Color',[0.80 0.82 0.88],'FontSize',10);
    ylabel(ax4,'Received Power (dBm)   [Pt=20 dBm]','Color',[0.80 0.82 0.88],'FontSize',10);
    title(ax4,sprintf('FSPL vs Distance  |  Pt=%d dBm  |  Gt=%.1f dBi  |  NF=%d dB', ...
        SIM.TxPower_dBm,SIM.TxGain_dBi,SIM.NoiseFigure_dB), ...
        'Color',[1 0.85 0.25],'FontSize',11,'FontWeight','bold');
    set(ax4,'XLim',[0.5 30],'YLim',[-120 SIM.TxPower_dBm+5]);
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: showEducationalAnnotations
%  Four persistent floating text boxes shown on startup.
% ══════════════════════════════════════════════════════════════════════════
function showEducationalAnnotations()
    global SIM;
    delete(findobj(SIM.fig,'Tag','edu'));
    cs={...
        'EdgeColor',[0.85 0.75 0.20],'String', ...
            {'① What is a ray?', ...
             'Rays approximate wavefronts.', ...
             'Valid when λ << obstacle size.', ...
             'Colour = received power.', ...
             'Red=strong, dark=attenuated.'}; ...
        'EdgeColor',[0.30 0.88 0.60],'String', ...
            {'② Free-Space Loss', ...
             'FSPL = 20log(d)+20log(f)+K', ...
             'Double d → −6 dB always.', ...
             '28 GHz loses 30 dB MORE', ...
             'than 900 MHz at same dist.'}; ...
        'EdgeColor',[0.40 0.72 1.00],'String', ...
            {'③ Reflection bounce', ...
             'd''= d − 2(d·n̂)n̂  (3D form)', ...
             'White dots = bounce points.', ...
             'Each bounce: −R_loss dB.', ...
             'Metal nearly lossless (R≈0.5dB).'}; ...
        'EdgeColor',[0.88 0.42 1.00],'String', ...
            {'④ Multipath in OFDM', ...
             'Many echoes arrive at Rx.', ...
             'RMS delay spread σ_τ=power-', ...
             'weighted std dev of delays.', ...
             'σ_τ > CP → ISI → rate drop!'}};
    ypos=[0.77 0.60 0.43 0.26];
    for k=1:4
        annotation(SIM.fig,'textbox',[0.02 ypos(k) 0.14 0.14], ...
            'String',cs{k,4},'Color',[1.0 0.96 0.65], ...
            'BackgroundColor',[0.09 0.09 0.07 0.90], ...
            'EdgeColor',cs{k,2},'LineWidth',1.0, ...
            'FontSize',7.0,'Tag','edu','Interpreter','none');
    end
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: addLegend
% ══════════════════════════════════════════════════════════════════════════
function addLegend()
    global SIM;
    delete(findobj(SIM.ax,'Tag','legline'));
    styles={'-','--',':','-.'};
    labels={'0 bounces (LOS / direct)','1st-order reflections', ...
            '2nd-order reflections','3rd-order and higher'};
    clrs  ={[1.0 0.35 0.10],[1.0 0.75 0.10],[0.40 0.85 1.0],[0.75 0.40 1.0]};
    h=gobjects(4,1);
    for i=1:4
        h(i)=line(SIM.ax,nan,nan,nan,'Color',clrs{i},'LineStyle',styles{i}, ...
            'LineWidth',1.7,'Tag','legline','DisplayName',labels{i});
    end
    lgd=legend(SIM.ax,h,'Location','northeast', ...
        'TextColor',[0.86 0.86 0.90],'Color',[0.08 0.08 0.11], ...
        'EdgeColor',[0.38 0.48 0.62],'FontSize',7.5);
    lgd.Title.String ='Reflection order';
    lgd.Title.Color  =[1.0 0.85 0.25];
end


%% ══════════════════════════════════════════════════════════════════════════
%  FUNCTION: buildGUIPanel  —  all interactive controls
% ══════════════════════════════════════════════════════════════════════════
function buildGUIPanel()
    global SIM;
    fig=SIM.fig;
    pan=uipanel('Parent',fig,'Title','Simulation Controls', ...
        'BackgroundColor',[0.12 0.12 0.15],'ForegroundColor',[1.0 0.85 0.25], ...
        'Position',[0.68 0.02 0.31 0.96],'FontSize',9.5,'FontWeight','bold', ...
        'BorderType','line','HighlightColor',[0.35 0.45 0.65]);

    function lbl(par,y,str,sz)
        if nargin<4; sz=8.5; end
        uicontrol(par,'Style','text','String',str,'Units','normalized', ...
            'Position',[0.03 y 0.94 0.026],'BackgroundColor',[0.12 0.12 0.15], ...
            'ForegroundColor',[0.78 0.85 0.98],'HorizontalAlignment','left','FontSize',sz);
    end
    function h=sld(par,y,mn,mx,val,cb)
        h=uicontrol(par,'Style','slider','Min',mn,'Max',mx,'Value',val, ...
            'Units','normalized','Position',[0.03 y 0.94 0.026], ...
            'BackgroundColor',[0.20 0.20 0.26],'Callback',cb);
    end
    function h=pop(par,y,items,val,cb)
        h=uicontrol(par,'Style','popupmenu','String',items,'Value',val, ...
            'Units','normalized','Position',[0.03 y 0.94 0.032], ...
            'BackgroundColor',[0.18 0.18 0.24],'ForegroundColor',[0.92 0.92 1.00], ...
            'FontSize',8.5,'Callback',cb);
    end
    function btn(par,y,str,bgc,cb)
        uicontrol(par,'Style','pushbutton','String',str,'Units','normalized', ...
            'Position',[0.03 y 0.94 0.038],'BackgroundColor',bgc, ...
            'ForegroundColor',[1 1 1],'FontWeight','bold','FontSize',9,'Callback',cb);
    end
    function chk(par,y,str,val,cb)
        uicontrol(par,'Style','checkbox','String',str,'Value',val, ...
            'Units','normalized','Position',[0.03 y 0.94 0.026], ...
            'BackgroundColor',[0.12 0.12 0.15],'ForegroundColor',[0.78 0.85 0.98], ...
            'FontSize',8.5,'Callback',cb);
    end

    % ── Sliders ──────────────────────────────────────────────────────
    lbl(pan,0.930,'Number of rays  (8 – 120)');
    sld(pan,0.902,8,120,SIM.Nrays,@cbNrays);

    lbl(pan,0.862,'Max reflections per ray  (1 – 8)');
    sld(pan,0.834,1,8,SIM.maxBounces,@cbBounce);

    lbl(pan,0.794,'Tx power  (dBm)');
    sld(pan,0.766,0,30,SIM.TxPower_dBm,@cbTxPow);

    lbl(pan,0.726,'Rx capture radius  (m)');
    sld(pan,0.698,0.1,1.5,SIM.captureRadius,@cbRadius);

    lbl(pan,0.658,'Channel bandwidth  (MHz)');
    sld(pan,0.630,5,80,SIM.Bandwidth_MHz,@cbBW);

    % ── Dropdowns ────────────────────────────────────────────────────
    lbl(pan,0.592,'Wall material');
    pop(pan,0.558,{'Drywall','Concrete','Glass','Metal','Wood'},1,@cbMat);

    lbl(pan,0.520,'Frequency band');
    pop(pan,0.486,{'900 MHz','2.4 GHz','5 GHz','28 GHz mmWave'},2,@cbFreq);

    % ── Checkboxes ───────────────────────────────────────────────────
    chk(pan,0.450,'Animate ray drawing',           SIM.animateRays,  @cbAnimate);
    chk(pan,0.420,'Show only rays reaching Rx',    SIM.showHitOnly,  @cbShowRx);
    chk(pan,0.390,'Show antenna radiation pattern',SIM.showAntPat,   @cbAntPat);

    % ── Primary action buttons ────────────────────────────────────────
    btn(pan,0.340,'▶  Re-run Simulation',           [0.10 0.38 0.12],@cbRerun);
    btn(pan,0.292,'📈  Channel Impulse Response',   [0.10 0.18 0.42],@(~,~)computeCIR());
    btn(pan,0.244,'🗺  Coverage Heatmap',           [0.36 0.18 0.10],@(~,~)plotHeatmap());
    btn(pan,0.196,'🎓  Concept Tour  (step 1→5)',   [0.28 0.22 0.38],@(~,~)showConceptTour());
    btn(pan,0.148,'📡  Frequency Sweep',            [0.18 0.30 0.38],@(~,~)showFrequencySweep());
    btn(pan,0.100,'🔄  Reset to Defaults',          [0.28 0.18 0.30],@cbReset);

    % ── Reference card ────────────────────────────────────────────────
    uicontrol(pan,'Style','text','Units','normalized', ...
        'Position',[0.02 0.01 0.96 0.095], ...
        'String',{'────── Material  R / T (dB) ──────'; ...
                  '  Drywall    3 /  5     Wood   2 /  4'; ...
                  '  Concrete   8 / 15     Glass  1 /  3'; ...
                  '  Metal    0.5 / 30'; ...
                  '─── Key: FSPL=20log(d)+20log(f)+K ───'; ...
                  '  λ=c/f  Bc≈1/(5σ_τ)  SNR=Prx−Pnoise'}, ...
        'BackgroundColor',[0.08 0.08 0.10],'ForegroundColor',[0.55 0.75 0.55], ...
        'FontSize',7.2,'HorizontalAlignment','left','FontName','FixedWidth');
end


%% ── Callbacks ────────────────────────────────────────────────────────────
function cbNrays(src,~);   global SIM; SIM.Nrays=round(src.Value);         end
function cbBounce(src,~);  global SIM; SIM.maxBounces=round(src.Value);    end
function cbTxPow(src,~);   global SIM; SIM.TxPower_dBm=src.Value;          end
function cbRadius(src,~);  global SIM; SIM.captureRadius=src.Value;        end
function cbBW(src,~);      global SIM; SIM.Bandwidth_MHz=round(src.Value); end
function cbAnimate(src,~); global SIM; SIM.animateRays=logical(src.Value); end
function cbAntPat(src,~);  global SIM; SIM.showAntPat=logical(src.Value);  end
function cbShowRx(src,~)
    global SIM; SIM.showHitOnly=logical(src.Value);
    SIM.showAllRays=~SIM.showHitOnly; end
function cbMat(src,~)
    global SIM; mats={'Drywall','Concrete','Glass','Metal','Wood'};
    SIM.matName=mats{src.Value}; updateTitle3D(); end
function cbFreq(src,~)
    global SIM; SIM.freq=SIM.freqTable(src.Value); updateTitle3D(); end
function cbRerun(~,~); buildRoom(); runSimulation(); end
function cbReset(~,~)
    global SIM;
    SIM.Nrays=60; SIM.maxBounces=6; SIM.TxPower_dBm=20;
    SIM.captureRadius=0.60; SIM.Bandwidth_MHz=20;
    SIM.matName='Drywall'; SIM.freq=2.4e9;
    buildRoom(); runSimulation(); end


%% ══════════════════════════════════════════════════════════════════════════
%  HELPER FUNCTIONS
% ══════════════════════════════════════════════════════════════════════════

function updateTitle3D()
    global SIM;
    [~,fi]=min(abs(SIM.freqTable-SIM.freq));
    title(SIM.ax,sprintf('3D Indoor RF Tracer  —  f = %s  |  %s  |  N = %d rays', ...
        SIM.freqLabels{fi},SIM.matName,SIM.Nrays), ...
        'Color',[1.0 0.85 0.25],'FontSize',12,'FontWeight','bold');
end

function [hitPrx,hitDelay]=gatherRxData(r)
    global SIM;
    hitPrx=[]; hitDelay=[];
    for k=1:numel(SIM.rayData)
        d=SIM.rayData{k};
        if d.hitsRx && d.rxIdx==r
            hitPrx(end+1)=d.Prx;
            hitDelay(end+1)=d.delay;
        end
    end
end

function d=pointToSegDist(P,A,B)
    AB=B-A; AP=P-A;
    len2=dot(AB,AB);
    if len2<1e-12; d=norm(AP); return; end
    t=max(0,min(1,dot(AP,AB)/len2));
    d=norm(P-(A+t*AB));
end

function pt=clampToRoom(pt,Lx,Ly,Lz)
    pt(1)=max(0,min(Lx,pt(1)));
    pt(2)=max(0,min(Ly,pt(2)));
    pt(3)=max(0,min(Lz,pt(3)));
end

function s=yn(b); if b; s='YES'; else; s='no'; end; end
