# Curriculum and Pedagogical Plan: AMBA 5 CHI Protocol Specification

## Course Overview & Pedagogical Philosophy
The **AMBA 5 Coherent Hub Interface (CHI)** represents the pinnacle of on-chip and multi-socket interconnect architectures. Developed by ARM to replace physical wire-bundle standards (like ACE) in massive enterprise processors, cloud data centers, and modern mobile SoCs, CHI replaces dedicated signal channels with a **packetized, layered Network-on-Chip (NoC)** protocol.

This curriculum provides a definitive, silicon-grade technical study of the AMBA CHI specification.

### Core Constraints & Directives:
- **Zero SystemVerilog / HDL Coding:** Focus purely on architectural principles, protocol definitions, packet and flit structures, channel layering, state machines, transactions, credit-based flow control, retry mechanisms, DVM, DCT/DWT, snooping, Home Nodes, and interconnect topologies.
- **Visual Clarity via Vector SVGs:** Every chapter is anchored by custom SVG diagrams stored in `images/`, avoiding Mermaid rendering issues and providing publication-quality schematics.
- **Deep Mathematical & Protocol Precision:** Each chapter covers protocol invariants, channel handshakes, response bitfield encodings, race condition resolutions, and hardware coherency mechanisms.
- **Self-Assessment:** Every chapter concludes with rigorous review questions featuring collapsible `<details>` answers for interview and certification preparation.
##### Copyright (c) 2026 squared-studio

---

## Complete 10-Chapter Syllabus

### Introduction to AMBA 5 CHI & Architecture Evolution
- Limitations of AMBA ACE: The Physical Wire and Pin-Count Scaling Wall
- The Packetized, Layered Network-on-Chip (NoC) Paradigm
- CHI Architectural Layers: Protocol Layer, Network Layer, Link Layer
- Node Taxonomy:
  - Request Nodes: Fully Coherent (`RN-F`), I/O Coherent (`RN-I`), Non-coherent (`RN-D`)
  - Home Nodes: Fully Coherent (`HN-F`), Non-coherent I/O (`HN-I`)
  - Subordinate Nodes: Memory (`SN-F`), Peripheral (`SN-I`)
  - Miscellaneous Node (`MN`)
- Key Figures:
  - `images/ch1_chi_evolution_layers.svg`: Contrasting ACE dedicated wires with CHI layered packets.
  - `images/ch1_chi_node_types_topology.svg`: Global system topology showing RN, HN, SN, and MN nodes.

### CHI Node Architecture & Network-on-Chip (NoC) Topologies
- Microarchitecture of Key Nodes:
  - Inside the RN-F: Core integration, L1/L2 caches, local trackers, protocol engine
  - Inside the HN-F: Point of Serialization (PoS), Snoop Filter / Directory, System Level Cache (SLC)
  - Inside the SN-F: Memory controllers (DDR5, HBM, LPDDR5)
- NoC Topologies: Crossbars, Bidirectional Rings, 2D Mesh Networks
- Dimension-Order Routing (X-First then Y) and Routing Deadlock Freedom
- NodeID Addressing and Physical Network Interfaces
- Key Figures:
  - `images/ch2_mesh_topology_routing.svg`: 2D Mesh crosspoint routing with X-first traversal.
  - `images/ch2_hnf_architecture_directory.svg`: Internal block diagram of the HN-F Home Node.

### Layered Architecture & Packet/Flit Formatting
- Deconstructing the CHI Stack:
  - Protocol Layer: Transaction semantics, opcode generation, coherency lifecycle
  - Network Layer: NodeID routing, Virtual Networks (VNETs), packet segmentation
  - Link Layer: Credit management, flit framing, clock and power handshakes
- What is a Flit? (Flow Control Unit)
- Physical Link Interface Signals (`TXFLITV`, `TXFLITPEND`, `TXFLIT`, `TXLCRDV`)
- The Four Primary Flit Types:
  - Request Flit (`REQ`): Opcodes, Target ID, Source ID, TxnID, Address, Memory Attributes
  - Response Flit (`RSP`): Status, Data Buffer ID (DBID), PCrdType, Forwarding State
  - Data Flit (`DAT`): DataID, Byte Enables, 128/256/512-bit data payloads
  - Snoop Flit (`SNP`): Inbound snoops from Home Node to Request Nodes
- Key Figures:
  - `images/ch3_layered_architecture_flit.svg`: Flit encapsulation through the 3 protocol layers.
  - `images/ch3_flit_packet_structure.svg`: Detailed field-by-field layout of REQ, RSP, SNP, and DAT flits.

### Credit-Based Flow Control & Link Layer Handshake
- Overcoming `VALID`/`READY` Backpressure Bottlenecks in High-Frequency NoCs
- The Link Credit (`LCRDV`) Flow Control Mechanism
- Link Credit Initialization Sequence
- Flit Transmission Rules: When can a transmitter drive a flit?
- Flit Pending Signaling (`TXFLITPEND`) for Low-Power Link Wakeup
- Timing Waveforms and Clock Cycle Analysis of Flit Egress and Credit Increments
- Key Figures:
  - `images/ch4_link_credit_flow.svg`: Transmitter and Receiver credit counter and buffer interaction.
  - `images/ch4_credit_waveform_timing.svg`: Timing waveform showing flit launch and credit return pulses.

### Coherent Read Transactions and Direct Data Transfer (DDT)
- CHI Read Transaction Catalog: `ReadShared`, `ReadClean`, `ReadNotSharedDirty`, `ReadOnce`
- Anatomy of a Coherent Read via Home Node (HN-F):
  - Request Phase (`REQ` from RN-F to HN-F)
  - Snoop Phase (`SNP` from HN-F to peer RN-F)
  - Data Response Phase (`DAT` from peer or memory to HN-F, then to RN-F)
  - Completion Handshake (`CompAck` from RN-F to HN-F)
- Direct Data Transfer (DDT / Direct Cache Transfer - DCT):
  - Forwarding Snoop (`SnpSharedFwd`, `SnpCleanFwd`)
  - Direct Cache-to-Cache Transfer bypassing HN-F data buffers
  - Latency reduction and bandwidth multiplication
- Key Figures:
  - `images/ch5_read_shared_flow.svg`: Ladder diagram of standard ReadShared via HN-F.
  - `images/ch5_direct_cache_transfer_dct.svg`: Direct Cache Transfer sequence from peer RN-F directly to requestor.

### Coherent Write, Eviction, and Direct Write Transactions
- Store Allocation and Ownership Acquisition: `ReadUnique`, `MakeUnique`, `CleanUnique`
- Non-CopyBack Writes (`WriteNoSnoop`, `WriteUniquePtl`, `WriteUniqueFull`)
- The Write Credit Protocol: Requesting write buffers via `DBIDResp`
- Direct Write-data Transfer (DWT):
  - Streaming write data directly from RN-F to memory controller (SN-F), bypassing HN-F
- CopyBack Eviction Transactions: `WriteEvictFull`, `WriteCleanFull`, `Evict`
- Key Figures:
  - `images/ch6_write_unique_flow.svg`: WriteUnique flow showing DBIDResp write credit and NCBWrData.
  - `images/ch6_dwt_memory_flow.svg`: Direct Write-data Transfer (DWT) routing directly to SN-F.

### Snoop Mechanics, Response Tracking, and Cache Coherency
- Inbound Snoop Dispatch: `SnpShared`, `SnpClean`, `SnpUnique`, `SnpCleanInvalid`, `SnpMakeInvalid`
- Snoop Response Types: `SnpResp`, `SnpRespData`, `SnpRespDataPtl`, `SnpRespDataFwd`
- Home Node Response Aggregation: Tracking multi-core snoop responses
- Cache State Tracking in the Snoop Filter:
  - Unique Clean (UC), Unique Dirty (UD), Shared Clean (SC), Shared Dirty (SD), Invalid (I)
- Resolving Simultaneous Cross-Snoop Races at the Point of Serialization (PoS)
- Key Figures:
  - `images/ch7_snoop_request_response_matrix.svg`: Matrix of inbound snoop types vs cache states and responses.
  - `images/ch7_snoop_race_serialization.svg`: Point of Serialization arbitrating conflicting concurrent requests.

### Retry Mechanisms, Protocol QoS, and Deadlock Avoidance
- What Happens When HN-F Resources are Saturated?
- Protocol-Level Flow Control: The `RetryAck` and Protocol Credit (`PCrd`) Protocol
- Credit Types: Tracker Credits, Request Credits, Snoop Credits
- Quality of Service (QoS) Priority Fields and Throttling
- Protocol Deadlock Avoidance:
  - Virtual Networks (VNETs): REQ, SNP, DAT, RSP separation
  - Physical buffer isolation preventing circular dependency deadlocks
- Key Figures:
  - `images/ch8_retry_pcrd_sequence.svg`: Flow diagram of RetryAck, PCrdGrant, and retried request.
  - `images/ch8_deadlock_free_vnets.svg`: Separation of the 4 independent Virtual Networks.

### Barriers, Atomics, and Distributed Virtual Memory (DVM)
- Hardware Barriers in CHI: Memory Barriers (`ReqOrder`) vs Endpoint Synchronization
- Far-Memory Atomic Transactions:
  - `AtomicStore`, `AtomicLoad`, `AtomicCompare`, `AtomicSwap`
  - Shifting execution from CPU ALU to Home Node / Memory Controller ALU
  - Eliminating cache line bouncing in multi-threaded spinlocks
- Distributed Virtual Memory (DVM) in CHI:
  - Role of the Miscellaneous Node (`MN`)
  - Non-sync vs Sync DVM operations, multi-flit DVM messages
- Key Figures:
  - `images/ch9_atomic_transactions_flow.svg`: Near-memory vs Far-memory atomic execution comparison.
  - `images/ch9_dvm_chi_broadcast.svg`: DVM message routing through the Miscellaneous Node (MN).

### Advanced CHI Features, Verification, and Future Horizons
- Architectural Evolution: From Issue A/B to CHI Issue C, D, E, F, G
  - MPAM (Memory System Resource Partitioning and Monitoring)
  - MTE (Memory Tagging Extension) support in CHI
  - Confidential Compute Architecture (Arm CCA / Realms)
  - 512-bit wide datapath scaling
- Bridging CHI to Compute Express Link (CXL):
  - CHI-to-CXL.cache and CXL.mem protocol bridges
  - Disaggregated memory pooling in cloud data centers
- Verification Strategies: Credit tracking, cache coherence assertions, protocol VIPs
- Key Figures:
  - `images/ch10_chi_spec_evolution.svg`: Timeline and feature matrix of CHI specifications.
  - `images/ch10_chi_to_cxl_bridge.svg`: Architecture bridging on-chip CHI NoC to off-chip CXL fabric.

---

##### Copyright (c) 2026 squared-studio

