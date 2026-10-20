# UART Protocol
## 1. [Introduction to Serial Communication and UART Architecture](UART_Protocol/chapter_00001.md)
  - Parallel vs. Serial Communication
  - Synchronous vs. Asynchronous Serial Communication
  - The Role of UART in Modern Embedded Systems and SoCs
  - High-Level UART Architecture
  - Communication Topologies
  - Throughput and Framing Efficiency Calculations
  - Chapter Summary
  - Review Questions
## 2. [UART Packet Frame Format and Signaling Mechanics](UART_Protocol/chapter_00002.md)
  - Line Signaling States
  - Complete Anatomy of a UART Packet Frame
  - Parity Modes and Mathematical Encodings
  - The Stop Bit Duration
  - Bit Timing Envelope and Noise Margins
  - Standard UART Frame Nomenclature
  - Chapter Summary
  - Review Questions
## 3. [Baud Rate Generation and Clock Dividers](UART_Protocol/chapter_00003.md)
  - Baud Rate vs. Bit Rate
  - Industry-Standard Baud Rates
  - Baud Rate Generator (BRG) Hardware Architecture
  - Baud Rate Quantization Error Analysis
  - The Maximum Tolerable Baud Rate Error Budget ($\pm 2.5\%$)
  - Fractional Baud Rate Generation
  - Special "Baud-Friendly" Crystal Oscillators
  - Chapter Summary
  - Review Questions
## 4. [Receiver Clock Recovery and Oversampling](UART_Protocol/chapter_00004.md)
  - The Asynchronous Clock Recovery Challenge
  - Metastability and Input Synchronization
  - The 16x Oversampling Architecture
  - Start Bit Detection and False-Start Glitch Filtering
  - Majority-Voting Center Sampling (3-Sample Filtering)
  - Cycle-by-Cycle Receiver State Tracking
  - High-Speed Oversampling
  - Chapter Summary
  - Review Questions
## 5. [Transmitter and Receiver State Machines](UART_Protocol/chapter_00005.md)
  - The Transmitter (TX) Finite State Machine
  - Double-Buffering Mechanics in the Transmitter
  - The Receiver (RX) Finite State Machine
  - Double-Buffering Mechanics in the Receiver
  - State Machine Timing Interaction Matrix
  - Chapter Summary
  - Review Questions
## 6. [Error Detection and Handling](UART_Protocol/chapter_00006.md)
  - The Four Core UART Error Conditions
  - Detailed Analysis of Error Types
  - Register Mapping
  - Error Association in Hardware FIFO Queues
  - Software Error Recovery Flow
  - Chapter Summary
  - Review Questions
## 7. [Flow Control](UART_Protocol/chapter_00007.md)
  - Why Flow Control is Necessary
  - Hardware Flow Control
  - Auto-RTS and Auto-CTS Hardware Engines
  - Software Flow Control
  - Comparison Matrix
  - Legacy Modem Control Signals
  - Chapter Summary
  - Review Questions
## 8. [FIFO Buffering, DMA, and Interrupt Architecture](UART_Protocol/chapter_00008.md)
  - The CPU Overhead Problem in Legacy UARTs
  - 16550 Hardware FIFO Architecture
  - Programmable FIFO Trigger Levels (Watermarks)
  - The Receiver Character Timeout Interrupt
  - Zero-CPU Overhead DMA Subsystems
  - Comparison
  - Chapter Summary
  - Review Questions
## 9. [Physical Layer Standards](UART_Protocol/chapter_00009.md)
  - Logic-Level UART vs. Physical Layer Standards
  - The RS-232 Standard (EIA/TIA-232)
  - The RS-422 Standard (Differential Multidrop)
  - The RS-485 Standard (Differential Multipoint Bus)
  - Bus Termination and Failsafe Biasing
  - Comprehensive Physical Standards Comparison Matrix
  - Chapter Summary
  - Review Questions
## 10. [SoC Integration, APB/AXI Peripheral Wrapping, and Modern Extensions](UART_Protocol/chapter_00010.md)
  - The Standard 16550 UART Register Map
  - Comprehensive Register Reference
  - SoC Peripheral Wrapper Architecture
  - Modern UART Extensions
  - Comprehensive Summary of the UART Protocol Series
  - Review Questions

##### Copyright (c) 2026 squared-studio

