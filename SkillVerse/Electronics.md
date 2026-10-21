# Electronics

A comprehensive curriculum covering the physical principles, analytical equations, characteristic curves, equivalent circuit models, and practical design applications of foundational electronic components.

---

## 1. [Resistors](Electronics/chapter_00001.md)
  - Basic Electrical Concepts ($V, I, R$)
  - Ohm's Law and Power Dissipation ($P = VI = I^2 R = V^2/R$)
  - Power Ratings and Thermal Derating Rules
  - Series and Parallel Resistor Configurations
  - Decoding Resistor Color Codes (4-Band and 5-Band Systems)
  - The Diverse Family of Resistors (Carbon, Metal Film, Wirewound, SMD, LDRs, Thermistors)
  - Key Parameters for Resistor Selection
  - Essential Resistor Applications (Voltage Dividers, LED Ballast, Digital Pull-Up/Pull-Down)
  - **Diagrams:** Fundamentals & Network Rules, 4-Band & 5-Band Color Guide, Essential Circuit Topologies

## 2. [Capacitors](Electronics/chapter_00002.md)
  - Fundamental Capacitor Physics ($Q = CV$, $C = \varepsilon_0 \varepsilon_r A / d$)
  - Electrostatic Stored Energy ($E = \frac{1}{2} C V^2$)
  - Current-Voltage Differential Law ($i = C \frac{dv}{dt}$)
  - Series and Parallel Equivalent Capacitance
  - Transient Response in RC Circuits and Time Constant ($\tau = RC$)
  - AC Circuit Dynamics and Capacitive Reactance ($X_C = \frac{1}{2\pi f C}$)
  - Essential Applications (Power Supply Reservoir Smoothing, IC High-Frequency Decoupling, AC Coupling)
  - Dielectric Technologies Comparison (Ceramic MLCC, Electrolytic, Tantalum, Film, Supercapacitors)
  - **Diagrams:** Capacitor Fundamentals & Physics, RC Transient Curves (0 to $5\tau$), Filtering & Decoupling Circuits

## 3. [Inductors](Electronics/chapter_00003.md)
  - Magnetic Flux Linkage, Faraday's Law, and Lenz's Back-EMF ($v = L \frac{di}{dt}$)
  - Solenoid Inductance Physics ($L = \frac{\mu N^2 A}{\ell}$)
  - Stored Magnetic Energy ($E = \frac{1}{2} L I^2$)
  - Series and Parallel Inductor Combinations
  - RL Step Response Dynamics ($\tau = L/R$) and Current Ramp
  - AC Steady-State Phase Dynamics ($V$ leads $I$ by $90^\circ$, $X_L = 2\pi f L$)
  - Magnetic Cores and Saturation Flux Density ($B_{sat}, I_{sat}$)
  - Essential Applications (Inductive Kickback Flyback Clamping, 2nd-Order LC Low-Pass Filters, SMPS Buck Power Stages)
  - **Diagrams:** Inductor Fundamentals & Solenoid Physics, RL Transient Ramp & AC Phase, Flyback & SMPS Topologies

## 4. [Diodes](Electronics/chapter_00004.md)
  - Semiconductor P-N Junction Physics and Depletion Layer Dynamics
  - Built-In Barrier Potential ($V_0 \approx 0.7\text{ V}$ for Silicon, $0.3\text{ V}$ for Germanium)
  - Forward Conduction vs Reverse Blocking States
  - Shockley Diode Equation and Dynamic Resistance ($r_d = 26\text{ mV} / I_D$)
  - Diode Circuit Models (Ideal, Constant Voltage Drop 0.7V, Piecewise Linear)
  - Full-Wave Bridge Rectification and Ripple Analysis
  - Zener Diode Voltage Regulation in Reverse Breakdown ($V_Z$)
  - Semiconductor Diode Technologies (Standard Silicon, Schottky Barrier, Fast Recovery, Zener, TVS)
  - **Diagrams:** P-N Junction & Biasing States, Diode I-V Curves & Models, Bridge Rectifier & Zener Regulator

## 5. [Light Emitting Diodes (LEDs)](Electronics/chapter_00005.md)
  - Direct Bandgap Electroluminescence Physics ($E_g = h\nu = hc/\lambda$)
  - Through-Hole LED Physical Anatomy and Polarity Identification (Anvil, Post, Flat Notch, Lead Lengths)
  - Forward Knee Voltage ($V_F$) Across the Optical Spectrum (IR, Red, Yellow, Green, Blue, White, UV)
  - Ballast Resistor Calculation ($R = \frac{V_{CC} - V_F}{I_F}$) and Power Ratings
  - Parallel String Current-Balancing Rules and Thermal Runaway Prevention
  - Microcontroller Transistor / MOSFET PWM Dimming
  - LED Packaging Standards (Through-Hole, SMD, High-Power COB, Addressable WS2812B)
  - **Diagrams:** LED Construction & Quantum Emission, Forward Voltage Spectrum & Curves, Driver Topologies

## 6. [Bipolar Junction Transistors (BJTs)](Electronics/chapter_00006.md)
  - NPN and PNP Semiconductor Sandwiches and Carrier Transport Physics
  - Thin Base Injection and Current Gain ($\beta = h_{FE}$, $\alpha$)
  - Fundamental Current Laws ($I_C = \beta I_B$, $I_E = I_C + I_B$, $V_{BE} \approx 0.7\text{ V}$)
  - Operating Regions (Cutoff, Active / Linear, Saturation, Reverse Active)
  - Common-Emitter Output Characteristics ($I_C$ vs $V_{CE}$), DC Load Line, and Q-Point Placement
  - Saturated BJT Switch Design with Forced-Beta Overdrive ($I_B \ge I_C / 10$)
  - Common-Emitter AC Voltage Amplifier with Stable Voltage Divider Biasing
  - Amplifier Configurations Comparison (Common Emitter, Common Collector / Emitter Follower, Common Base)
  - **Diagrams:** BJT Physical Structure & Schematic Symbols, Output Family & DC Load Line, Switch & Amplifier Circuits

## 7. [Junction Field-Effect Transistors (JFETs)](Electronics/chapter_00007.md)
  - Unipolar Voltage-Controlled Conduction Channel Physics (N-Channel vs P-Channel)
  - Reverse-Biased Gate Depletion and Channel Pinch-Off Phenomenon
  - Ultra-High Input Impedance ($R_{in} > 10^{10}\,\Omega$, $I_G < 1\text{ nA}$)
  - Shockley's JFET Parabolic Transfer Equation ($I_D = I_{DSS}(1 - V_{GS}/V_P)^2$)
  - Transconductance Gain ($g_m = dI_D / dV_{GS}$)
  - Drain Characteristics ($I_D$ vs $V_{DS}$): Ohmic/Linear VCR Region vs Saturation Plateaus
  - Practical Topologies: Self-Biased Common-Source Preamplifier, 2-Terminal Constant Current Source ($I_{DSS}$)
  - JFET vs BJT Comprehensive Architectural Comparison
  - **Diagrams:** JFET Structure & Depletion Control, Transfer & Drain Characteristics, Self-Biased & CCS Circuits

## 8. [Metal-Oxide-Semiconductor Field-Effect Transistors (MOSFETs)](Electronics/chapter_00008.md)
  - MOS Gate Structure and $\text{SiO}_2$ Dielectric Isolation ($R_{in} > 10^{12}\,\Omega$)
  - Physical Inversion Layer Formation and Threshold Voltage ($V_{th}$)
  - Enhancement Mode (Normally OFF) vs Depletion Mode (Normally ON)
  - Parasitic Intrinsic Body Diode Physics
  - Operating Regions & Equations: Cutoff, Triode / Linear ($R_{DS(on)}$), and Saturation
  - Power NMOS Low-Side Switch Design (Gate Pull-Down, Series Damping, Switching Losses)
  - CMOS Inverter Architecture and Zero-Static Power Operation
  - Bidirectional I2C Level Shifter ($3.3\text{ V} \leftrightarrow 5\text{ V}$)
  - **Diagrams:** MOSFET Structure & Gate Inversion, I-V Characteristic Planes, Power Switch & CMOS Circuits

## 9. [Crystals](Electronics/chapter_00009.md)
  - Quartz Crystal Lattice and Direct vs Inverse Piezoelectric Transduction
  - Resonator Cuts: AT-Cut (Thickness-Shear, $35^\circ 15'$, Zero-Drift at $25^\circ\text{C}$) and Tuning Fork ($32.768\text{ kHz} = 2^{15}\text{ Hz}$)
  - Butterworth-Van Dyke (BVD) Equivalent Electrical Circuit Model ($R_m, L_m, C_m, C_0$)
  - Series Resonance ($f_s$) vs Parallel Anti-Resonance ($f_p$)
  - Quality Factor ($Q = 10,000\text{--}500,000$) and Reactance Frequency Curves
  - Standard Pierce Crystal Oscillator Circuit Design (CMOS Inverter, $R_f, R_s, \pi$-Network)
  - Load Capacitance Matching Formula ($C_L = \frac{C_1 C_2}{C_1 + C_2} + C_{stray}$) and Frequency Pulling
  - Clock Technology Comparison (Tuning Fork, AT-Cut Quartz, TCXO, OCXO, MEMS, Internal RC)
  - **Diagrams:** Piezoelectric Physics & AT-Cut Geometry, BVD Equivalent & Reactance Curves, Pierce Oscillator Architecture

##### Copyright (c) 2026 squared-studio
