# CHI Node Architecture & Network-on-Chip (NoC) Topologies

## Microarchitecture of Key CHI Nodes
In an enterprise or high-end mobile SoC implementing AMBA 5 CHI, the overall architecture is composed of distributed, specialized nodes communicating across a packet-switched fabric. To understand how memory coherency and high bandwidth are achieved, we must examine the internal structure of each primary node type: **RN-F**, **HN-F**, and **SN-F**.

```
+--------------------------------------------------------------------------+
|                       CHI DISTRIBUTED MESH FABRIC                        |
|                                                                          |
|     [ RN-F 0 ] <======> [ Crosspoint (0,0) ] <======> [ HN-F 0 ]         |
|         ^                        ^                         ^             |
|         |                        |                         |             |
|         v                        v                         v             |
|     [ RN-F 1 ] <======> [ Crosspoint (0,1) ] <======> [ SN-F 0 ]         |
+--------------------------------------------------------------------------+
```

---

## Inside the Fully Coherent Request Node (`RN-F`)
An **RN-F** typically encapsulates one or more high-performance CPU cores (e.g., an Arm Cortex-X or Neoverse core) together with their private L1 and L2 cache hierarchies.

### Architectural Sub-Blocks of an RN-F:
1. **Core Load/Store Pipeline:**
   - Issues memory operations (loads, stores, atomics, and barriers) derived from instruction execution.
2. **Private Cache Subsystem (L1/L2):**
   - Implements local MOESI/MESI cache states.
   - Handles local cache hits without generating bus traffic.
3. **Outbound Request Generator:**
   - Converts local cache misses and write invalidations into CHI **Request Flits (`REQ`)**.
   - Assigns a local **Transaction ID (`TxnID`)** to track each outstanding operation.
4. **Inbound Snoop Pipeline:**
   - Listens to incoming **Snoop Flits (`SNP`)** routed from Home Nodes across the NoC.
   - Probes private cache tag directories, invalidates lines, or extracts dirty data to satisfy peer requests.
5. **Outstanding Transaction Trackers (Miss Status Holding Registers - MSHRs):**
   - Keeps track of all pending memory fills, responses, and completion handshakes (`CompAck`).

---

## Inside the Fully Coherent Home Node (`HN-F`)
The **HN-F** is the nerve center of cache coherency in an AMBA CHI system. In large SoCs, physical memory is partitioned across multiple distributed HN-F "slices" (e.g., 8, 16, or 32 parallel HN-Fs) to distribute traffic evenly across the chip.

![HN-F Microarchitecture and Directory](images/ch2_hnf_architecture_directory.svg)

### Key Functional Subsystems within an HN-F:

### Point of Serialization (PoS)
The PoS is the single arbiter responsible for determining the global memory observation order for its allocated address range.
- When multiple RN-Fs simultaneously issue requests targeting the same cache line (e.g., two cores attempting to write to the same lock variable), the PoS arbitrates between them.
- Whichever transaction is accepted first by the PoS establishes the architectural order of execution. All subsequent accesses must wait until the winning transaction completes or releases the line.

### Snoop Filter / Directory (SF)
The Snoop Filter maintains a directory of all cache lines currently cached across any RN-F in the SoC.
- **Directory Tag Arrays:** Stores the address tags of cached lines along with a **Sharer Bitmask** (where each bit corresponds to an RN-F in the system).
- **Directory States:** Tracks whether the line is held in an **Exclusive (Unique)** state by a single core or in a **Shared** state across multiple cores.
- **Snoop Pruning:** When an RN-F requests data, the HN-F queries the SF. If the SF indicates that no other RN-F holds the line, the HN-F completely suppresses snoop generation, saving significant NoC bandwidth and core power.

### System Level Cache (SLC)
Many modern interconnects (such as the Arm CoreLink CMN-600 / CMN-700) integrate a distributed, on-chip L3/L4 cache inside each HN-F slice.
- Serves as a high-speed buffer for dirty and clean cache lines evicted by RN-Fs.
- Services read requests in 10 to 15 nanoseconds, avoiding slow, energy-expensive off-chip memory trips.

### Coherency Tracker Entries
The HN-F contains a pool of internal hardware tracking slots. Each allocated tracker entry manages the end-to-end lifecycle of a single coherent transaction: issuing snoops to peer RN-Fs, collecting snoop responses (`RSP`/`DAT`), querying the SLC/SN-F, delivering completion tokens, and waiting for `CompAck`.

---

## Inside the Subordinate Node (`SN-F`)
The **SN-F** interfaces the coherent interconnect to physical memory subsystems:
- **DRAM Controllers:** DDR4, DDR5, LPDDR5, or high-bandwidth 3D-stacked memory (HBM3).
- **Memory Scheduling Queues:** Re-orders incoming read and write flits to maximize DRAM bank and row-buffer hit rates.
- **Reliability Engines:** Implements Error-Correcting Code (ECC) generation, scrubbing, and multi-bit fault detection.

---

## Network-on-Chip (NoC) Topologies
In AMBA CHI, physical links between nodes are not constrained to rigid crossbar switches. Modern CHI interconnects deploy three primary topologies:

| Topology | Target System | Scalability | Latency Characteristics | Wire Congestion |
| :--- | :--- | :---: | :--- | :--- |
| **Crossbar Matrix** | Small mobile SoCs (2-4 CPU clusters) | Poor ($O(N^2)$) | Extremely low (single-cycle hop) | High at center |
| **Bidirectional Ring** | Mid-tier computing (4-8 clusters, e.g. CCI-550) | Moderate | Scales linearly with ring circumference | Moderate |
| **2D Mesh Grid** | Enterprise Cloud, Neoverse (16-128+ cores, e.g. CMN-700) | Exceptional ($O(N)$) | Uniform, predictable hop latency | Low, distributed evenly across silicon |

---

## The 2D Mesh Topology and Dimension-Order Routing
For high-core-count enterprise silicon, the **2D Mesh Network-on-Chip** has emerged as the universal standard.

In a 2D Mesh, the chip is laid out as a grid of coordinate points $(X, Y)$. Each grid intersection houses a **Crosspoint Router (XP)**. Each router connects to four orthogonal neighbors (North, South, East, West) and features local device ports connecting to an RN-F, HN-F, or SN-F.

![2D Mesh Topology and Routing](images/ch2_mesh_topology_routing.svg)

### Dimension-Order Routing (DOR: X-First then Y)
In any packet-switched network, arbitrary packet routing can lead to **routing deadlocks**—situations where packets in adjacent routers form a circular waiting loop, freezing the entire interconnect.

To guarantee mathematical deadlock freedom without requiring complex virtual channel arbitration, CHI 2D Mesh networks enforce **Dimension-Order Routing (DOR)**:
1. **Rule 1 (X-First Traversal):** A flit must traverse the horizontal (X) dimension completely until its current X-coordinate matches the destination Target NodeID ($X_{\text{curr}} == X_{\text{dest}}$).
2. **Rule 2 (Y Traversal):** Only after reaching the destination X-coordinate may the flit turn into the vertical (Y) dimension to reach the target router ($Y_{\text{curr}} == Y_{\text{dest}}$).
3. **Deadlock Freedom Theorem:** By prohibiting flits from turning from the Y dimension back into the X dimension (eliminating 4 out of the 8 possible turns in a 2D grid), circular channel dependency loops cannot form. The routing graph is strictly acyclic!

---

## Address Hashing and NodeID Slicing
In a system with 16 distributed HN-F nodes, how does an RN-F know which specific HN-F to target when issuing a read to physical address `0x8000_1000`?

Hardware performs **Address Striping (Hashing)**:

```
[64-Bit Physical Address]
  +-----------------------------------------------------------+
  |  Address Tag  | Set Index | HN-F Hash Bits | Cache Offset |
  +-----------------------------------------------------------+
                              |
                              v
             [ Hash Function: XOR Logic / Prime Modulo ]
                              |
                              v
             Target NodeID: HN-F_5 (XP Coordinate 1,2)
```

The lower address bits (above the 64-byte cache line offset) are passed through an internal hashing algorithm (often involving XOR combinations of high and low address bits). This maps contiguous memory lines across alternating HN-F slices in a round-robin or interleaved fashion:
- Address `0x00` $\rightarrow$ `HN-F 0`
- Address `0x40` $\rightarrow$ `HN-F 1`
- Address `0x80` $\rightarrow$ `HN-F 2`
- ...

This striping ensures that memory access workloads are distributed uniformly across all mesh routers, directories, and memory channels, preventing hotspots and maximizing aggregate memory bandwidth.

---

## Chapter Summary
- An **RN-F** integrates CPU cores, local caches, outbound request generators, and inbound snoop pipelines.
- An **HN-F** is the coherency hub containing the Point of Serialization (PoS), Snoop Filter / Directory, System Level Cache (SLC), and transaction tracker slots.
- Enterprise SoCs deploy **2D Mesh NoCs** where nodes interface through Crosspoint (XP) routers.
- **Dimension-Order Routing (X-First then Y)** strictly eliminates circular buffer waiting cycles, guaranteeing deadlock-free packet routing.
- Physical memory addresses are **hashed across distributed HN-F slices** to balance traffic and eliminate memory bottlenecks.

---

## Review Questions

1. **What is the function of the Point of Serialization (PoS) inside an HN-F, and why is it critical for multi-threaded programming?**
   <details>
   <summary>Click to view answer</summary>
   The Point of Serialization (PoS) acts as the definitive hardware arbiter that establishes the exact global arrival order for all concurrent transactions targeting the same physical cache line. In multi-threaded software, when multiple cores attempt to acquire a mutex lock or write to a shared variable simultaneously, the PoS serializes their requests into a strict chronological sequence, preventing race conditions and ensuring that all observers see a single, consistent memory modification history.
   </details>

2. **How does Dimension-Order Routing (DOR: X-First then Y) mathematically prevent routing deadlocks in a 2D Mesh NoC?**
   <details>
   <summary>Click to view answer</summary>
   A routing deadlock occurs when packets occupy a circular loop of network buffers where each packet waits for the next buffer to free up. In a 2D mesh, there are 8 possible 90-degree turns. DOR mandates that packets must travel entirely along the X-axis before turning onto the Y-axis, explicitly prohibiting any packet from turning from Y back onto X. By eliminating these 4 turns, circular dependency cycles become mathematically impossible, rendering the network topology acyclic and deadlock-free.
   </details>

3. **Why do high-performance SoCs stripe physical memory addresses across multiple HN-F slices rather than using a single centralized Home Node?**
   <details>
   <summary>Click to view answer</summary>
   A single centralized Home Node would create an catastrophic bandwidth bottleneck, as every coherent read, write, and snoop from dozens of cores would converge on one physical location, saturating local routing links and directory tag RAM ports. By striping addresses across 8, 16, or 32 HN-F slices, memory traffic is dispersed evenly across the entire surface of the silicon die, allowing parallel directory lookups and multiplying aggregate interconnect bandwidth.
   </details>

4. **What information does the Snoop Filter inside an HN-F maintain, and how does it reduce core power consumption?**
   <details>
   <summary>Click to view answer</summary>
   The Snoop Filter maintains a directory of address tags along with a sharer bitmask indicating which specific RN-F nodes currently cache each line. When a core requests data, the HN-F queries the Snoop Filter. If the line is not cached anywhere or is cached by only one specific core, the HN-F sends a targeted snoop only to that core (or suppresses snoops entirely if unshared). This eliminates wasteful broadcast snoops to innocent cores, saving significant dynamic switching power and preventing pipeline stalls on core tag RAMs.
   </details>

---

##### Copyright (c) 2026 squared-studio

