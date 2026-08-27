# Troubleshooting Log — ECG Monitor Project

A record of every real problem hit while building this, and how each was solved.
Keeping this partly because future-me will hit some of these again on the next project.

---

## Hardware identification

**Problem:** Assumed I had a PICkit programmer, but it turned out to be a Digilent
chipKIT PGM — a different device with a key limitation: it can only program
3.3V-programmable devices, unlike a real PICkit3/4 which can generate the higher
programming voltages needed for older/other PIC parts.

**Fix:** Picked a target chip (PIC24FJ64GA002) that's natively 3.3V and
3.3V-programmable, so it works fine with the chipKIT PGM. No new hardware needed.

---

## AD8232 power/logic level

**Problem:** My AD8232 breakout only exposes 3 pins (5V-in, GND, OUTPUT) — a
simpler variant than the 9-pin version with LO+/LO-/SDN. Powering it at 5V risked
feeding a >3.3V signal into the PIC's ADC pin, which only tolerates 0–3.3V.

**Fix:** Powered the module from the 3.3V rail instead of 5V. Measured the OUTPUT
pin with a multimeter (~3.2V max) to confirm it was safely within the PIC's ADC
range before ever connecting it.

---

## Wrong register names (PIC24FJ64GA002-specific)

**Problem:** Build failed with `'AD1CHS0bits' undeclared` and `'RPOR9bits' undeclared`.

**Cause:** These register names vary across PIC24 variants. This specific chip uses:
- `AD1CHS` (not `AD1CHS0` — no channel-bank suffix on this simpler ADC module)
- `RPOR4bits.RP9R` (not `RPOR9bits` — RP9 lives in a *paired* register on this chip,
  not an individual per-pin register)

**Fix:** Changed both to match this chip's actual header file.

---

## `__delay_ms()` / `__delay_us()` undefined reference

**Problem:** Compiled fine, but linking failed with `undefined reference to '__delay_ms'`.

**Cause:** `FCY` (instruction cycle rate) was `#define`d *after* `#include <libpic30.h>`.
The delay macros need `FCY` defined before that include, or they fall back to
expecting real functions that don't exist anywhere.

**Fix:** Moved `#define FCY 4000000UL` above all the includes.

---

## MPLAB 8: assembler instead of C compiler

**Problem:** Build failed with `pic30-coff-as.exe: unrecognized option '-mcpu=24FJ64GA002'`.

**Cause:** The project had been created from an Assembly project template, so MPLAB
was routing `main.c` through the assembler (`pic30-as.exe`) instead of the C
compiler (`pic30-gcc.exe`).

**Fix:** Recreated the project as a Standalone Project with **Microchip C30
Toolsuite** selected specifically (not ASM30).

---

## chipKIT PGM never detected by Windows (ASUS X515)

**Problem:** chipKIT PGM plugged in, LED lit, USB chime played — but never showed
up anywhere in Device Manager. Ruled out: bad cable (tried multiple), bad USB port,
missing driver, hidden/ghost devices.

**Status:** Never solved on this specific laptop. Worked around it by using a
second laptop with **MPLAB v8.80 + the C30 toolchain** instead, where the chipKIT
PGM (shown there as "Licensed Debugger") was detected and worked immediately.

---

## CP2102 — "Access is denied" (Error 5) on COM3

**Problem:** CP2102 showed up correctly in Device Manager as COM3, but nothing —
not MATLAB, not PuTTY — could actually open the port. Got a hard "Access is
denied" error every time, even after a full laptop restart.

**What didn't fix it:** clearing MATLAB serial objects, restarting MATLAB,
restarting the whole laptop, running as Administrator, checking for third-party
antivirus (none installed).

**Fix:** Got around it by downloading a separate driver — the CP210x VCP
Windows Driver.

---

## ADC conflict: auto-convert vs. manual sampling

**Problem:** ADC readings were unreliable/hung intermittently.

**Cause:** `AD1CON1bits.SSRC` was set to `7` (auto-convert mode), but the code in
`ReadADC()` was manually toggling the `SAMP` bit to control sampling — the two
approaches fight each other. In auto-convert mode, manually clearing `SAMP` is
ignored by the hardware.

**Fix:** Changed `SSRC` to `0` (manual mode), matching the manual `SAMP`
toggling already in the code.

---

## UART transmitter enabled before the UART module itself

**Problem:** Potential transmit lockup on some silicon.

**Cause:** `U1STAbits.UTXEN = 1` (enable transmitter) was set *before*
`U1MODEbits.UARTEN = 1` (enable the UART module as a whole).

**Fix:** Flipped the order — enable the module first, then the transmitter.

---

## Firmware/MATLAB sample rate mismatch

**Problem:** Live plot scrolled far slower than expected — a "5 second window"
was actually taking well over 10 seconds to fill.

**Cause:** Firmware was sampling at ~100 Hz (`__delay_ms(10)`), but the MATLAB
script assumed 250 Hz for its window-size calculation.

**Fix:** Matched both sides — changed firmware to `__delay_ms(4)` (~250 Hz) and
confirmed `SAMPLE_RATE_HZ = 250` in MATLAB.

---

## Live plot froze after ~2000 samples

**Problem:** The scrolling waveform would just stop updating after a while,
looking like a crash.

**Cause:** A periodic `cleanpoints(h)` call (meant to prevent memory buildup)
wiped ALL historical points from the `animatedline` object, but the x-axis kept
scrolling forward based on total sample count — so the visible window ended up
empty.

**Fix:** Rewrote the plot as a fixed-size wrap-around buffer (like a real
hospital monitor's sweeping display) instead of an ever-growing `animatedline` —
no cleanup calls needed, runs indefinitely.

---

## Git not in PATH (happened twice, two different laptops)

**Problem:** `git : The term 'git' is not recognized...` even after confirming
Git was installed.

**Cause:** The installer's PATH step either got skipped or defaulted to
"Git Bash only" instead of making `git` available system-wide.

**Fix:** Re-ran the Git for Windows installer, explicitly selected **"Git from
the command line and also from 3rd-party software"** on the PATH screen, then
fully closed and reopened the terminal (PATH changes don't apply to
already-open terminal windows).

---

## MPLAB 8 build failing with no error text at all

**Problem:** Build failed instantly (same-second start/fail timestamps), with
zero compiler error text ever appearing in the Output window — across multiple
different project/file setups.

**Cause:** Windows Security had the toolchain app blocked/quarantined, so the
compiler was never actually running — MPLAB 8's IDE doesn't clearly surface
this as a security block, it just shows a generic build failure with no
detail.

**Fix:** Allowed the app through Windows Security. (Running the exact compiler
command directly in Command Prompt, copied from the IDE's log, is a good way
to confirm whether a "silent" build failure is a real compiler error or the
IDE swallowing output — worth doing early next time this happens.)

---

## Noisy ECG signal — mains interference from the laptop charger

**Problem:** Live waveform showed a thick, fuzzy high-frequency noise band
riding on top of the real signal, on top of a few large motion-artifact-style
spikes. Electrodes were suspected first (they were old).

**Cause:** The laptop was plugged into its charger during recording. With a
simple 3-pin AD8232 module (no right-leg-drive circuit to actively cancel
common-mode noise), the circuit was picking up 60Hz mains interference,
likely via a ground loop through the USB connection.

**Fix:** Unplugged the laptop charger and ran on battery power only during
recording. Dramatically cleaned up the waveform — clear, well-defined QRS
complexes visible afterward. Electrode age turned out not to be the main
issue.
