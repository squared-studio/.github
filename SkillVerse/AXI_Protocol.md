# AXI Protocol
## 1. [Introduction to AMBA AXI Protocol and Architecture](AXI_Protocol/chapter_00001.md)
  - The Role of AXI in High-Performance SoC Design
  - The AMBA Protocol Hierarchy
  - Evolution of the AXI Specification
  - Fundamental Architectural Innovations of AXI
  - Bandwidth and Bus Utilization Calculations
  - Chapter Summary
  - Review Questions
## 2. [The Five Independent AXI Channels & Signal Dictionary](AXI_Protocol/chapter_00002.md)
  - The Decoupled Five-Channel Architecture
  - Signal Directions and Top-Level Interface
  - Comprehensive Signal Dictionary
  - Clock and Reset Semantics
  - Channel Independence and Real-World Concurrency
  - Chapter Summary
  - Review Questions
## 3. [Handshake Protocol](AXI_Protocol/chapter_00003.md)
  - Two-Way Handshake Fundamental Mechanics
  - The Three Handshake Timing Scenarios
  - The Core Protocol Invariants
  - Cross-Channel Handshake Dependencies
  - Handshake Dependency Comparison Table
  - Deadlock Scenarios in Interconnect Design
  - Chapter Summary
  - Review Questions
## 4. [Burst Transactions and Address Calculation](AXI_Protocol/chapter_00004.md)
  - Burst Parameters and Encoding
  - The Three AXI Burst Types
  - Mathematical Derivation of WRAP Bursts
  - The Critical 4KB Address Boundary Rule
  - Unaligned Transfers and Write Strobes (WSTRB)
  - Chapter Summary
  - Review Questions
## 5. [Basic Write and Read Transactions](AXI_Protocol/chapter_00005.md)
  - Complete Anatomy of an AXI Write Transaction
  - Complete Anatomy of an AXI Read Transaction
  - Full-Duplex Simultaneous Read and Write Operation
  - Address Pipelining and Outstanding Transactions
  - Comparison of Write and Read Timing Characteristics
  - Chapter Summary
  - Review Questions
## 6. [Response Signaling and Error Handling](AXI_Protocol/chapter_00006.md)
  - The Four AXI Response Types
  - Write Response Semantics (BRESP)
  - Read Response Semantics (RRESP)
  - Slave Error (SLVERR) vs. Decode Error (DECERR)
  - The Burst Completion Invariant
  - System-Level Fault Recovery and CPU Exceptions
  - Chapter Summary
  - Review Questions
## 7. [Transaction Ordering, Multi-Threading, and Out-of-Order Completion](AXI_Protocol/chapter_00007.md)
  - Motivation for Out-of-Order Execution
  - AXI Identification Tags (ID Signals)
  - The Fundamental AXI Ordering Rules
  - Out-of-Order Read Data Interleaving
  - Write Interleaving
  - Interconnect ID Widening (ID Prepending)
  - Chapter Summary
  - Review Questions
## 8. [Advanced Attributes](AXI_Protocol/chapter_00008.md)
  - Memory Attributes and AxCACHE Signaling
  - Standard AxCACHE Memory Encodings
  - Protection Levels and AxPROT (Hardware Firewalls)
  - Quality of Service (AxQOS) Signaling
  - Multiple Region Signaling (AxREGION)
  - Chapter Summary
  - Review Questions
## 9. [Atomic and Exclusive Accesses](AXI_Protocol/chapter_00009.md)
  - Multiprocessor Synchronization
  - Evolution
  - The Exclusive Access Transaction Flow
  - The Exclusive Monitor State Machine
  - Internal vs. External Exclusive Monitors
  - Protocol Restrictions for Exclusive Accesses
  - Chapter Summary
  - Review Questions
## 10. [AXI4-Lite, Bridging, and Interconnect Architecture](AXI_Protocol/chapter_00010.md)
  - The AXI4-Lite Protocol Profile
  - Architectural Comparison
  - Multi-Master, Multi-Slave Crossbar Interconnects
  - Data Width Conversion
  - Clock Domain Crossing (CDC) and Asynchronous Bridges
  - Protocol Bridges
  - Chapter Summary
  - Review Questions

##### Copyright (c) 2026 squared-studio

