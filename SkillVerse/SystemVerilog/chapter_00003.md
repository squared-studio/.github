# SystemVerilog Built-in Tasks and Functions: Your Simulation Toolkit

SystemVerilog provides powerful built-in system tasks and functions that act as your essential toolkit for debugging, simulation control, and waveform analysis. Think of them as the multimeter, oscilloscope, and control panel of your verification environment—helping you observe, measure, and manage your design's behavior during simulation. This chapter explores these utilities with clear explanations, practical analogies, and hands-on examples to build your confidence from the ground up.

## **Display Tasks: Talking to Your Simulation**

Display tasks let your simulation "speak" back to you by printing messages and variable values. They're crucial for understanding _what_ your design is doing and _when_.

### **1. `$display`: Your Instant Message Logger**

`$display` works like a `print` statement in software—it outputs text **immediately** when executed. Use it for logging events, checking values at specific moments, or getting quick feedback.

#### **Key Format Specifiers** (Control how data appears):

| Specifier | Meaning         | Use Case                                      |
| --------- | --------------- | --------------------------------------------- |
| `%t`      | Simulation time | Timestamp events (e.g., _"Error at 100ns"_)   |
| `%d`      | Decimal integer | Show counter values, register contents        |
| `%b`      | Binary          | Inspect individual bits (e.g., bus states)    |
| `%h`      | Hexadecimal     | Compact view of addresses/data (e.g., `0xAF`) |

#### **Example: Debugging a Counter**

```systemverilog
module counter_debug;
  reg [3:0] count = 0;

  initial begin
    // Print time, decimal value, and binary/hex equivalents
    $display("[%0t ns] Count = %0d (0b%b, 0x%h)", $time, count, count, count);

    // Simulate counting
    repeat (5) begin
      #10 count = count + 1;
      $display("[%0t ns] Count incremented to %0d", $time, count);
    end
  end
endmodule
```

**Typical Output** (simulator-dependent timing):

```
[0 ns] Count = 0 (0b0000, 0x0)
[10 ns] Count incremented to 1
[20 ns] Count incremented to 2
[30 ns] Count incremented to 3
[40 ns] Count incremented to 4
[50 ns] Count incremented to 5
```

> 💡 **Why `%0t`?** The `0` in `%0t` suppresses leading zeros (e.g., prints `10` instead of `0000000010`), making time stamps cleaner.

### **2. `$monitor`: Your Automatic Variable Watchdog**

`$monitor` acts like a vigilant assistant that **watches specified variables** and prints an update **whenever any of them change**. It’s perfect for tracking signal evolution over time without cluttering your code with manual `$display` calls.

#### **Key Rules**:

- Only **one `$monitor` can be active** at a time (a new call replaces the old one).
- Use `$monitoron` to resume monitoring and `$monitoroff` to pause it temporarily (useful during reset sequences).

#### **Example: Tracking a Handshake Protocol**

```systemverilog
module handshake_monitor;
  reg req, ack;

  initial begin
    // Start monitoring: print when req OR ack changes
    $monitor("[%0t ns] REQ=%b, ACK=%b", $time, req, ack);

    // Simulate handshake: request → wait for ack → reset
    req = 0; ack = 0;  // Initial state (time 0)
    #5 req = 1;        // Assert request
    #5 ack = 1;        // Slave responds with ack
    #5 req = 0;        // Deassert request
    #5 ack = 0;        // Slave deasserts ack
    #5 $monitoroff;    // Stop monitoring
    #5 req = 1;        // Change ignored (monitor is off)
  end
endmodule
```

**Output**:

```
[0 ns] REQ=0, ACK=0
[5 ns] REQ=1, ACK=0
[10 ns] REQ=1, ACK=1
[15 ns] REQ=0, ACK=1
[20 ns] REQ=0, ACK=0
```

> 💡 **Analogy**: Like a security camera that only records when motion is detected—`$monitor` saves simulator output by triggering _only_ on changes.

### **3. `$strobe`: Capturing the Final Stable Value**

`$strobe` is like a camera shutter that clicks **at the very end of a simulation time step**, after all non-blocking assignments (`<=`) have settled. Use it when you need the _definitive_ value after concurrent updates—critical for clocked logic.

#### **Why It Matters: Blocking vs. Non-blocking**

- **Blocking (`=`)**: Takes effect _immediately_ (like sequential code).
- **Non-blocking (`<=`))**: Scheduled to take effect _at the end_ of the current time step (models parallel hardware updates).

#### **Example: Avoiding Race Conditions**

```systemverilog
module strobe_demo;
  reg state;

  initial begin
    state = 0;          // Blocking: state becomes 0 NOW
    state <= 1;         // Non-blocking: state will become 1 LATER (end of time step)

    // $display sees the *immediate* value (0)
    $display("[$0t ns] Display sees state = %0d (non-blocking not settled)", $time, state);

    // $strobe sees the *final* value after non-blocking settles (1)
    $strobe("[$0t ns] Strobe sees state = %0d (after non-blocking resolves)", $time, state);

    #1 $finish;
  end
endmodule
```

**Output**:

```
[0 ns] Display sees state = 0 (non-blocking not settled)
[0 ns] Strobe sees state = %0d (after non-blocking resolves) 1
```

> 💡 **Think of it**: In a relay race, `$display` checks the baton position _as runners pass it_, while `$strobe` waits until _all runners have finished their leg_ and the baton is firmly in hand.

#### **When to Use Which Display Task?**

| Task       | Best For                                         | Analogy                                          |
| ---------- | ------------------------------------------------ | ------------------------------------------------ |
| `$display` | Instant checks, logging specific events          | Taking a snapshot with a phone                   |
| `$monitor` | Continuous tracking of changing signals          | Setting up a motion-activated camera             |
| `$strobe`  | Verifying stable values after concurrent updates | Waiting for a circuit to settle before measuring |

---

## **Wavedump Tasks: Visualizing Signal Behavior**

Waveform viewers (like GTKWave or Verdi) turn signal changes into intuitive graphs—your oscilloscope for digital logic. VCD (Value Change Dump) files are the standard format these tools read.

### **1. `$dumpfile`: Naming Your Waveform Log**

This task simply sets the **filename** for the VCD file (e.g., `"design_wave.vcd"`). Call it _before_ `$dumpvars`.

### **2. `$dumpvars`: Choosing What to Record**

This controls **which signals** get saved to the VCD file. You can dump:

- **Everything**: `$dumpvars(0, top_module)` → Records all signals in `top_module` and below.
- **Specific levels**: `$dumpvars(2, module)` → Records signals in `module` and its direct instances (level 2 = top + 1 deeper).
- **Single signal**: `$dumpvars(1, signal_name)` → Records only that signal.

#### **Example: Selective Dumping for Focused Debugging**

```systemverilog
module cpu_top;
  reg clk, reset;
  wire [31:0] pc, instruction;
  // ... CPU datapath and control logic ...

  initial begin
    $dumpfile("cpu_debug.vcd");
    // Dump ONLY the program counter and instruction (top-level, level 1)
    $dumpvars(1, cpu_top.pc);
    $dumpvars(1, cpu_top.instruction);

    // Simulate a few instructions
    clk = 0; reset = 1;
    #10 reset = 0;
    #50 $finish;
  end
endmodule
```

> 💡 **Why be selective?** Dumping everything in a large design creates huge VCD files. Targeting key signals (like `pc` and `instruction` here) keeps files small and analysis fast—like using a magnifying glass only on the suspect area of a circuit board.

#### **After Simulation: Viewing Waveforms**

1. Run your simulation (generates `cpu_debug.vcd`).
2. Open the VCD file in GTKWave (free) or your simulator’s waveform viewer.
3. You’ll see:
   - A clock trace toggling every 10ns.
   - `reset` deasserting at 10ns.
   - `pc` and `instruction` updating on clock edges.

> 🌐 **Real-World Tip**: Always start with selective dumping. If you need more signals later, adjust `$dumpvars` and re-simulate—it’s faster than sifting through irrelevant data.

---

## **Time-Related Functions: Measuring Simulation Progress**

These functions let you read the current simulation time in different formats—essential for timing analysis and logging.

### **1. `$time`: The 64-Bit Workhorse (Recommended)**

Returns time as a **64-bit integer**—plenty of precision for any practical simulation (can handle >500 years at 1ns resolution!). Use this for 99% of cases.

#### **Example: Measuring Delay Accuracy**

```systemverilog
initial begin
  #7.5ns; // Delay 7.5 nanoseconds
  $display("Sim time: %0t ns", $time); // Output: "Sim time: 7 ns" (if timescale is 1ns/1ps)
  $display("Real time: %0f ns", $realtime); // Output: "Real time: 7.500000 ns"
end
```

> ⚠️ **Note**: `$time` truncates fractional time (shows `7` not `7.5`). The `ns` unit comes from your `timescale` directive (e.g., `timescale 1ns/1ps`).

### **2. `$stime`: The 32-Bit Legacy Function (Use with Caution)**

Returns time as a **32-bit integer**—risky for long simulations! It wraps around after ~4.29 seconds at 1ns resolution (2³² ns ≈ 4.29s). **Prefer `$time`** unless you have a specific performance need confirmed by your simulator vendor.

### **3. `$realtime`: For Fractional Precision**

Returns time as a **floating-point real number**—essential when you need to see _exact_ fractional delays (e.g., 7.5ns).

#### **Example: Logging Jitter**

```systemverilog
initial begin
  forever begin
    #5.125ns clk = ~clk; // Clock with 5.125ns half-period
    $display("[%0t] Clk edge (real=%0.3f ns)", $time, $realtime);
  end
end
```

**Snippet of Output**:

```
[0] Clk edge (real=0.000 ns)
[5] Clk edge (real=5.125 ns)
[10] Clk edge (real=10.250 ns)
[15] Clk edge (real=15.375 ns)
```

> 💡 **When to use**: Only when fractional time matters (e.g., PLL modeling, high-speed serial links). For most RTL, `$time` suffices.

---

## **Simulation Control Tasks: Directing the Simulation Flow**

These tasks manage when your simulation runs, pauses, or stops—like the play/pause/stop buttons on your debugger.

### **1. `$finish`: The Graceful Shutdown**

Ends the simulation cleanly (like selecting "Stop" in your simulator’s GUI). Code after `$finish` **won’t execute**. Use it to mark test completion or handle fatal errors.

#### **Example: Self-Checking Testbench**

```systemverilog
initial begin
  // Apply stimulus, check results...
  if (error_count == 0) begin
    $display("✅ TEST PASSED: 0 errors");
    $finish; // Normal termination
  end else begin
    $display("❌ TEST FAILED: %0d errors", error_count);
    $finish(1); // Non-zero exit code signals failure to OS
  end
end
```

> 💡 **Pro Tip**: `$finish(N)` returns exit code `N` to the operating system (useful in automated regression scripts).

### **2. `$stop`: The Interactive Pause Button**

Halts simulation but keeps the simulator alive—you can inspect variables, then resume (e.g., with `run -continue` in ModelSim). Ideal for debugging unexpected behavior.

#### **Example: Catching a Glitch**

```systemverilog
initial begin
  #100ns; // Let design run for a bit
  if (suspicious_signal === 1'bx) begin
    $display("🔍 UNKNOWN DETECTED at %0t ns—pausing for inspection", $time);
    $stop; // Now check: why is this signal X?
  end
end
```

> 🛑 **Remember**: In batch scripts (non-interactive sims), `$stop` may act like `$finish`. Check your simulator’s docs.

### **3. `$exit`: The Emergency Brake (Use Rarely)**

Forces _immediate_ simulator termination—bypassing cleanup steps. **Only use** for unrecoverable errors (e.g., heap corruption). In normal testing, **`$finish` is almost always better**.

#### **When `$exit` Might Be Necessary**

```systemverilog
initial begin
  if ($test$plusargs("FAST_EXIT")) begin
    $display("⚡ Forcing early exit per command-line arg");
    $exit; // Skip remaining testbenches in regression
  end
end
```

> ⚠️ **Warning**: `$exit` can leave files unsaved or resources locked. Default to `$finish` unless you know your simulator handles `$exit` safely.

#### **Control Task Cheat Sheet**

| Task      | When to Use                                 | Risk Level |
| --------- | ------------------------------------------- | ---------- |
| `$finish` | Normal test end, expected errors            | ✅ Safe    |
| `$stop`   | Interactive debugging (pauses safely)       | ⚠️ Low\*   |
| `$exit`   | Simulator crash recovery, forced early quit | ❌ High    |

> \*Low risk in GUI/interactive mode; may terminate abruptly in batch mode.

---

## **Hands-On Exercises: Build Your Intuition**

### **Exercise 1: Format Mastery**

_Predict the output:_

```systemverilog
initial begin
  $display("Time=%0t, Hex=%0h, Bin=%b", $time, 16'd255, 8'ha5);
end
```

<details>
<summary>Solution</summary>
`Time=0, Hex=00ff, Bin=10100101` (Assuming time starts at 0)
</details>

### **Exercise 2: `$monitor` vs. `$display`**

_Why does this print only two lines?_

```systemverilog
initial begin
  $monitor("A=%b, B=%b", a, b);
  a = 0; b = 0;
  #5 a = 1;
  #5 b = 1;
  #5 $monitoroff;
  #5 a = 0; // No output!
end
```

<details>
<summary>Solution</summary>
`$monitor` prints on *any change* to `a` or `b`:
- T=0: `A=0, B=0` (initial)
- T=5: `A=1, B=0` (a changed)
- T=10: `A=1, B=1` (b changed)
- After `$monitoroff`, changes to `a` (T=15) are ignored.
</details>

### **Exercise 3: `$strobe` in Action**

_Fix this to show the correct AND result:_

```systemverilog
module and_gate;
  reg x, y;
  wire z = x & y;

  initial begin
    x = 0; y = 0;
    #5 x = 1; y = 1; // Both change at T=5
    $display("T=%0t: z=%b (too early!)", $time, z); // Might show 0
    // Add $strobe here to see the stable value
  end
endmodule
```

<details>
<summary>Solution</summary>
Insert after `$display`:
```systemverilog
$strobe("T=%0t: z=%b (stable!)", $time, z);
```
Output order may vary, but `$strobe` *will* show `z=1`.
</details>

### **Exercise 4: Waveform Focus**

_How would you record only the `reset` and `clk` signals in a module `testbench`?_

<details>
<summary>Solution</summary>
```systemverilog
initial begin
  $dumpfile("focus.vcd");
  $dumpvars(1, testbench.reset); // Level 1 = top-level signals
  $dumpvars(1, testbench.clk);
end
```
</details>

### **Exercise 5: Time Function Choice**

_Which function should you use to log simulation duration in a regression script, and why?_

<details>
<summary>Solution</summary>
`$time`—it’s 64-bit (no wrap-around risk for any realistic simulation) and sufficient for millisecond/nanosecond precision needs.
</details>

---

## **Why This Matters: The Verification Mindset**

Mastering these tasks isn’t just about memorizing syntax—it’s about developing a **debugger’s intuition**:

- **`$display`/`$monitor`/`$strobe`** → Your _ears_ and _eyes_ during simulation (what’s happening _now_).
- **Waveform dumping** → Your _oscilloscope_ (how signals evolve *relate to simulation flow control tasks → Your *steering wheel* (is, and emergency brake**. Remember**: The best verification engineers don’t just run simulations—they *interrogate\* them. Use these tools to ask:
  > *“What value do I expect here? When should it change? What does the waveform *really* show?”*  
  > Every `$display` is a question; every waveform trace is an answer waiting to be interpreted.

---

**Next Steps**: Try modifying the examples above—break them on purpose, then fix them using the right display/task. True understanding comes from _seeing_ how these tools respond to your design’s behavior. Happy verifying! 🚀

##### Copyright (c) 2026 squared-studio
