# DiodeTutor — 1N4148 Semiconductor Diode: A Visual Learning Journey

## Overview

**DiodeTutor** is a step-by-step MATLAB educational simulator for the 1N4148
silicon diode.  It is designed for electronics engineering students who have never
studied semiconductor device modelling before.

Each level introduces **exactly one** new physical concept — no more, no less.

---

## Quick Start

```matlab
DiodeTutor          % show the level menu
DiodeTutor(1)       % run Level 1 (Shockley equation)
DiodeTutor(3)       % jump to Level 3 (breakdown)
DiodeTutor('all')   % run all levels in sequence
```

---

## Folder Structure

```
DiodeTutor/
│
├── DiodeTutor.m               ← Main launcher and menu
├── diode_utils.m              ← Shared physics (solver, parameters, IS(T))
│
├── Level1_Shockley.m          ← Ideal Shockley diode equation
├── Level2_SeriesResistance.m  ← Series resistance Rs
├── Level3_Breakdown.m         ← Reverse breakdown (avalanche / Zener)
├── Level4_Temperature.m       ← Temperature effects on IS and Vf
├── Level5_SelfHeating.m       ← Self-heating thermal feedback loop
├── Level6_Capacitance.m       ← Junction capacitance Cj(Vd)
├── Level7_ReverseRecovery.m   ← Reverse recovery stored charge
│
└── DiodeTutor_README.md       ← This file
```

---

## Level Map

| Level | Title                | New Concept              | Key Equation                        |
|-------|----------------------|--------------------------|-------------------------------------|
| 1     | The Shockley Equation| Ideal exponential I-V    | I = IS·[exp(V/nVT) − 1]            |
| 2     | Series Resistance    | Ohmic drop inside diode  | V_ext = Vd + I·Rs                  |
| 3     | Reverse Breakdown    | Avalanche / Zener        | I_brk = −IBR0·exp((−V−VBR)/Vz)    |
| 4     | Temperature Effects  | IS(T) and VT(T) scaling  | IS(T) = IS0·(T/T0)^3·exp(...)      |
| 5     | Self-Heating         | Thermal feedback loop    | Tj = Ta + P·Rth;  P = Vd·I        |
| 6     | Junction Capacitance | Voltage-controlled cap   | Cj = Cj0/(1 − Vd/Vj)^M            |
| 7     | Reverse Recovery     | Stored minority charge   | dQ/dt = I_app − Q/τ_R              |

---

## Device Under Study: 1N4148

| Parameter    | Symbol | Value     | Notes                         |
|--------------|--------|-----------|-------------------------------|
| Sat. current | IS0    | 2.52 nA   | At 300 K                      |
| Ideality     | n      | 1.752     | Includes recombination        |
| Series R     | Rs     | 0.5 Ω     | Bulk + contacts               |
| R temp coeff | α_Rs   | 0.004/K   | Mobility decrease with T      |
| Breakdown    | V_BR   | 100 V     | Avalanche mechanism           |
| Thermal R    | Rth    | 300 °C/W  | Junction-to-ambient, free air |
| Zero-bias C  | Cj0    | 4 pF      |                               |
| Built-in V   | Vj     | 0.7 V     | Silicon contact potential     |
| Grading      | M      | 0.33      | Linearly graded junction      |
| Transit time | τ_F    | 1 ns      | Forward minority transit      |
| Recovery τ   | τ_R    | 6 ns      | Reverse recovery time const   |

---

## Learning Philosophy

1. **One concept per level** — cognitive load is controlled deliberately.
2. **Visual before mathematical** — every figure is designed to build intuition.
3. **Physical narrative first** — each level opens with a story, not an equation.
4. **Common misconceptions** — each level explicitly names what students often get wrong.
5. **Cumulative understanding** — each level builds on the one before it.

---

## Common Misconceptions Addressed

- The 0.7 V threshold is not a wall — it is a soft exponential knee (L1)
- Real diodes do not have infinite current — Rs limits it (L2)
- Breakdown does not mean destruction — it is controllable (L3)
- Higher temperature does NOT mean higher forward voltage (L4)
- Power = Vd·I, not Vext·I (L5)
- Cj formula breaks down in forward bias — use diffusion cap instead (L6)
- trr is when Q = 0, not when current begins to fall (L7)

---

## Suggested Study Path

### First encounter (60 minutes)
- Run Levels 1, 2, 3 consecutively
- Focus on the figures; read the console output

### Deep study (2–3 hours)
- Run all 7 levels
- Modify parameters (change Rs, V_BR, Rth) and observe the effect
- Try: what happens when you halve Rth in Level 5?

### Lab correlation
- Measure your own 1N4148 I-V and compare with Level 2 output
- Measure trr on an oscilloscope and compare with Level 7

---

## Extending the Tutor

To add Level 8 (e.g. SPICE parameter extraction):
1. Copy the template structure from `Level7_ReverseRecovery.m`
2. Add the new case to `DiodeTutor.m` switch statement
3. Add a new entry to the menu in `print_menu()`

---

## Further Reading

- Pierret, R.F. — *Semiconductor Device Fundamentals* (Ch. 6–7)
- Neamen, D.A. — *Microelectronics: Circuit Analysis and Design*
- Sze, S.M. — *Physics of Semiconductor Devices* (advanced)
- 1N4148 Datasheet: ON Semiconductor / Vishay / Nexperia

---

## Architecture Notes

`diode_utils.m` provides:
- `diode_params()` — all 1N4148 parameters in one struct
- `IS_T()` — SPICE temperature scaling
- `solveI()` — Newton-Raphson solver (handles Rs and breakdown)
- `print_separator()` / `heading()` — console formatting helpers

Each Level file:
- Is **self-contained** — can be run independently
- Calls `diode_utils` to avoid duplicating physics
- Produces exactly **one figure** with 2–4 subplots
- Prints a structured console explanation and learning summary
