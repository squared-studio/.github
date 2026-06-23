# Procedural Blocks in SystemVerilog: The Behavioral Modeling Engine

## Introduction

Imagine designing a hardware system where you need to describe not just static connections (like wires), but **how things change over time**—such as a counter incrementing on each clock pulse, a state machine transitioning between modes, or a testbench generating stimulus patterns. This is where **procedural blocks** shine. They are the behavioral modeling constructs in SystemVerilog that let you describe sequential, step-by-step logic execution—much like writing software—but for hardware description and verification.

Unlike continuous assignments (which update instantly when inputs change, like a direct wire connection), procedural blocks execute **in sequence** over simulated time. This makes them indispensable for:

- Modeling sequential elements (flip-flops, registers, memories)
- Creating complex control logic (state machines, FSMs)
- Building verification environments (testbenches, stimulus generators)
- Controlling simulation flow (initialization, cleanup)

Whether you're writing synthesizable RTL or verification code, mastering procedural blocks is fundamental to effective SystemVerilog design.

---

## Initial Blocks: Setting the Stage

Think of an `initial` block as the **opening scene of a play**—it runs exactly once when the simulation begins (at time 0) to set up the initial state, load configurations, and kick off the first actions.

### Key Characteristics

- **One-Time Execution**: Code runs top-to-bottom only once at simulation start.
- **Concurrent Start**: Multiple `initial` blocks begin simultaneously at time 0, but their completion order is **non-deterministic** (depends on simulator scheduling—like actors starting scenes at the same curtain rise but finishing at different times).
- **Testbench-Only**: Not synthesizable; used exclusively in simulation environments for setup and stimulus.

### Common Uses

- Initializing DUT inputs, internal signals, and memory contents
- Generating the first stimulus vectors or configuration sequences
- Opening log files or displaying simulation banners
- Setting up simulation termination conditions (e.g., `#1000 $finish;`)

### Example: Testbench Initialization

```systemverilog
module tb_uart;
  logic clk;
  logic rst_n;
  logic [7:0] tx_data;
  logic tx_start;

  initial begin  // Setup block
    clk = 0;
    rst_n = 0;   // Assert reset
    tx_data = 8'h00;
    tx_start = 0;

    $display("[%0t] Testbench: Initializing UART simulation...", $time);
    #20 rst_n = 1;    // De-assert reset after 20 time units
    #10 tx_data = 8'h55; // Load test data
    #5 tx_start = 1;   // Start transmission
  end

  initial begin  // Termination block (runs concurrently)
    #200 $finish; // End simulation after 200 time units
  end

  // Clock generator (always block, covered later)
  always #5 clk = ~clk;
endmodule
```

**Why this works**: The first `initial` block configures the DUT and sends a stimulus. The second independently manages simulation duration. Both start at time 0 but operate independently—like two crew members preparing different parts of a stage before the show begins.

---

## Final Blocks: The Curtain Call

If `initial` blocks are the opening scene, `final` blocks are the **closing curtain**—they run exactly once when the simulation is about to end, perfect for reporting results, cleaning up resources, and summarizing outcomes.

### Key Characteristics

- **Single Execution**: Runs once after all simulation activity completes (no ongoing processes).
- **Simulation-Exclusive**: Not synthesifiable; used only in testbenches for verification cleanup.
- **Critical for Verification**: Ensures you capture final statistics before the simulator exits.

### Common Uses

- Displaying simulation summary (transaction counts, error rates, coverage)
- Closing log files, waveform dumps, or output data streams
- Reporting pass/fail status based on verification goals
- Releasing simulation-specific resources (handled automatically by most simulators, but good practice to explicitize)

### Example: Simulation Report Generator

```systemverilog
module tb_verification;
  integer pkt_count = 0;
  integer error_count = 0;
  integer log_fd;

  initial begin
    log_fd = $fopen("sim.log", "w");
    $display("[%0t] Verification started.", $time);
    // ... testbench logic that increments pkt_count and error_count ...
  end

  // ... (testbench stimulus, DUT, checkers) ...

  final begin
    $display("\n=== SIMULATION SUMMARY ===");
    $display("[%0t] Total Packets Processed: %0d", $time, pkt_count);
    $display("[%0t] Total Errors Detected: %0d", $time, error_count);

    if (error_count > 0) begin
      $display("[%0t] RESULT: FAILED (%0d errors)", $time, error_count);
    end else begin
      $display("[%0t] RESULT: PASSED", $time);
    end

    $fclose(log_fd);
    $display("[%0t] Log file closed.", $time);
  end
endmodule
```

**Analogy**: Like a stage manager turning off lights and tallying ticket sales after the final bow, `final` blocks ensure you capture the simulation's outcome before the virtual theater empties.

---

## Always Blocks: The Reactive Workhorses

`always` blocks describe **continuously active processes** that react to events or time delays. They are the backbone of RTL design for modeling both combinational and sequential logic. Think of them as diligent workers who constantly monitor specific signals (their _sensitivity list_) and spring into action whenever those signals change.

### Choosing the Right `always` Variant

SystemVerilog provides specialized `always` blocks to prevent common mistakes and clarify intent—like using the right tool for a job (wrench vs. screwdriver).

#### 1. General `always` Block: Time-Driven Processes (Testbenches)

- **Use Case**: Creating free-running signals (clocks, reset sequences) or background tasks in testbenches.
- **How It Works**: Combined with timing controls (`#delay`), it loops continuously, executing statements step-by-step after each delay.
- **Synthesizability**: Rarely synthesizable in RTL (lacks clear event sensitivity); reserve for testbenches.

```systemverilog
module clock_gen;
  output logic clk;

  initial clk = 0;  // Initialize
  always #5 clk = ~clk;  // Toggle every 5 time units → 100MHz clock (period=10)
endmodule
```

**Why `#5`?** Each toggle happens after 5 time units. Low for 5 units, high for 5 units → 50% duty cycle. Total period = 10 units.

#### 2. `always_comb`: Pure Combinational Logic

- **Use Case**: Modeling logic where outputs depend _only_ on current inputs (no memory)—like adders, multiplexers, or decoders.
- **Key Feature**: **Automatic sensitivity list**. The simulator watches _all_ signals read in the block and re-evaluates instantly when any change.
- **Critical Rule**: Use **blocking assignments (`=`)**. This ensures immediate output updates, mimicking real combinational gates (no delay between input change and output update).

```systemverilog
module priority_encoder (
  input  logic [3:0] req,
  output logic [1:0] grant,
  output logic       valid
);
  always_comb begin
    // Blocking assignments for immediate combinational response
    if (req[3]) begin
      grant = 2'b11; valid = 1'b1;
    end else if (req[2]) begin
      grant = 2'b10; valid = 1'b1;
    end else if (req[1]) begin
      grant = 2'b01; valid = 1'b1;
    end else if (req[0]) begin
      grant = 2'b00; valid = 1'b1;
    end else begin
      grant = 2'bxx; valid = 1'b0;  // Default case prevents latches
    end
  end
endmodule
```

**Analogy**: Like a room full of people shouting requests—`always_comb` instantly points to the highest-priority requester the moment anyone speaks up.

#### 3. `always_ff`: Sequential Logic (Flip-Flops & Registers)

- **Use Case**: Modeling memory elements that update only on specific events (clock edges), like counters, shift registers, or state registers.
- **Key Feature**: **Requires explicit sensitivity list**—must include the clock edge (`posedge clk`/`negedge clk`) and any asynchronous resets/set.
- **Critical Rule**: Use **non-blocking assignments (`<=`)**. This models true hardware parallelism: all flip-flops update _simultaneously_ at the clock edge, preventing race conditions.

```systemverilog
module sync_reset_counter (
  input  logic clk,
  input  logic rst_n,  // Active-low async reset
  output logic [3:0] count
);
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      count <= 4'b0000;  // Async reset: immediate override
    end else begin
      count <= count + 1'b1;  // Sync update: happens ONLY at clock edge
    end
  end
endmodule
```

**Why non-blocking?** Imagine a line of people passing a baton. Non-blocking assignments ensure everyone grabs the baton _from the previous person's position at the start of the step_—not from someone who already updated mid-step. This mirrors how real flip-flops sample inputs at the clock edge.

#### 4. `always_latch`: Level-Sensitive Latches (Use Sparingly)

- **Use Case**: Modeling latches (transparent when enabled, holding when disabled)—_rarely recommended in synchronous RTL_.
- **Key Feature**: Infers a latch if outputs aren't assigned in _all_ code paths (e.g., missing `else` in an `if`).
- **Critical Warning**: Latches can cause timing hazards in clocked designs. Prefer `always_ff` for most sequential logic unless your architecture specifically requires level-sensitive behavior.

```systemverilog
module gated_latch (
  input  logic enable,
  input  logic data,
  output logic q
);
  always_latch begin
    if (enable) begin
      q = data;  // Transparent: follows input when enabled
    end
    // MISSING ELSE: When enable=0, q holds previous value (latch behavior)
    // Without explicit hold, synthesis may still infer a latch—but it's unclear!
  end
endmodule
```

**Better Practice**: Explicitly show the hold behavior for clarity and to avoid synthesis mismatches:

```systemverilog
always_latch begin
  if (enable)
    q = data;
  else
    q = q;  // Explicit hold (though q=q is redundant, it documents intent)
end
```

> 💡 **Pro Tip**: In 95% of synchronous designs, you’ll use `always_ff` for sequential logic and `always_comb` for combinational logic. Reserve `always_latch` for rare cases like asynchronous FIFO control logic—and always verify with your team’s coding guidelines.

---

## Blocking vs. Non-Blocking Assignments: The Timing Detail

The assignment type (`=` vs. `<=`) inside procedural blocks controls _when_ updates take effect—critical for modeling hardware accurately.

### Blocking Assignments (`=`): "Do It Now, Then Move On"

- **Behavior**: Execute immediately in sequence. The next statement waits for this to finish.
- **Use Case**:
  - Combinational logic (`always_comb`)
  - Sequential testbench steps (`initial`/`final` blocks)
  - Temporary variables in algorithms
- **Analogy**: Like following a recipe step-by-step—you must finish chopping onions before you can start sautéing them.

```systemverilog
initial begin
  integer a, b, temp;
  a = 5;      // a is 5 immediately
  b = a + 3;  // b becomes 8 (using a's *current* value)
  temp = a;   // temp = 5
  a = b;      // a = 8
  b = temp;   // b = 5 → SWAPPED!
end
```

### Non-Blocking Assignments (`<=`): "Schedule It, Then Keep Going"

- **Behavior**: Schedule the update to occur at the _end_ of the current time step. The procedural block continues immediately.
- **Use Case**:
  - Sequential logic (`always_ff`)—models concurrent register updates
  - When you need to preserve old values during calculation (e.g., swaps, pipelines)
- **Analogy**: Like placing orders at a drive-through—you tell the speaker what you want (schedule), drive to the window (continue), then get your food (update) after everyone ahead has been served.

```systemverilog
initial begin
  logic [1:0] x, y;
  x <= 2'b01;  // Schedule x=01
  y <= x;      // Schedule y=OLD x (which was 00 at start of step), NOT new x!
  #1;
  // After delay: x=01, y=00 → NOT swapped!
end
```

**Key Insight**: In `always_ff`, non-blocking assignments ensure all flip-flops update based on _pre-clock_ values—exactly how real hardware works.

### Assignment Cheat Sheet

| Block Type        | Recommended Assignment | Why                                                              |
| ----------------- | ---------------------- | ---------------------------------------------------------------- |
| `always_comb`     | Blocking (`=`)         | Needs immediate output response to input changes                 |
| `always_ff`       | Non-blocking (`<=`)    | Models concurrent register updates at clock edge                 |
| `initial`/`final` | Blocking (`=`)         | Sequential step-by-step execution (like software)                |
| General `always`  | Context-dependent      | Testbenches often use `=`; avoid in RTL unless timing-controlled |

> ⚠️ **Critical Rule**: **Never mix `=` and `<=` for the same variable in one procedural block.** This creates simulation-dependent races (e.g., scheduling an update then immediately overwriting it).

---

## Best Practices: Writing Clear, Synthesizable, and Reliable Code

Follow these guidelines to avoid common pitfalls and ensure your code simulates and synthesizes as intended.

### 1. Match Block Type to Intent

- **Combinational logic? → `always_comb`**  
  _Why_: Automatic sensitivity prevents forgotten latches; blocking assignments model real gates.
- **Sequential logic? → `always_ff`**  
  _Why_: Explicit sensitivity + non-blocking assignments = accurate flip-flop modeling.
- **Avoid generic `always` in RTL**  
  _Why_: It’s ambiguous (is it comb or seq?) and often unsynthesizable without careful timing controls.

### 2. Prevent Latches in Combinational Logic

Always cover **every possible input condition** for outputs in `always_comb`:

```systemverilog
// BAD: Missing 'else' infers latch when enable=0
always_comb if (enable) out = in;

// GOOD: Explicitly defined for all cases
always_comb out = enable ? in : 1'b0;  // Using ternary operator
// OR
always_comb begin
  if (enable) out = in;
  else        out = 1'b0;              // Explicit else
end
```

### 3. Complete Sensitivity Lists for `always_ff`

Include **all** asynchronous triggers (clock edge + resets/set):

```systemverilog
// GOOD: Captures clock and async reset
always_ff @(posedge clk or negedge rst_n)

// BAD: Missing reset → sim mismatch if reset changes asynchronously
always_ff @(posedge clk)
```

### 4. Consistent Assignment Style Per Block

Pick one assignment type per block and stick to it—especially in `always_ff`/`always_comb`. Mixing causes confusion and bugs.

### 5. Use `default` in `case` Statements

Prevents latch inference in `always_comb`:

```systemverilog
always_comb begin
  case (state)
    S0: next = S1;
    S1: next = S2;
    default: next = S0;  // Covers all unspecified states
  end
end
```

---

## Exercises: Build Your Intuition

1. **Initial Block Ping**  
   Create a testbench with an `initial` block that prints `"Testbench alive!"` at time 0 and `"Testbench signing off!"` at time 50 using `#delay`.

2. **Final Block Calculator**  
   Write a testbench that uses a `final` block to compute and display the average packet latency (sum of latencies / packet count) after simulation ends.

3. **50MHz Clock with Variable Duty Cycle**  
   Design a clock generator using a general `always` block that outputs a 50MHz clock (20ns period) with 30% duty cycle (high for 6ns, low for 14ns).

4. **Combinational Priority MUX**  
   Implement a 4-input priority mux using `always_comb`: `always_comb`` where input 3 has highest priority, input 0 lowest. Output the selected 2-bit data.

5. **Shift Register with Synchronous Enable**  
   Build a 4-bit shift register using `always_ff`: shifts left on `posedge clk` when `enable=1`, holds when `enable=0`. Include synchronous active-high reset.

6. **Enable-Controlled Latch (with Caveats)**  
   Model a latch using `always_latch` that passes `data` to `q` when `enable=1`, holds when `enable=0`. Add a comment explaining why this might be problematic in a clocked design.

7. **Assignment Swap Showdown**  
   Create two modules:
   - **Module A**: Swap two 32-bit variables using blocking assignments in an `initial` block.
   - **Module B**: Attempt the same swap using non-blocking assignments.  
     Display values before/after to observe the behavioral difference.

---

By internalizing these concepts—especially the _why_ behind `always_comb`/`always_ff` and blocking/non-blocking assignments—you’ll write SystemVerilog that’s not only correct but also clear, synthesizable, and verification-friendly. Remember: procedural blocks are your toolkit for describing _behavior over time_. Use them wisely, and your hardware will do exactly what you intend.

##### Copyright (c) 2026 squared-studio
