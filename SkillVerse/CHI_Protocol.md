# CHI Protocol
## 1. [Introduction to AMBA 5 CHI & Architecture Evolution](CHI_Protocol/chapter_00001.md)
  - The Multi-Core Scaling Wall and the Death of Parallel Buses
  - The Packetized, Layered Network-on-Chip Paradigm
  - CHI Node Taxonomy
  - High-Level Comparison
  - The System Topology Lifecycle
  - Chapter Summary
  - Review Questions
## 2. [CHI Node Architecture & Network-on-Chip (NoC) Topologies](CHI_Protocol/chapter_00002.md)
  - Microarchitecture of Key CHI Nodes
  - Inside the Fully Coherent Request Node (RN-F)
  - Inside the Fully Coherent Home Node (HN-F)
  - Inside the Subordinate Node (SN-F)
  - Network-on-Chip (NoC) Topologies
  - The 2D Mesh Topology and Dimension-Order Routing
  - Address Hashing and NodeID Slicing
  - Chapter Summary
  - Review Questions
## 3. [Layered Architecture & Packet/Flit Formatting](CHI_Protocol/chapter_00003.md)
  - The Three-Tier Protocol Stack
  - Deep-Dive into Stack Responsibilities
  - What is a Flit? (Flow Control Unit)
  - Physical Link Layer Interface Signals
  - The Four Primary CHI Flit Types
  - Detailed Flit Field Anatomy
  - Chapter Summary
  - Review Questions
## 4. [Credit-Based Flow Control & Link Layer Handshake](CHI_Protocol/chapter_00004.md)
  - The Flaws of Reactive VALID/READY Handshaking
  - Proactive Credit-Based Flow Control (LCRDV)
  - Link Initialization and Credit Exchange
  - Flit Pending Signaling (TXFLITPEND) and Power Optimization
  - Detailed Timing Waveform Analysis
  - Link Deactivation and Low-Power Disconnect
  - Chapter Summary
  - Review Questions
## 5. [Coherent Read Transactions and Direct Data Transfer (DDT)](CHI_Protocol/chapter_00005.md)
  - The Taxonomy of CHI Read Transactions
  - Standard Coherent Read via Home Node (HN-F)
  - Direct Data Transfer (DDT / Direct Cache Transfer - DCT)
  - Cache State Grants via CompData Responses
  - Chapter Summary
  - Review Questions
## 6. [Coherent Write, Eviction, and Direct Write Transactions](CHI_Protocol/chapter_00006.md)
  - The Mechanics of Coherent Writes in CHI
  - Ownership Acquisition
  - Non-CopyBack (NCB) Writes and the DBIDResp Credit Protocol
  - Direct Write-data Transfer (DWT)
  - Eviction and CopyBack Transactions
  - Chapter Summary
  - Review Questions
## 7. [Snoop Mechanics, Response Tracking, and Cache Coherency](CHI_Protocol/chapter_00007.md)
  - The Inbound Snoop Pipeline
  - The Snoop Request and Response Resolution Matrix
  - Snoop Response Flit Semantics
  - Multi-Core Response Aggregation at the Home Node
  - Resolving Cross-Snoop Races at the Point of Serialization
  - Chapter Summary
  - Review Questions
## 8. [Retry Mechanisms, Protocol QoS, and Deadlock Avoidance](CHI_Protocol/chapter_00008.md)
  - Resource Saturation at the Home Node
  - The Protocol-Level Retry Mechanism
  - Quality of Service (QoS) and Dynamic Throttling
  - Virtual Networks (VNETs) & Protocol Deadlock Avoidance
  - The Strict VNET Dependency Hierarchy
  - Chapter Summary
  - Review Questions
## 9. [Barriers, Atomics, and Distributed Virtual Memory (DVM)](CHI_Protocol/chapter_00009.md)
  - Advanced Synchronization in Enterprise Multi-Core
  - Memory Ordering and Hardware Barriers in CHI
  - Near-Memory vs. Far-Memory Atomics
  - CHI Far-Memory Atomics
  - Distributed Virtual Memory (DVM) in AMBA CHI
  - Chapter Summary
  - Review Questions
## 10. [Advanced CHI Features, Verification, and Future Horizons](CHI_Protocol/chapter_00010.md)
  - The Continuous Evolution of the AMBA CHI Specification
  - Architectural Milestones
  - Bridging On-Chip AMBA CHI to Off-Chip Compute Express Link (CXL)
  - System-Level Verification Challenges in CHI Designs
  - Course Conclusion
  - Chapter Summary
  - Review Questions

##### Copyright (c) 2026 squared-studio

