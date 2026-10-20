# The Five Independent AXI Channels & Signal Dictionary

### Learning Objectives
- Master the architectural separation of the five independent AXI channels.
- Distinguish the signal responsibilities and directionality across Master, Interconnect, and Slave interfaces.
- Explore the complete AXI signal dictionary, including bus widths, standard default values, and functional roles.
- Understand the strict reset and clocking semantics required by the AXI specification (`ACLK`, `ARESETn`).
- Analyze how channel independence enables concurrent, out-of-phase command and data transfers.

---

## The Decoupled Five-Channel Architecture

The cornerstone of the AXI protocol is the complete decoupling of information flow into **five unidirectional channels**. Every transaction is decomposed into an address phase and a data/response phase, each operating with its own flow control.

![The Five Independent AXI Channels](images/ch2_five_channels.svg)

### The Channels:
1. **Write Address Channel (AW):** Transmits control and address information for a write burst from Master to Slave.
2. **Write Data Channel (W):** Transmits payload data beats and byte-lane qualifiers (`WSTRB`) from Master to Slave.
3. **Write Response Channel (B):** Returns the completion status of the write burst from Slave to Master.
4. **Read Address Channel (AR):** Transmits control and start address information for a read burst from Master to Slave.
5. **Read Data Channel (R):** Returns data beats and read completion status from Slave to Master.

Notice a fundamental asymmetry: **The Read Data Channel combines data payload and response status (`RRESP`), whereas the Write operation requires a dedicated Write Response Channel (`B`).** 
Why is this necessary? Because read data flows from slave to master, meaning the slave can effortlessly append status flags (`RRESP`) directly alongside the returned data beats. In contrast, write data travels from master to slave; therefore, the slave requires a separate return path (`B` channel) to acknowledge whether the data was successfully committed to memory.

---

## Signal Directions and Top-Level Interface

Every AXI signal belongs to exactly one channel and possesses a fixed, single-direction transmission path.

![AXI Signal Directions](images/ch2_signal_directions.svg)

---

## Comprehensive Signal Dictionary

The following tables define the standard AXI4 signals across all five channels, as well as global clock and reset signals.

###.1 Global Clock and Reset Signals
| Signal | Direction | Description |
|---|---|---|
| `ACLK` | Input (all) | Global clock source. All signals are sampled on the rising edge of `ACLK`. |
| `ARESETn` | Input (all) | Global active-LOW reset. Asynchronous assertion, synchronous deassertion. |

###.2 Write Address Channel (AW) Signals
| Signal | Direction | Width | Description |
|---|---|---|---|
| `AWID` | M $\rightarrow$ S | `ID_WIDTH` | Identification tag for the write address group. |
| `AWADDR` | M $\rightarrow$ S | `ADDR_WIDTH` | Start address of the write burst (typically 32-bit or 64-bit). |
| `AWLEN` | M $\rightarrow$ S | 8 bits | Burst length. Specifies the number of data beats: Burst length = `AWLEN + 1` (1 to 256 beats). |
| `AWSIZE` | M $\rightarrow$ S | 3 bits | Burst size. Specifies the number of bytes in each data beat: Bytes = $2^{\text{AWSIZE}}$ (1, 2, 4, 8, 16, 32, 64, or 128 bytes). |
| `AWBURST` | M $\rightarrow$ S | 2 bits | Burst type: `00` (FIXED), `01` (INCR), `10` (WRAP), `11` (Reserved). |
| `AWLOCK` | M $\rightarrow$ S | 1 bit | Atomic access attribute: `0` = Normal access, `1` = Exclusive access (AXI4). |
| `AWCACHE` | M $\rightarrow$ S | 4 bits | Memory type and cacheability attributes (Bufferable, Modifiable, Allocate). |
| `AWPROT` | M $\rightarrow$ S | 3 bits | Protection level: Privileged/User, Secure/Non-secure, Instruction/Data. |
| `AWQOS` | M $\rightarrow$ S | 4 bits | Quality of Service identifier (priority indicator). |
| `AWREGION`| M $\rightarrow$ S | 4 bits | Region identifier, allows single slave interface to target multiple physical regions. |
| `AWUSER` | M $\rightarrow$ S | User-defined | Optional user-defined sideband signals. |
| `AWVALID` | M $\rightarrow$ S | 1 bit | Write address valid. Indicates valid write address and control info is present. |
| `AWREADY` | S $\rightarrow$ M | 1 bit | Write address ready. Indicates slave is ready to accept the address. |

###.3 Write Data Channel (W) Signals
| Signal | Direction | Width | Description |
|---|---|---|---|
| `WDATA` | M $\rightarrow$ S | `DATA_WIDTH` | Write data bus (typically 32, 64, 128, 256, 512, or 1024 bits). |
| `WSTRB` | M $\rightarrow$ S | `DATA_WIDTH/8`| Write strobes. Each bit indicates whether the corresponding byte lane contains valid data. |
| `WLAST` | M $\rightarrow$ S | 1 bit | Write last. Asserted HIGH by the master during the final data beat of the write burst. |
| `WUSER` | M $\rightarrow$ S | User-defined | Optional user-defined sideband signals. |
| `WVALID` | M $\rightarrow$ S | 1 bit | Write valid. Indicates that valid write data and strobes are present. |
| `WREADY` | S $\rightarrow$ M | 1 bit | Write ready. Indicates that the slave can accept the write data. |

###.4 Write Response Channel (B) Signals
| Signal | Direction | Width | Description |
|---|---|---|---|
| `BID` | S $\rightarrow$ M | `ID_WIDTH` | Response ID tag. Matches the `AWID` of the transaction being acknowledged. |
| `BRESP` | S $\rightarrow$ M | 2 bits | Write response status: `00` (OKAY), `01` (EXOKAY), `10` (SLVERR), `11` (DECERR). |
| `BUSER` | S $\rightarrow$ M | User-defined | Optional user-defined sideband signals. |
| `BVALID` | S $\rightarrow$ M | 1 bit | Write response valid. Indicates that a valid write response is present. |
| `BREADY` | M $\rightarrow$ S | 1 bit | Write response ready. Indicates that the master can accept the write response. |

###.5 Read Address Channel (AR) Signals
| Signal | Direction | Width | Description |
|---|---|---|---|
| `ARID` | M $\rightarrow$ S | `ID_WIDTH` | Identification tag for the read address group. |
| `ARADDR` | M $\rightarrow$ S | `ADDR_WIDTH` | Start address of the read burst. |
| `ARLEN` | M $\rightarrow$ S | 8 bits | Burst length: Number of data transfers = `ARLEN + 1` (1 to 256 beats in AXI4). |
| `ARSIZE` | M $\rightarrow$ S | 3 bits | Burst size: Bytes per beat = $2^{\text{ARSIZE}}$. |
| `ARBURST` | M $\rightarrow$ S | 2 bits | Burst type: `00` (FIXED), `01` (INCR), `10` (WRAP). |
| `ARLOCK` | M $\rightarrow$ S | 1 bit | Atomic access attribute: `0` = Normal, `1` = Exclusive. |
| `ARCACHE` | M $\rightarrow$ S | 4 bits | Memory type and cache attributes. |
| `ARPROT` | M $\rightarrow$ S | 3 bits | Protection level. |
| `ARQOS` | M $\rightarrow$ S | 4 bits | Quality of Service identifier. |
| `ARREGION`| M $\rightarrow$ S | 4 bits | Region identifier. |
| `ARUSER` | M $\rightarrow$ S | User-defined | Optional user-defined sideband signals. |
| `ARVALID` | M $\rightarrow$ S | 1 bit | Read address valid. Indicates valid read address and control signals. |
| `ARREADY` | S $\rightarrow$ M | 1 bit | Read address ready. Indicates slave is ready to accept the read address. |

###.6 Read Data Channel (R) Signals
| Signal | Direction | Width | Description |
|---|---|---|---|
| `RID` | S $\rightarrow$ M | `ID_WIDTH` | Read ID tag. Matches the `ARID` of the read transaction. |
| `RDATA` | S $\rightarrow$ M | `DATA_WIDTH` | Read data bus. |
| `RRESP` | S $\rightarrow$ M | 2 bits | Read response status for the current data beat. |
| `RLAST` | S $\rightarrow$ M | 1 bit | Read last. Asserted HIGH by slave during the final beat of the read burst. |
| `RUSER` | S $\rightarrow$ M | User-defined | Optional user-defined sideband signals. |
| `RVALID` | S $\rightarrow$ M | 1 bit | Read valid. Indicates valid read data and response are available. |
| `RREADY` | M $\rightarrow$ S | 1 bit | Read ready. Indicates master can accept the read data and response. |

---

## Clock and Reset Semantics

The AXI specification establishes strict invariants governing the relationship between the clock (`ACLK`) and the active-LOW reset (`ARESETn`):

### Reset Assertion
`ARESETn` may be asserted asynchronously by hardware reset generators, but it must be deasserted synchronously with respect to the rising edge of `ACLK`.

### Default Signal Values During Reset
During any clock cycle where `ARESETn` is LOW:
- All Master output `VALID` signals (`AWVALID`, `WVALID`, `ARVALID`) **must be driven LOW**.
- All Slave output `VALID` signals (`RVALID`, `BVALID`) **must be driven LOW**.
- All other payload and control signals (such as `AWADDR`, `WDATA`, `ARLEN`) are considered "don't care" and need not be driven to specific logic levels, minimizing flip-flop reset gate overhead.

### Post-Reset Handshake State
The earliest cycle a master or slave is permitted to assert a `VALID` signal is the first rising clock edge **after** `ARESETn` is observed HIGH. `READY` signals may be asserted HIGH or LOW during or immediately following reset.

---

## Channel Independence and Real-World Concurrency

Because the five channels have distinct physical wires and separate handshake pairs:
- **Write Address before Write Data:** The master can drive `AWVALID` before, during, or after `WVALID`.
- **Write Data before Write Address:** A master with pre-buffered data can assert `WVALID` and transmit write data beats into an interconnect buffer even before the slave accepts `AWVALID`!
- **Simultaneous Read and Write:** A master can stream 256 bytes on `WDATA` to DDR memory while concurrently fetching 256 bytes on `RDATA` from an internal SRAM block.
- **Multiple Outstanding Addresses:** A master can issue 8 consecutive read addresses on `AR` before the first byte of read data arrives on `R`.

---

## Chapter Summary

- AXI establishes five unidirectional channels: **AW**, **W**, **B**, **AR**, and **R**.
- Read operations combine data and status within the **R channel**, while Write operations require a dedicated **B channel** for response acknowledgment.
- Each channel operates using an independent forward `VALID` and reverse `READY` flow control handshake.
- During reset (`ARESETn = 0`), all five `VALID` signals must be driven strictly LOW to prevent spurious transaction launches.
- True channel independence enables overlapping address/data phases, pipelining, and full-duplex throughput.

---

## Review Questions

### Question 1
Why does the AXI protocol provide a separate Write Response Channel (`B`), but no separate Read Response Channel?
<details>
<summary><b>View Answer</b></summary>
In a read transaction, data travels from Slave to Master. The slave can easily encode the response status (`RRESP`) alongside the returned data bits on the same physical channel (`R`). In a write transaction, data travels from Master to Slave. Because the master cannot know whether the slave encountered a bus error or successfully committed the data to memory, the slave must have a dedicated channel (`B`) traveling in the reverse direction to return completion status (`BRESP`).
</details>

### Question 2
What is the legal behavior of `AWREADY` when `ARESETn` is held LOW?
<details>
<summary><b>View Answer</b></summary>
The specification only mandates that `VALID` signals (`AWVALID`, `WVALID`, `BVALID`, `ARVALID`, `RVALID`) must be driven LOW during reset. `READY` signals (`AWREADY`, `WREADY`, `BREADY`, `ARREADY`, `RREADY`) may be driven LOW or HIGH during reset. However, it is standard design practice to drive `READY` LOW to prevent spurious handshakes before the interface fully initializes.
</details>

### Question 3
If an AXI4 master sets `AWLEN = 8'h0F` and `AWSIZE = 3'b011`, how many total bytes will be transferred in the write burst?
<details>
<summary><b>View Answer</b></summary>
- Number of beats = `AWLEN + 1` = $15 + 1 = 16\text{ beats}$.
- Bytes per beat = $2^{\text{AWSIZE}} = 2^3 = 8\text{ bytes/beat}$ (64-bit word).
- Total bytes = $16\text{ beats} \times 8\text{ bytes/beat} = 128\text{ bytes}$.
</details>

### Question 4
Can a master assert `WVALID` and begin transferring data before the slave asserts `AWREADY` to accept the write address?
<details>
<summary><b>View Answer</b></summary>
Yes. In AXI, the Write Address and Write Data channels are decoupled. A master may assert `WVALID` and present write data prior to or concurrently with the address handshake on the AW channel. However, the slave cannot commit the data to memory until it receives the target address.
</details>

---

##### Copyright (c) 2026 squared-studio

