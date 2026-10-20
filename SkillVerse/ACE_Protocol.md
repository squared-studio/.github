# ACE Protocol
## 1. [Introduction to Hardware Cache Coherency and AMBA ACE](ACE_Protocol/chapter_00001.md)
  - The Multi-Core Era and the Memory Wall
  - The Cache Incoherency Problem
  - Software-Managed vs. Hardware-Managed Coherency
  - Evolution
  - System-Level Topology
  - Snooping vs. Directory-Based Coherency
  - Chapter Summary
  - Review Questions
## 2. [Cache States and the MOESI / MESI Coherency Model](ACE_Protocol/chapter_00002.md)
  - The Foundations of Cache Line States
  - The Five MOESI Cache States
  - MOESI State Transition Dynamics
  - The Critical Advantage of MOESI Over MESI
  - State Invariants in Coherent Systems
  - Chapter Summary
  - Review Questions
## 3. [ACE Channel Architecture & Signal Dictionary](ACE_Protocol/chapter_00003.md)
  - Expanding the Five AXI Channels into Eight ACE Channels
  - Master-to-Interconnect Extensions on Existing AXI Channels
  - The Three Dedicated Snoop Channels
  - Comprehensive ACE Signal Dictionary
  - Handshake Dependencies and Deadlock Prevention
  - Chapter Summary
  - Review Questions
## 4. [Coherency Domains and Memory Types](ACE_Protocol/chapter_00004.md)
  - The Concept of Coherency Domains
  - The Four AMBA ACE Shareability Domains
  - Mapping Software MMU Attributes to Bus Signals
  - Interconnect Domain Filtering Mechanics
  - Performance and Power Implications
  - Chapter Summary
  - Review Questions
## 5. [Coherent Read and Clean Transactions](ACE_Protocol/chapter_00005.md)
  - Overview of Coherent Read Operations
  - Coherent Read Transaction Types
  - Detailed Transaction Walkthrough
  - Clean Transactions and Cache Maintenance
  - Extended Read Response Signaling (RRESP[3
  - Chapter Summary
  - Review Questions
## 6. [Coherent Write, Eviction, and Make Transactions](ACE_Protocol/chapter_00006.md)
  - The Architecture of Coherent Writes
  - Write Allocation Transactions (ReadUnique and MakeUnique)
  - Coherent Write Transactions on AW and W
  - Eviction Mechanics
  - Write Barrier and Ordering Guarantees
  - Chapter Summary
  - Review Questions
## 7. [Snoop Channel Mechanics & `CRRESP` Response Decoding](ACE_Protocol/chapter_00007.md)
  - The Inbound Snoop Pipeline
  - Detailed Decoding of the CRRESP[4
  - Canonical CRRESP Response Combinations
  - Snoop Handshake Dynamics and Waveforms
  - Resolving Simultaneous Cross-Snooping Races
  - Chapter Summary
  - Review Questions
## 8. [Barrier Transactions and Memory Ordering](ACE_Protocol/chapter_00008.md)
  - The Reality of Relaxed Memory Ordering
  - Barrier Signaling on Address Channels (AxBAR[1
  - Memory Barrier vs. Synchronization Barrier
  - Barrier Scoping via Shareability Domains
  - Step-by-Step Interconnect Execution of Barrier Transactions
  - Deadlock Prevention in Barrier Implementations
  - Chapter Summary
  - Review Questions
## 9. [Distributed Virtual Memory (DVM) and Message Signaling](ACE_Protocol/chapter_00009.md)
  - Virtual Memory in Heterogeneous Multi-Core SoCs
  - The Overhead of Software TLB Shootdown
  - The AMBA ACE DVM Solution
  - DVM Transaction Types and Scopes
  - Two-Beat DVM Message Format over the AR Channel
  - Complete DVM Synchronization Protocol Sequence
  - Chapter Summary
  - Review Questions
## 10. [ACE-Lite and Coherent Interconnect Architecture (CCI)](ACE_Protocol/chapter_00010.md)
  - The Role of ACE-Lite in Heterogeneous SoCs
  - ACE-Lite Interface & Transaction Capabilities
  - Microarchitecture of a Coherent Interconnect
  - Snoop Filters and Duplicate Tag Directories
  - Comparative Case Study
  - The Future of Cache Coherency
  - Chapter Summary
  - Review Questions

##### Copyright (c) 2026 squared-studio

