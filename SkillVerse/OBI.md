# OBI
## 1. [Introduction to Open Bus Interface (OBI) and OpenHW Ecosystem](OBI/chapter_00001.md)
  - The Genesis of the Open Bus Interface (OBI)
  - OBI in the CORE-V Processor Ecosystem
  - Architectural Comparison
  - Fundamental Architectural Principles of OBI
  - Protocol Efficiency and Theoretical Bandwidth
  - Chapter Summary
  - Review Questions
## 2. [Signal Architecture and Channel Decomposition](OBI/chapter_00002.md)
  - The Two-Channel Architecture
  - Complete OBI Signal Dictionary
  - Clocking and Reset Semantics
  - Channel Sizing and Data Width Conventions
  - Chapter Summary
  - Review Questions
## 3. [Handshake Protocols](OBI/chapter_00003.md)
  - The Two Independent Handshakes
  - The Core Protocol Invariant
  - Request Handshake Timing Scenarios
  - Response Phase Latency and Behaviors
  - Cross-Phase Handshake Dependencies and Deadlock Freedom
  - Handshake Rules Summary Matrix
  - Chapter Summary
  - Review Questions
## 4. [Basic Read and Write Transfers](OBI/chapter_00004.md)
  - Anatomy of an OBI Read Transaction
  - Anatomy of an OBI Write Transaction
  - Byte Enable (be) Mechanics and Partial Writes
  - Read-After-Write (RAW) Hazards in OBI Systems
  - Comparison of OBI Read and Write Characteristics
  - Chapter Summary
  - Review Questions
## 5. [Pipelining and Multiple Outstanding Transactions (MOT)](OBI/chapter_00005.md)
  - The Single-Outstanding Throughput Bottleneck
  - Pipelined Streaming
  - In-Flight Transaction Tracking Architecture
  - Master-Side Transaction Order Queue
  - Little's Law and FIFO Depth Sizing
  - Chapter Summary
  - Review Questions
## 6. [Transaction IDs, Routing, and Out-of-Order Execution](OBI/chapter_00006.md)
  - Multi-Master Interconnect Routing
  - Interconnect ID Widening (Prefix Prepending)
  - OBI Ordering Rules
  - Interconnect Pending Transaction Table (PTT)
  - Preserving RISC-V Memory Consistency
  - Chapter Summary
  - Review Questions
## 7. [Atomic Operations (ATOP) and Protection Attributes](OBI/chapter_00007.md)
  - Supporting the RISC-V 'A' Extension in OBI
  - The atop[5
  - Protection Levels and prot[2
  - Hardware Security Firewalls and RISC-V PMP
  - The Debug Access Signal (dbg)
  - Chapter Summary
  - Review Questions
## 8. [Error Reporting, Fault Handling, and Bus Exceptions](OBI/chapter_00008.md)
  - The OBI Error Indicator Signal (err)
  - Root Causes of OBI Bus Errors
  - The Response Completion Invariant
  - Translation to RISC-V Architectural Exceptions
  - Architectural CSR Updates on Trap Entry
  - Chapter Summary
  - Review Questions
## 9. [Interconnect Architecture](OBI/chapter_00009.md)
  - Multi-Master, Multi-Slave OBI Interconnects
  - Fundamental Interconnect Building Blocks
  - The OBI-to-APB4 Peripheral Bridge
  - The OBI-to-AXI4 Interconnect Bridge
  - OBI-to-SRAM Memory Wrappers
  - Chapter Summary
  - Review Questions
## 10. [Verification, Protocol Invariants, and Best Practices](OBI/chapter_00010.md)
  - The Four Fundamental OBI Protocol Invariants
  - Mathematical Formulation of Protocol Invariants
  - OBI Functional Verification Checklist
  - Common Architectural Pitfalls in OBI Design
  - Comprehensive Summary of the OBI Protocol Series
  - Review Questions

##### Copyright (c) 2026 squared-studio

