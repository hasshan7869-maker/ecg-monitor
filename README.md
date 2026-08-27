# Real-Time ECG Monitor — PIC24FJ64GA002 + MATLAB

A single-lead ECG monitor: electrodes → analog front-end → PIC24 microcontroller
→ live scrolling waveform in MATLAB with real-time BPM detection, hospital-monitor
style. Also includes a custom PCB layout (KiCad) for the full circuit.


![image alt](https://github.com/hasshan7869-maker/ecg-monitor/blob/248d5862b38528553bc88ccba0183d2b40fbb9bb/Media/Screenshot%202026-08-23%20115538.png)
![image alt](https://github.com/hasshan7869-maker/ecg-monitor/blob/248d5862b38528553bc88ccba0183d2b40fbb9bb/Media/20260823_122118.jpg)

## Schematic + PCB Layouts
![image alt](https://github.com/hasshan7869-maker/ecg-monitor/blob/6c84f99e352572562690b4e1d51c772517148115/Media/Screenshot%202026-08-27%20190401.png)
![image alt](https://github.com/hasshan7869-maker/ecg-monitor/blob/6c84f99e352572562690b4e1d51c772517148115/Media/Screenshot%202026-08-27%20190401.png)
![image alt](https://github.com/hasshan7869-maker/ecg-monitor/blob/6c84f99e352572562690b4e1d51c772517148115/Media/Screenshot%202026-08-27%20192725.png)


![image alt](https://github.com/hasshan7869-maker/ecg-monitor/blob/6c84f99e352572562690b4e1d51c772517148115/Media/ECGplusBPM.webp)
ECG + BPM using cheaper electrodes

## Signal Path

```
Electrodes → AD8232 (analog front-end) → PIC24FJ64GA002 (ADC + UART)
           → CP2102 (USB-to-serial) → MATLAB (live plot)
```

## Hardware

- **PIC24FJ64GA002** — samples the signal, transmits over UART
- **AD8232** breakout — analog front-end / amplification
- **Digilent chipKIT PGM** — ICSP programmer
- **CP2102** — USB-to-TTL bridge to the PC
- 3x Ag/AgCl electrodes, breadboard, jumper wires

## Software

- **MPLAB v8.80** + **MPLAB C30** compiler (legacy toolchain, for chipKIT PGM
  compatibility)
- **MATLAB** (R2019b+, uses `serialport`)

## Getting Started

**1. Flash the firmware**
Open `main.c` in MPLAB v8.80 as a Standalone Project (device:
PIC24FJ64GA002, toolsuite: Microchip C30). Set Configuration Bits
(Oscillator = FRC, Watchdog = Disabled, JTAG = Disabled), build, and program
via the chipKIT PGM.

**2. Run the live plot**
Wire the CP2102 (RXD → PIC TX pin, GND → GND), note its COM port in Device
Manager, update `COM_PORT` in `ecg_live_plot.m`, and run it in MATLAB.

## Repository Structure

```
├── main.c                # PIC24 firmware
├── ecg_live_plot.m       # MATLAB live plot script
├── images/
├── TROUBLESHOOTING.md    # Every build issue hit, and how it was fixed
└── README.md
```

## Limitations

Single-lead only, no leads-off detection, built for educational/portfolio
purposes — not a medical device. Signal quality is sensitive to interference
from nearby AC power sources (e.g. a laptop charger) — best results running
on battery power only.

## Completed / Roadmap

- [x] Custom PCB layout (KiCad)
- [x] Real-time BPM via QRS/peak detection in MATLAB
- [ ] Manufacture and populate the PCB
- [ ] Digital filtering (baseline drift, 50/60Hz notch)

---

Built by Hassan Hanif as a personal biomedical engineering project.
See [`TROUBLESHOOTING.md`](TROUBLESHOOTING.md) for the full debugging log.
