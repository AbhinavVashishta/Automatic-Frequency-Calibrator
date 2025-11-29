# Fast Automatic Frequency Calibration (AFC) for PLL-Based Frequency Synthesizers

A Verilog implementation of a binary search-based automatic frequency calibration scheme for Phase-Locked Loop (PLL) frequency synthesizers with digitally-controlled VCOs.

## Overview

Modern PLL-based frequency synthesizers use VCOs with small gain (K_VCO) for low phase noise, making it difficult to cover the required frequency locking range. This is typically solved using switchable capacitor banks that provide digital frequency control. Before normal PLL operation can begin, the optimal frequency control code must be determined through an Automatic Frequency Calibration (AFC) process.

This project implements a fast, counter-based AFC scheme that uses binary search to quickly converge on the correct frequency control code.

## Design Approach

### Binary Search Algorithm

The AFC uses a binary search strategy to minimize calibration time:

1. **Initialize**: Start with the midpoint of the control code range (typically 127 for 8-bit codes)
2. **Compare**: Count rising edges of both the reference clock and divided VCO clock
3. **Decide**: If reference clock count exceeds divided clock count, the VCO is too slow (increase code). If divided clock count exceeds reference, the VCO is too fast (decrease code)
4. **Update**: Adjust the search boundaries and move to the new midpoint
5. **Settle**: Wait for the VCO frequency to stabilize before the next measurement
6. **Repeat**: Continue until frequencies match within threshold or boundaries converge

This approach achieves O(log N) convergence, requiring only 8 iterations maximum for an 8-bit control code space.

### Key Features

- **Fast Convergence**: Binary search reduces calibration time compared to linear search methods
- **Robust Comparison**: Waits for minimum sample count before making frequency decisions
- **Stability Detection**: Requires multiple consecutive equal measurements to declare lock
- **Proper Settling**: Allows VCO frequency to stabilize after each control code update
- **Clock Domain Crossing**: Two-stage synchronizer handles asynchronous clock domains safely

## Implementation Details

### Frequency Detection Method

The design uses a counter-based approach that is immune to mismatch and process variations:

- Two counters track rising edges of the reference clock and divided VCO clock
- Comparison happens when sufficient samples have accumulated (MIN_SAMPLES = 50)
- A threshold (THRESHOLD = 2) determines when frequencies are considered equal
- Stability counter requires 4 consecutive equal measurements to confirm lock

### Control Flow

```
IDLE → SETTLE → RUN → [RUN or SETTLE loop] → FINISH
```

- **IDLE**: Waiting for AFC trigger
- **SETTLE**: Allow VCO frequency to stabilize (100 clock cycles)
- **RUN**: Compare frequencies and update control code
- **FINISH**: Lock achieved, maintain current code

### Design Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| CODE_WIDTH | 8 | Control code width (8 bits = 256 codes) |
| COUNT_WIDTH | 16 | Counter width for frequency measurement |
| THRESHOLD | 2 | Count difference threshold for equal detection |
| MIN_SAMPLES | 50 | Minimum samples before comparison |
| SETTLE_CYCLES | 100 | Cycles to wait for VCO settling |

## Simulation

The testbench (`tb_dual_refclk.v`) simulates a complete AFC cycle:

- **Reference Clock**: 100 MHz
- **VCO Range**: 50 MHz to 300 MHz  
- **Starting Frequency**: 200 MHz (far from target to stress-test the algorithm)
- **Target**: Lock to 100 MHz (matching reference)

The simulation includes detailed cycle-by-cycle monitoring of the first 60 clock cycles for debugging, followed by automatic verification of lock time and final frequency accuracy.

### Running the Simulation

```bash
# Compile with Icarus Verilog
iverilog -g2012 -o afc_sim \
    rtl/diff_compare.v \
    rtl/binary_search_controller.v \
    rtl/refclk_generator.v \
    rtl/afc_top.v \
    tb/tb_dual_refclk.v

# Run simulation
vvp afc_sim

# View waveforms
gtkwave tb_dual_refclk.vcd
```

Expected output shows lock achieved in microseconds with frequency error well under 1%.

## References

This implementation is based on the IEEE paper:

**"A Fast Automatic Frequency Calibration (AFC) Scheme for Phase-Locked Loop (PLL) Frequency Synthesizer"**  
Chan-Young Jeong, Dong-Ho Choi, and Changsik Yoo  
IEEE Radio Frequency Integrated Circuits Symposium, 2009

The paper demonstrates AFC completion in less than 1.6μs with only 0.01mm² silicon area in 0.18μm CMOS.

## License

MIT License - See LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.
