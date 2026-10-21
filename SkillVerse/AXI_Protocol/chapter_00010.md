# AXI4-Lite, Bridging, and Interconnect Architecture

### Learning Objectives

- Master the **AXI4-Lite** protocol subset: its restrictions, simplified signaling, and register-map use cases.
- Compare the architectural tradeoffs between Full AXI4, AXI4-Lite, and APB4.
- Analyze the internal structure of multi-master, multi-slave **AXI Crossbar Interconnects**.
- Understand data width conversion: **Upsizing** (narrow master to wide slave) and **Downsizing** (wide master to narrow slave).
- Explore Clock Domain Crossing (CDC) asynchronous bridges and protocol converters (AXI-to-AXI4-Lite and AXI-to-APB).

---

## The AXI4-Lite Protocol Profile

While Full AXI4 provides immense throughput, its full feature set (bursting up to 256 beats, out-of-order IDs, cache attributes, wrapping bursts) requires significant silicon area. For simple memory-mapped control and status registers (CSRs), this complexity is unnecessary.

**AXI4-Lite** is a formal, lightweight subset of AXI4 tailored specifically for register access interfaces:

![AXI4-Lite Comparison](images/ch10_axi4_lite_comparison.svg)

### Key Rules and Restrictions of AXI4-Lite:

1. **Fixed Burst Length of 1 Beat:** All transactions consist of exactly one transfer (`AxLEN` is omitted; implicitly 0).
2. **Fixed Data Width:** The data bus width must be strictly **32 bits or 64 bits** (`AxSIZE` is omitted).
3. **No Out-of-Order Execution:** Transaction ID signals (`AWID`, `BID`, `ARID`, `RID`) are **omitted**. All transactions are strictly in-order.
4. **No Cache or Protection Filtering:** `AxCACHE` is omitted (all accesses are unbuffered and non-cacheable). `AxPROT` is retained for privilege/security checks.
5. **No Burst Types:** `AxBURST` is omitted (all transactions behave as single-beat `INCR`).
6. **No Exclusive Accesses:** `AxLOCK` is omitted.
7. **No WLAST / RLAST:** Because burst length is always 1, `WLAST` and `RLAST` are omitted (implicitly asserted on every beat).

---

## Architectural Comparison: Full AXI4 vs. AXI4-Lite vs. APB4

When designing peripheral subsystems in an SoC, architects select bus interfaces based on bandwidth, latency, and area:

| Protocol Attribute         | Full AXI4                         | AXI4-Lite                                | APB4                                      |
| -------------------------- | --------------------------------- | ---------------------------------------- | ----------------------------------------- |
| **Primary Target**         | DDR memory, DMA, GPUs, NPUs, PCIe | Memory-mapped IP registers, config ports | Low-power peripherals (UART, I2C, Timers) |
| **Burst Length**           | 1 to 256 beats                    | **Strictly 1 beat**                      | **None (1 transfer per 2+ cycles)**       |
| **Data Bus Width**         | 32 to 1024 bits                   | 32 or 64 bits                            | 32 bits typical                           |
| **Channels**               | 5 independent channels            | 5 independent channels                   | 1 shared multiplexed bus                  |
| **Out-of-Order Execution** | Yes (via ID tags)                 | No (strictly in-order)                   | No (half-duplex lockstep)                 |
| **Pipelining**             | Yes (multiple outstanding)        | Yes (address/data decoupled)             | No (requires Setup then Access phase)     |
| **Silicon Gate Count**     | High (~10k-50k gates/port)        | Low (~2k-5k gates/port)                  | Ultra-low (~500 gates/port)               |
| **Register Slicing**       | Straightforward on any channel    | Straightforward on any channel           | Difficult (timing tight on setup/enable)  |

---

## Multi-Master, Multi-Slave Crossbar Interconnects

In a complete SoC, multiple masters (e.g., Dual-Core CPU, GPU, 2x DMA engines) must communicate concurrently with multiple slaves (e.g., DDR Controller, On-Chip SRAM, PCIe Bridge, Peripheral Bridge).

The **AXI Crossbar Interconnect** is the switching fabric that arbitrates and routes these transactions:

![AXI Crossbar Interconnect](images/ch10_crossbar_interconnect.svg)

### Internal Modules of an AXI Crossbar:

1. **Address Decoders:** Inspect `AWADDR` and `ARADDR` from each master port against the system memory map to determine the target slave port.
2. **Channel Arbiters:** Resolve multi-master contention when several masters request the same slave simultaneously (using Round-Robin, Fixed Priority, or `AxQOS` weighting).
3. **M-to-S and S-to-M Multiplexers:** Establish high-speed non-blocking crossbar routing matrix. Uncontested routes execute concurrently in parallel (e.g., CPU accessing DDR while DMA accesses SRAM).
4. **Reorder and ID Widening Buffers:** Prepend master port indices to ID tags and ensure intra-ID ordering rules are strictly maintained.

---

## Data Width Conversion: Upsizing and Downsizing

In heterogenous SoCs, different blocks operate with different native data bus widths. For example, a 64-bit CPU master frequently communicates with a 256-bit DDR memory controller or a 32-bit peripheral bus.

The interconnect handles these discrepancies transparently through **Width Converters**:

![AXI Upsizing and Downsizing](images/ch10_upsizing_downsizing.svg)

### Upsizing (Narrow Master to Wide Slave)

- **Scenario:** A 64-bit Master writes to a 256-bit Slave.
- **Mechanism:** The upsizer packs four 64-bit master beats into a single 256-bit slave beat.
- **Byte Strobes:** The upsizer shifts and positions the master's 8-bit `WSTRB` into the appropriate 32-bit lane of the slave's `WSTRB` bus.
- **Burst Length:** The upsizer calculates a reduced `AWLEN` for the wide slave:
  $$\text{Slave\_LEN} = \left\lceil \frac{\text{Master\_LEN} + 1}{\text{Width\_Ratio}} \right\rceil - 1$$

### Downsizing (Wide Master to Narrow Slave)

- **Scenario:** A 256-bit Master writes to a 64-bit Slave.
- **Mechanism:** The downsizer unpacks each 256-bit master beat into four sequential 64-bit slave beats.
- **Burst Splitting:** The downsizer generates multiple sub-bursts, incrementing the address appropriately.
- **4KB Check:** The downsizer must verify that expanded burst lengths do not violate the 4KB boundary rule.

---

## Clock Domain Crossing (CDC) and Asynchronous Bridges

SoC IP blocks routinely run on distinct, asynchronous clock frequencies:

- CPU cores may operate at 2.0 GHz.
- The AXI system interconnect may operate at 800 MHz.
- High-bandwidth DDR controllers may operate at 1.2 GHz.
- Peripheral buses (APB) may operate at 100 MHz.

### Asynchronous AXI Bridges:

To bridge these domains safely without metastability:

- **Dual-Clock Asynchronous FIFOs:** Placed on all five channels. Address and data payloads are written using the master clock (`M_ACLK`) and read using the slave clock (`S_ACLK`).
- **Gray-Code Pointer Synchronization:** FIFO read and write pointers are synchronized across the clock boundary using 2-stage or 3-stage flip-flop synchronizers.
- **Register Slices (Skid Buffers):** Decouple `READY` backpressure combinatorial paths from the FIFO control logic, enabling maximum operational frequency.

---

## Protocol Bridges: AXI-to-AXI4-Lite and AXI-to-APB

### AXI4 to AXI4-Lite Converter:

When a full AXI4 master targets an AXI4-Lite peripheral:

- If the master issues a multi-beat burst (`AxLEN > 0`), the converter **splits the burst into multiple independent single-beat transactions**.
- The converter accumulates all split responses and returns a single combined response (`BRESP` or `RRESP`) back to the full AXI4 master.

### AXI4 to APB Bridge:

When an AXI master targets low-speed control registers on an APB bus:

1. The bridge accepts the AXI address and write data handshakes.
2. The bridge translates the transaction into APB's two-phase cycle (**SETUP Phase** $\rightarrow$ **ENABLE Phase**).
3. The bridge holds `WREADY` or `ARREADY` LOW if its internal APB request queue is full.
4. When the APB slave asserts `PREADY`, the bridge samples `PRDATA` and `PSLVERR`, translating `PSLVERR = 1` into `SLVERR` (`2'b10`) on the AXI `B` or `R` channel.

---

## Chapter Summary

- **AXI4-Lite** provides a lean, low-area subset of AXI4: strictly 1-beat bursts, 32/64-bit bus widths, and no IDs or cache attributes.
- **Full AXI4** is used for maximum memory bandwidth; **AXI4-Lite** is used for internal IP control registers; **APB4** is used for simple, low-power system peripherals.
- **AXI Crossbars** combine address decoding, dynamic arbiters, non-blocking multiplexers, and ID widening to support concurrent multi-master multi-slave traffic.
- **Upsizing** packs multiple narrow beats into one wide beat; **Downsizing** expands one wide beat into multiple narrow sequential beats.
- **Asynchronous CDC Bridges** use dual-clock Gray-code FIFOs to cross clock domains seamlessly between CPU, crossbar, and DDR controllers.

---

## Review Questions

### Question 1

List four signals present in the full AXI4 specification that are omitted from AXI4-Lite.

<details>
<summary><b>View Answer</b></summary>
Any four of the following:
1. `AxLEN` (burst length is fixed to 1 beat).
2. `AxSIZE` (data width is fixed to 32-bit or 64-bit).
3. `AxBURST` (burst type is omitted; behaves as INCR).
4. `AWID`, `BID`, `ARID`, `RID` (transaction IDs omitted; no out-of-order execution).
5. `WLAST`, `RLAST` (last flags omitted; implicitly 1).
6. `AxCACHE` (caching attributes omitted; unbuffered/non-cacheable).
7. `AxLOCK` (exclusive accesses omitted).
</details>

### Question 2

What is the function of an AXI downsizer when a 256-bit DMA engine writes a 4-beat burst to a 64-bit on-chip peripheral buffer?

<details>
<summary><b>View Answer</b></summary>
The downsizer converts the 256-bit wide burst into a 64-bit narrow burst. Because the width ratio is $256 / 64 = 4$, each 256-bit beat from the master is unpacked and serialized into four sequential 64-bit beats on the peripheral interface. A 4-beat master burst is thus converted into a 16-beat slave burst, with the downsizer automatically updating addresses and routing byte strobes.
</details>

### Question 3

How does an AXI-to-APB bridge map the APB slave error signal `PSLVERR` into the AXI protocol?

<details>
<summary><b>View Answer</b></summary>
When an APB slave asserts `PSLVERR = 1` during the `ENABLE` phase with `PREADY = 1`, the bridge maps this error status directly to `SLVERR` (`2'b10`). For a write transaction, the bridge returns `BRESP = 2'b10` on the B channel. For a read transaction, the bridge returns `RRESP = 2'b10` on the R channel alongside `PRDATA`.
</details>

### Question 4

Why is asynchronous FIFO pointer synchronization implemented using Gray code rather than standard binary counters in AXI CDC bridges?

<details>
<summary><b>View Answer</b></summary>
In a binary counter, multiple bits can change simultaneously (e.g., from `0111` to `1000`, all 4 bits toggle). If the receiving clock domain samples during this transition, clock skew can cause some bits to be sampled early and others late, creating transient invalid pointer values (metastability and pointer corruption). Gray code guarantees that exactly **one bit changes at every counter increment**, completely eliminating multi-bit transition race conditions across the synchronizer flip-flops.
</details>

---

##### Copyright (c) 2026 squared-studio
