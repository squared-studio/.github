# Introduction to AMBA AXI Protocol and Architecture

### Learning Objectives

- Understand the role of the Advanced eXtensible Interface (AXI) in modern high-performance System-on-Chip (SoC) platforms.
- Define and distinguish foundational AXI terminologies: bit, byte, byte lane, word, handshake, wait state, transfer, beat, burst, transaction, channel, phase, master (manager), and slave (subordinate).
- Compare and contrast the three core AMBA protocols: AXI, AHB, and APB.
- Trace the historical evolution of the AXI specification from AXI3 to AXI4, AXI4-Lite, and AXI4-Stream.
- Master the fundamental architectural innovations that allow AXI to achieve ultra-high bandwidth, low latency, and concurrent data transfers.
- Calculate bus throughput, efficiency, and bandwidth limits across various bus widths and clock frequencies.

---

## The Role of AXI in High-Performance SoC Design

Modern System-on-Chip (SoC) architectures integrate multi-core central processing units (CPUs), high-end graphics processing units (GPUs), neural network processing units (NPUs), hardware video accelerators, high-speed Direct Memory Access (DMA) engines, and multi-channel DDR memory controllers on a single silicon die. These heterogenous compute engines demand:

1. **Ultra-High Bandwidth:** Multi-gigabyte-per-second throughput to sustain graphics, deep learning inference, and streaming compute workloads.
2. **Low Latency:** Fast access paths for latency-critical CPU cache refills.
3. **Decoupled Concurrency:** Simultaneous bidirectional data movement without read/write bus turnaround bubbles.
4. **Frequency Decoupling:** Ability to insert register slices (pipeline stages) between masters, interconnects, and slaves without violating protocol timing or deadlocking.

The **AMBA (Advanced Microcontroller Bus Architecture) AXI** protocol, developed by Arm, is the industry standard created specifically to meet these demanding requirements.

![AXI System Topology](images/ch1_axi_system_topology.svg)

As illustrated in the system topology above, AXI serves as the high-throughput backbone (the "system fabric") connecting processing cores and high-speed memory subsystems. Slower peripherals (such as UART, SPI, I2C, and configuration registers) connect via an **AXI-to-APB bridge**, insulating the high-speed interconnect from low-speed bus stalls.

---

## Core AXI Terminology and Data Hierarchy

Before analyzing AXI channels, handshakes, and burst math, it is essential to use exact, specification-compliant terminology. Engineers frequently confuse words like *transfer*, *beat*, *burst*, and *transaction*, even though each refers to a distinct layer of the AXI protocol.

![AXI Terminology and Data Hierarchy](images/ch1_axi_terminology_hierarchy.svg)

### Data Granularity and Bus Width Terminologies

- **Bit:** The smallest unit of binary information (`0` or `1`) carried on a single physical signal wire—for example, a 1-bit control wire such as `AWVALID` or `WLAST`, or a single bit slice of data such as `WDATA[0]`.
- **Byte:** Exactly **8 contiguous bits**. The byte is the fundamental addressable unit of AXI memory: every AXI address (`AWADDR`, `ARADDR`) is a **byte address**, and write masking operates at byte granularity.
- **Byte Lane and Write Strobe (`WSTRB`):** An 8-bit physical slice of the data bus (`WDATA[8n+7 : 8n]` or `RDATA[8n+7 : 8n]`). A data bus of width `DATA_WIDTH` bits is divided into `DATA_WIDTH / 8` parallel byte lanes (for example, a 64-bit bus has 8 byte lanes). On the Write Data (`W`) channel, each byte lane `n` has a dedicated 1-bit strobe wire `WSTRB[n]` indicating whether that byte carries valid write data (`1`) or must be ignored by memory (`0`).
- **Architectural Word Sizes:** Following Arm/AMBA convention, multi-byte data quantities map directly to `AxSIZE` encodings:
  - **Half-word:** 16 bits = 2 bytes (`AxSIZE = 3'b001`)
  - **Word:** 32 bits = 4 bytes (`AxSIZE = 3'b010`)
  - **Double-word:** 64 bits = 8 bytes (`AxSIZE = 3'b011`)
  - **Quad-word:** 128 bits = 16 bytes (`AxSIZE = 3'b100`)
- **Data Bus Width (`DATA_WIDTH`):** The physical bit-width of the `WDATA` and `RDATA` buses (standardized at `32`, `64`, `128`, `256`, `512`, or `1024` bits in AXI4), establishing a maximum per-cycle transport capacity of `DATA_WIDTH / 8` bytes.

### Protocol Exchange Hierarchy: Handshake, Transfer, Beat, Burst, and Transaction

- **Handshake:** The synchronous flow-control event on any AXI channel where both `VALID = 1` (driven by the source) and `READY = 1` (driven by the destination) are sampled HIGH on the rising edge of `ACLK`.
- **Wait State:** Any rising clock edge where the source asserts `VALID = 1` but the destination holds `READY = 0`. No transfer occurs during a wait state, and the source must keep `VALID` HIGH and all payload wires stable until `READY` goes HIGH.
- **Transfer:** A **single information exchange across any of the five AXI channels**, completed by exactly one `VALID` + `READY` handshake:
  - **Address Transfer:** One handshake on `AW` or `AR` carrying the start address and burst attributes.
  - **Data Transfer (Beat):** One handshake on `W` or `R` carrying data payload (plus `WSTRB`/`WLAST` on `W`, or `RRESP`/`RLAST` on `R`).
  - **Response Transfer:** One handshake on `B` carrying the burst completion status (`BRESP` and `BID`).
- **Beat (Data Beat):** A single **data transfer**—specifically one `VALID` + `READY` handshake on the Write Data (`W`) or Read Data (`R`) channel. On data channels, *beat* and *data transfer* are synonymous, whereas *transfer* is the broader term that applies to `AW`, `AR`, and `B` as well.
  - **Beat Size (`AxSIZE`) vs. Bus Width (`DATA_WIDTH`):** Each beat carries up to $2^{\text{AxSIZE}}$ active bytes (1 to 128 bytes). If $2^{\text{AxSIZE}} = \text{DATA\_WIDTH}/8$, every beat uses the entire bus width (**Full-Width Transfer**). If $2^{\text{AxSIZE}} < \text{DATA\_WIDTH}/8$, only a subset of byte lanes is active per beat (**Narrow Transfer**).
- **Burst:** A contiguous sequence of **1 to 256 data beats** (`Burst_Length = AxLEN + 1`) associated with a single address transfer and terminated on the final beat by `WLAST = 1` (write) or `RLAST = 1` (read). Even a single-beat access (`AxLEN = 0`) is formally a **1-beat burst**. In an aligned burst, total payload bytes equal $(\text{AxLEN} + 1) \times 2^{\text{AxSIZE}}$.
- **Transaction:** The **complete end-to-end read or write bus operation** spanning all participating channels from initial address request to final completion acknowledgment:
  - **Write Transaction:** `1 AW Address Transfer` + `1 W Data Burst (AWLEN + 1 Beats)` + `1 B Response Transfer` = $(\text{AWLEN} + 3)$ total channel transfers.
  - **Read Transaction:** `1 AR Address Transfer` + `1 R Data Burst (ARLEN + 1 Beats with embedded RRESP)` = $(\text{ARLEN} + 2)$ total channel transfers.
- **Outstanding Transaction:** An active transaction whose address transfer (`AW` or `AR` handshake) has completed, but whose final completion transfer (`B` handshake for a write, or final `R` beat with `RLAST = 1` for a read) has not yet completed.

### Architectural and Topology Terminologies

- **Channel:** One of the five physically separate, unidirectional signal bundles (`AW`, `W`, `B`, `AR`, `R`), each governed by its own independent `VALID`/`READY` handshake.
- **Phase:** A logical stage of a transaction (**Address Phase**, **Data Phase**, or **Response Phase**). Because AXI channels are decoupled, phases of different transactions—and even the address and data phases of a single write transaction—can overlap or execute concurrently.
- **Master (Manager):** The bus agent that initiates read and write transactions by driving `ARVALID` and `AWVALID` (for example, a CPU, GPU, or DMA engine). Modern AMBA 5 specifications use the term **Manager** as the updated equivalent of *Master*.
- **Slave (Subordinate):** The target bus agent that accepts requests and returns read data or write responses (for example, a DDR controller, SRAM, or peripheral bridge). Modern AMBA 5 specifications use the term **Subordinate** as the updated equivalent of *Slave*.
- **Interconnect (Crossbar):** The switching and arbitration fabric that decodes addresses, routes channel transfers between multiple masters and slaves, adapts bus widths, and tracks transaction IDs.
- **Register Slice (Skid Buffer):** A pipeline flip-flop stage inserted across an AXI channel boundary to break combinatorial timing paths without changing logical transaction behavior.

### Comprehensive AXI Terminology Reference Matrix

| Term | Hierarchy Level | AXI Signal / Governing Equation | Precise Definition |
| --- | --- | --- | --- |
| **Bit** | Physical wire | `1` signal wire (`0` or `1`) | Smallest binary unit on any single AXI wire (e.g., `AWVALID`, `WDATA[0]`). |
| **Byte** | Addressable unit | $1\text{ byte} = 8\text{ bits}$ | Smallest addressable memory unit (`AxADDR` is a byte address) and masking unit. |
| **Byte Lane** | Data bus slice | `DATA[8n+7 : 8n]`, `DATA_WIDTH / 8` lanes | One 8-bit data slice; qualified on writes by `WSTRB[n]`. |
| **Word** | Multi-byte unit | Half-word `2B`, Word `4B`, DWord `8B`, QWord `16B` | Standard Arm/AMBA data sizes corresponding to `AxSIZE = 3'b001..3'b100`. |
| **Handshake** | Clock-edge event | $\text{VALID} = 1 \land \text{READY} = 1$ at `posedge ACLK` | Synchronous event that commits a single transfer on a channel. |
| **Wait State** | Stall cycle | $\text{VALID} = 1 \land \text{READY} = 0$ at `posedge ACLK` | Cycle where source waits for destination readiness; payload must remain stable. |
| **Transfer** | Single-channel exchange | 1 handshake on `AW`, `W`, `B`, `AR`, or `R` | One committed address, data, or response item on any single channel. |
| **Beat** | Data-channel exchange | 1 handshake on `W` or `R` ($2^{\text{AxSIZE}}$ bytes) | One data transfer on `W` or `R` (synonymous with *data transfer*). |
| **Burst** | Multi-beat payload | $\text{AxLEN} + 1$ beats; ends with `WLAST`/`RLAST` | Complete data phase (1–256 beats) tied to one address transfer. |
| **Transaction** | End-to-end operation | Write: $\text{AWLEN} + 3$ transfers; Read: $\text{ARLEN} + 2$ transfers | Full read (`AR`+`R`) or write (`AW`+`W`+`B`) sequence from request to completion. |
| **Outstanding Transaction** | In-flight operation | Between `AW`/`AR` handshake and `B`/`RLAST` handshake | Transaction initiated on an address channel that has not yet completed. |
| **Master / Slave** | Topology agents | Initiator (**Manager**) $\rightarrow$ Target (**Subordinate**) | Initiating requester (`Master`/`Manager`) vs. responding target (`Slave`/`Subordinate`). |

---

## The AMBA Protocol Hierarchy: AXI vs. AHB vs. APB

The AMBA family defines a tiered hierarchy of on-chip interconnect protocols, each tailored for specific performance, area, and power budgets:

| Protocol Feature                 | APB (Advanced Peripheral Bus)                | AHB (Advanced High-performance Bus)                 | AXI (Advanced eXtensible Interface)                       |
| -------------------------------- | -------------------------------------------- | --------------------------------------------------- | --------------------------------------------------------- |
| **Primary Domain**               | Low-bandwidth peripherals, control registers | Moderate-performance on-chip memories, legacy DMA   | High-performance cores, DDR controllers, GPUs, PCIe       |
| **Channel Structure**            | Single multiplexed address/data bus          | Pipelined address and data phases                   | **Five independent, decoupled channels**                  |
| **Read/Write Concurrency**       | Half-duplex (sequential)                     | Pipelined half-duplex                               | **Full-duplex simultaneous read and write**               |
| **Burst Support**                | None (single transfers only)                 | Fixed bursts (INCR4, WRAP8, etc.), address per beat | **Up to 256 beats (AXI4); address issued once per burst** |
| **Out-of-Order Execution**       | No                                           | No                                                  | **Yes (via Transaction ID tags)**                         |
| **Pipelining / Register Slices** | No                                           | Difficult (timing tight on address/data phases)     | **Trivial (register slices insertable on any channel)**   |
| **Hardware Complexity**          | Minimal (very few gates)                     | Moderate                                            | High (requires crossbars, FIFOs, and reorder buffers)     |

---

## Evolution of the AXI Specification

The AXI specification has undergone several major iterations to adapt to growing chip complexity and varying peripheral requirements:

![AXI Evolution](images/ch1_axi_evolution.svg)

### AXI3 (2003)

Introduced in the AMBA 3 specification, AXI3 established the foundational 5-channel architecture:

- Maximum burst length of **16 beats** (`AxLEN[3:0]`).
- Write interleaving supported via the Write Data ID tag (`WID`).
- Atomic locked transfers (`AxLOCK[1:0]`) alongside exclusive accesses.

### AXI4 (2010)

Introduced in AMBA 4, AXI4 optimized the protocol for modern memory subsystems:

- Extended maximum burst length to **256 beats** for `INCR` bursts (`AxLEN[7:0]`), dramatically improving DMA efficiency.
- **Removed the `WID` signal** (write data interleaving), mandating that write data must strictly match write address order. This drastically simplified interconnect crossbar FIFOs.
- Added Quality of Service (`AxQOS`) and Region (`AxREGION`) identifier signals.
- Removed locked transfers (`AxLOCK[1:0]`), retaining only exclusive accesses for multicore synchronization.

### AXI4-Lite

A lightweight subset of AXI4 tailored for simple memory-mapped control and status registers (CSRs):

- Fixed burst length of **1 beat** (`AxLEN = 0`).
- Fixed data bus width of 32-bit or 64-bit.
- All transfers are unbuffered and uncacheable (`AxCACHE` omitted).
- Zero support for exclusive accesses or out-of-order execution (IDs omitted).

### AXI4-Stream

A point-to-point streaming protocol without address channels, designed for unbounded packet streams such as camera sensors, video pipelines, network packets, and DSP blocks.

---

## Fundamental Architectural Innovations of AXI

Why has AXI dominated high-performance SoC design for over two decades? Four key architectural concepts set AXI apart:

### Decoupled Five-Channel Architecture

Instead of sharing a single bidirectional bus between address, read data, and write data, AXI separates them into five unidirectional channels:

1. **Read Address (AR)**
2. **Read Data (R)**
3. **Write Address (AW)**
4. **Write Data (W)**
5. **Write Response (B)**

Because each channel is completely independent and possesses its own forward (`VALID`) and reverse (`READY`) flow-control signals, transfers can execute concurrently. A master can issue five read addresses while transmitting write data for a previous command, all while receiving read data from an earlier read burst.

### Address Issued Once per Burst

In legacy protocols like AHB, an address is computed and presented on the bus for every single beat of a burst. In AXI, the master issues the start address **once** on the Address channel along with the burst length (`AxLEN`), burst size (`AxSIZE`), and burst type (`AxBURST`). The slave or interconnect internally increments the address for all subsequent beats, saving massive address bus bandwidth and switching power.

### Out-of-Order and Interleaved Transactions

Fast peripherals (such as on-chip SRAM) should not be blocked behind slow peripherals (such as external DDR memory with variable refresh and precharge latencies). AXI tags every transaction with an **ID**. Slaves may return responses out-of-order with respect to other IDs, allowing high-performance reordering inside the master or crossbar.

### Direct Support for Pipeline Register Slices

Every signal across all five channels moves in only one direction (either Master-to-Slave or Slave-to-Master). There are no multi-driver tri-state buses, and handshake flow control is strictly point-to-point. Consequently, a designer can place register slices (pipeline registers) directly across any channel boundary to break long timing paths in deep submicron silicon without changing transaction semantics.

---

## Bandwidth and Bus Utilization Calculations

The maximum theoretical bandwidth of an AXI interface is governed by its clock frequency, data bus width, and handshake efficiency.

### Theoretical Maximum Bandwidth

The peak theoretical bandwidth (\(BW\_{peak}\)) for either read or write transfers is given by:

$$BW_{peak} = f_{CLK} \times W_{bytes}$$

Where:

- \(f\_{CLK}\) is the interface clock frequency in Hertz (Hz).
- \(W\_{bytes} = \frac{\text{Data Bus Width in Bits}}{8}\).

Because AXI supports **simultaneous full-duplex operation** (independent Read and Write data channels), the combined peak aggregate bandwidth is:

$$BW_{aggregate\_peak} = 2 \times \left( f_{CLK} \times W_{bytes} \right)$$

### Example Calculation

Consider a high-performance 256-bit AXI4 bus operating at an internal clock frequency of 800 MHz:

- Data bus width = 256 bits = 32 bytes.
- Peak Read Bandwidth:
  $$BW_{read} = 800 \times 10^6 \times 32 = 25.6\text{ GB/s}$$
- Peak Write Bandwidth:
  $$BW_{write} = 800 \times 10^6 \times 32 = 25.6\text{ GB/s}$$
- Aggregate Peak Bandwidth:
  $$BW_{total} = 25.6\text{ GB/s} + 25.6\text{ GB/s} = 51.2\text{ GB/s}$$

### Protocol Efficiency

In real-world systems, the effective bandwidth (\(BW\_{eff}\)) is reduced by address handshake latency, slave wait states, burst boundaries, and response phases:

$$\text{Efficiency } (\eta) = \frac{\text{Active Data Handshake Cycles}}{\text{Total Elapsed Cycles}} \times 100\%$$

Longer burst lengths (such as AXI4's 256-beat bursts) amortize the single-cycle address phase across many data cycles, pushing protocol efficiency toward 98-99%.

---

## Chapter Summary

- **AXI Terminology Hierarchy:** A single `VALID` + `READY` handshake commits a **transfer** on any channel (`AW`, `W`, `B`, `AR`, `R`), whereas a **beat** specifically denotes a data transfer on `W` or `R`; **bursts** group `AxLEN + 1` beats of $2^{\text{AxSIZE}}$ bytes (built from 8-bit **bytes** and 1-bit **bits** across **byte lanes**); and a **transaction** encompasses the entire end-to-end address, data burst, and response sequence.
- **AXI** is the highest-performance member of the AMBA family, engineered for high-bandwidth, low-latency multi-master SoC interconnects.
- While **APB** is unpipelined and half-duplex for low-speed peripherals, and **AHB** features pipelined single-burst transactions, **AXI** features five decoupled, concurrent channels with out-of-order execution support.
- **AXI4** enhanced AXI3 by expanding burst lengths from 16 to 256 beats, removing write data interleaving (`WID`) to simplify hardware, and introducing QoS and memory regions.
- **AXI4-Lite** serves register access needs with 1-beat bursts, while **AXI4-Stream** handles addressless, continuous data streams.
- The decoupled channel architecture enables register slicing for physical timing closure without degrading logical throughput.

---

## Review Questions

### Question 1

Explain why AXI is able to achieve significantly higher bus utilization than AHB during simultaneous read and write traffic.

<details>
<summary><b>View Answer</b></summary>
AHB utilizes a shared, multiplexed address bus and shared data phase that operates in half-duplex mode; reading and writing cannot occur at the exact same physical clock cycle on the same bus segment. AXI features physically separate, independent Read Data (R) and Write Data (W) channels, along with independent Read Address (AR) and Write Address (AW) channels. This enables full-duplex simultaneous read and write transfers without bus turnaround cycles.
</details>

### Question 2

Why did the AXI4 specification remove the `WID` (Write Data ID) signal that was present in AXI3?

<details>
<summary><b>View Answer</b></summary>
In AXI3, `WID` allowed write data beats from different transactions to be interleaved on the Write Data channel. In practice, almost no masters took advantage of write interleaving, but supporting it forced slave devices and interconnect crossbars to implement large reassembly buffers and complex tracking logic. Removing `WID` in AXI4 mandates that write data must be sent in the exact order of the issued write addresses, significantly reducing area and routing congestion in crossbar switches.
</details>

### Question 3

An AXI4 interface has a 128-bit data bus operating at 500 MHz. What is its peak unidirectional bandwidth in Gigabytes per second (GB/s)?

<details>
<summary><b>View Answer</b></summary>
A 128-bit bus carries 16 bytes per beat (128 / 8 = 16 bytes).  
Peak bandwidth = $500 \times 10^6 \text{ cycles/sec} \times 16 \text{ bytes/cycle} = 8.0 \times 10^9 \text{ bytes/sec} = 8.0\text{ GB/s}$.
</details>

### Question 4

Why are register slices uniquely easy to implement in an AXI system compared to earlier shared-bus architectures?

<details>
<summary><b>View Answer</b></summary>
All AXI signals are unidirectional point-to-point connections with dedicated forward (`VALID`) and reverse (`READY`) handshakes. There are no tri-state buses, no combinatorial multi-drop feedback loops, and no timing dependencies requiring zero-cycle slave responses. A register slice can be inserted into any of the five channels by capturing the payload and handling the ready/valid handshake across flip-flop registers, seamlessly breaking critical timing paths.
</details>

### Question 5

Distinguish between a **transfer**, a **beat**, a **burst**, and a **transaction** in AXI4, and calculate the number of bits, bytes, data beats, and total channel transfers in an 8-beat (`AWLEN = 7`), 64-bit (`AWSIZE = 3'b011`) write transaction on a 64-bit bus.

<details>
<summary><b>View Answer</b></summary>
**Definitions:**
- **Transfer:** Any single `VALID` + `READY` handshake on any of the five channels (`AW`, `W`, `B`, `AR`, `R`).
- **Beat:** A single data transfer specifically on the Write Data (`W`) or Read Data (`R`) channel.
- **Burst:** The sequence of `AxLEN + 1` data beats associated with one address transfer and terminated by `WLAST = 1` or `RLAST = 1`.
- **Transaction:** The complete end-to-end operation spanning address, data burst, and response phases.
**Calculation (`AWLEN = 7`, `AWSIZE = 3'b011`, 64-bit bus):**
- **Transactions / Bursts:** `1` write transaction containing `1` write burst.
- **Data Beats:** `AWLEN + 1` = $7 + 1 = 8\text{ data beats}$ on the `W` channel.
- **Total Channel Transfers:** `1 AW address transfer` + `8 W data beats` + `1 B response transfer` = $10\text{ channel transfers total}$ ($\text{AWLEN} + 3 = 10$).
- **Data Granularity:** Each beat carries $2^3 = 8\text{ bytes} = 64\text{ bits}$ across 8 byte lanes; the full burst transfers $8 \times 8 = 64\text{ bytes} = 512\text{ bits}$ of payload data.
</details>

---

##### Copyright (c) 2026 squared-studio
