# Parameterized Synchronous FIFO – SystemVerilog Verification

## Project Overview

Designed and implemented a parameterized synchronous FIFO (First-In First-Out) using SystemVerilog and developed a verification environment to validate its functionality.

The project focuses on RTL design, simulation, constrained-random verification, assertions, functional coverage, and waveform analysis.

## Design Specifications

| Parameter | Value |
|---|---|
| FIFO Type | Synchronous FIFO |
| Data Width | 8 bits |
| FIFO Depth | 16 entries |
| Clock | Single clock |
| Reset | Synchronous, active-high |
| Read/Write | Independent read and write enables |

## Architecture

The FIFO uses:
- Memory array for data storage.
- Write pointer to track the next write location.
- Read pointer to track the next read location.
- Occupancy counter to track the number of stored entries.
- Full and empty status flags.

## Verification Methodology

Developed a SystemVerilog testbench incorporating:

- Directed testing for basic read and write operations.
- FIFO overflow and underflow checks.
- Simultaneous read and write operations.
- Pointer wraparound verification.
- Scoreboard-based data integrity checking.
- SystemVerilog Assertions (SVA).
- Functional coverage.
- Constrained-random transaction generation.

## Tools Used

- SystemVerilog
- QuestaSim 2025.2
- EDA Playground
- EPWave

## Simulation Results

The design was simulated and verified using directed and constrained-random test scenarios.

Waveforms were analysed to verify:
- Correct FIFO data ordering.
- Pointer increment and wraparound.
- Occupancy counter behaviour.
- Full and empty flag transitions.
- Correct read and write operations.

## Project Files

- `design.sv` – FIFO RTL implementation.
- `testbench.sv` – SystemVerilog verification environment.
- `waveforms/` – Simulation waveform screenshots.

## Key Learning Outcomes

- RTL design using SystemVerilog.
- FIFO architecture and pointer management.
- Testbench development.
- Scoreboard-based verification.
- Assertions and functional coverage.
- Constrained-random verification.
- Simulation debugging and waveform analysis.
