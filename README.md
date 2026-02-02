# 3×3 Convolution Engine Accelerator

A hardware accelerator for 3×3 convolution operations, designed for integration with microcontroller DMA in 32-bit mode.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        MICROCONTROLLER                              │
│                    (DMA 32-bit transfers)                           │
└───────────────────────────┬─────────────────────────────────────────┘
                            │ DMAport[31:0]
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                         ConvEngine                                  │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    MUX (1:6 Demux)                             │ │
│  │         Select[2:0] routes data to 1 of 6 registers            │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │                                        │
│       ┌────────────────────┼────────────────────┐                   │
│       ▼                    ▼                    ▼                   │
│  ┌─────────┐          ┌─────────┐          ┌─────────┐              │
│  │  Reg0   │          │  Reg1   │          │  Reg2   │  ← Pixels    │
│  │ P0,P1,P2│          │ P3,P4,P5│          │ P6,P7,P8│              │
│  └─────────┘          └─────────┘          └─────────┘              │
│  ┌─────────┐          ┌─────────┐          ┌─────────┐              │
│  │  Reg3   │          │  Reg4   │          │  Reg5   │  ← Kernels   │
│  │ K0,K1,K2│          │ K3,K4,K5│          │ K6,K7,K8│              │
│  └─────────┘          └─────────┘          └─────────┘              │
│       │                    │                    │                   │
│       └────────────────────┼────────────────────┘                   │
│                            ▼                                        │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │           9× Wallace Tree Multipliers (int8 × int8)            │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │ 9× 16-bit products                     │
│                            ▼                                        │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                    Adder Tree (Sum of 9)                       │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │                                        │
│                            ▼                                        │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │                   32-bit Accumulator                           │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                            │                                        │
└────────────────────────────┼────────────────────────────────────────┘
                             ▼
                      result[31:0]
```

## Files

| File | Description |
|------|-------------|
| `ConvEngine.v` | Top module integrating all components |
| `MUX.v` | 1:6 demultiplexer for DMA data routing |
| `Register.v` | 24-bit register with enable |
| `Wallace.v` | Baugh-Wooley Wallace tree multiplier for signed int8 |
| `ConvEngine_tb.v` | Testbench for verification |

## Specifications

| Parameter | Value |
|-----------|-------|
| Input data type | Signed int8 (-128 to 127) |
| Kernel size | 3×3 (9 weights) |
| Multiplier | Baugh-Wooley Wallace Tree |
| Product width | 16-bit signed |
| Accumulator | 32-bit signed |
| DMA transfers per convolution | 6 (3 pixel + 3 kernel) |
| Datapath | Fully combinational (1 cycle MAC) |

## DMA Word Format (32-bit)

```
┌────────────────────┬────────┬────────┬──────────┐
│    [31:8]          │  [7]   │ [6:3]  │  [2:0]   │
├────────────────────┼────────┼────────┼──────────┤
│  24-bit Data       │ Enable │ Unused │ Select   │
│  (3 × int8 bytes)  │  bit   │ (4b)   │ (3 bits) │
└────────────────────┴────────┴────────┴──────────┘
```

### Select Line Mapping

| Select | Register | Contents |
|--------|----------|----------|
| `000` | Reg0 | pixel[0], pixel[1], pixel[2] |
| `001` | Reg1 | pixel[3], pixel[4], pixel[5] |
| `010` | Reg2 | pixel[6], pixel[7], pixel[8] |
| `011` | Reg3 | kernel[0], kernel[1], kernel[2] |
| `100` | Reg4 | kernel[3], kernel[4], kernel[5] |
| `101` | Reg5 | kernel[6], kernel[7], kernel[8] |

## Top Module Interface

```verilog
module ConvEngine (
    input         clk,        // Clock
    input         rst,        // Async reset
    input  [31:0] DMAport,    // 32-bit DMA input
    input         acc_enable, // Accumulator enable
    input         acc_clear,  // Clear accumulator
    output [31:0] result      // 32-bit convolution result
);
```

## Operation Sequence

### 1. Load Kernel (once per filter)
```
DMA Write: {K0,K1,K2, 1'b1, 4'b0, 3'b011}  → Reg3
DMA Write: {K3,K4,K5, 1'b1, 4'b0, 3'b100}  → Reg4
DMA Write: {K6,K7,K8, 1'b1, 4'b0, 3'b101}  → Reg5
```

### 2. For Each Pixel Window
```
DMA Write: {P0,P1,P2, 1'b1, 4'b0, 3'b000}  → Reg0
DMA Write: {P3,P4,P5, 1'b1, 4'b0, 3'b001}  → Reg1
DMA Write: {P6,P7,P8, 1'b1, 4'b0, 3'b010}  → Reg2

Assert acc_clear  (1 cycle)  // Clear accumulator
Assert acc_enable (1 cycle)  // Compute and accumulate
Read result                  // Get output pixel
```

## Pixel/Kernel Layout

The 3×3 window maps indices as follows:

```
┌─────┬─────┬─────┐
│  0  │  1  │  2  │
├─────┼─────┼─────┤
│  3  │  4  │  5  │
├─────┼─────┼─────┤
│  6  │  7  │  8  │
└─────┴─────┴─────┘
```

## Simulation

Run with Icarus Verilog:

```bash
iverilog -o conv_tb ConvEngine_tb.v ConvEngine.v MUX.v Register.v Wallace.v
vvp conv_tb
```

### Expected Output

```
========================================
  ConvEngine Testbench
========================================

--- Test 1: Identity kernel at center ---
PASS: Result = 10 (expected 10)

--- Test 2: All ones kernel ---
PASS: Result = 45 (expected 45)

--- Test 3: Signed multiplication ---
PASS: Result = 9 (expected 9)

--- Test 4: Mixed signed values ---
PASS: Result = -1143 (expected -1143)

--- Test 5: Accumulation test ---
PASS: Result = 180 (expected 180)

--- Test 6: Edge detection kernel (Sobel-like) ---
PASS: Result = 0 (expected 0)

========================================
  Testbench Complete
========================================
```

## Test Cases

The testbench includes:

1. **Identity kernel** - Center weight only
2. **All ones kernel** - Sum of all pixels
3. **Signed multiplication** - (-1) × (-1) = 1
4. **Mixed signs** - 127 × (-1)
5. **Accumulation** - Multiple MAC operations
6. **Edge detection** - Sobel-like kernel

## License

MIT License
