# SystemVerilog Built-in System Tasks and Functions: A Practical Guide

SystemVerilog provides a rich set of built-in system tasks and functions (identified by the `$` prefix) that act as your Swiss Army knife for simulation and verification. Think of them as specialized tools that help you control simulation time, manipulate data, generate stimuli, check assertions, collect coverage, and interact with files—all without writing complex low-level code.

This guide focuses on the most practical and commonly used system tasks/functions, explaining them with real-world analogies and clear examples to help you apply them immediately in your verification work.

## ⏱️ Simulation Control: Starting, Stopping, and Pausing

Just like a movie director controls when a film starts, pauses, or ends, these tasks control your simulation's execution flow.

### `$finish`: Gracefully Ending Simulation

**Analogy:** Like calling "That's a wrap!" on a film set—everything wraps up neatly before everyone goes home.

- `$finish;` or `$finish(0);`: Ends simulation quietly (no extra messages)
- `$finish(1);`: Ends simulation and prints when/where it stopped
- `$finish(2);`: Ends simulation with detailed stats (time, memory, CPU usage)

**Example:**

```systemverilog
initial begin
  $display("Starting chip verification at %0t", $time);
  #100ns;  // Simulate for 100 nanoseconds
  $display("Finished basic tests at %0t", $time);
  $finish(2);  // End with full statistics
end
```

### `$stop`: Pausing for Debugging

**Analogy:** Like hitting "pause" on a movie to examine a specific frame—you can inspect values, then resume.

- `$stop;` or `$stop(0);`: Pauses silently
- `$stop(1);`: Pauses and shows time/location
- `$stop(2);`: Pauses with time, location, and resource stats

**Example:**

```systemverilog
initial begin
  $display("Starting debug session at %0t", $time);
  #50ns;
  $display("Checking intermediate state at %0t", $time);
  $stop(1);  // Pause here to inspect signals
  // ... (simulation remains paused until you continue in simulator)
  #50ns;
  $finish;
end
```

### `$exit`: Immediate Termination

**Analogy:** Like pulling the emergency stop on a factory line—immediate halt without cleanup procedures.

Use sparingly (prefer `$finish` for clean shutdowns):

```systemverilog
if (error_count > MAX_ERRORS) begin
  $display("Too many errors! Aborting at %0t", $time);
  $exit(1);  // Exit with error code 1
end
```

## ⏳ Time Functions: Measuring Simulation Time

These functions let you read the current simulation time in different formats—like having multiple clocks on your wall showing different time zones.

### `$realtime`: Precise Time (with Fractions)

Returns time as a floating-point number, respecting your timescale's precision.

- **Returns:** `real` type (e.g., 10.5 for 10.5 time units)

### `$stime`: Integer Time (Truncated)

Returns time as an integer, chopping off any fractional part.

- **Returns:** 32-bit unsigned integer

### `$time`: Scaled Integer Time

Returns time scaled to your timescale's _reference unit_ (not the precision unit).

- **Returns:** 32-bit unsigned integer

**Example with `timescale 1ns / 1ps`:**

```systemverilog
initial begin
  $display("At time 0:");
  $display("  $realtime = %f (precise)", $realtime);  // 0.000000
  $display("  $stime    = %0d (truncated ns)", $stime);  // 0
  $display("  $time     = %0d (scaled to ns)", $time);    // 0

  #10.5;  // Wait 10.5 nanoseconds
  $display("\nAfter #10.5:");
  $display("  $realtime = %f", $realtime);  // 10.500000
  $display("  $stime    = %0d", $stime);      // 10 (0.5 ns truncated)
  $display("  $time     = %0d", $time);       // 10 (10.5 ns scaled to ns = 10.5 → truncated to 10)
end
```

**Key Insight:**

- `$realtime` = time in _precision units_ (ps here) as real number
- `$stime` = time in _time units_ (ns here) as integer (truncated)
- `$time` = time in _reference units_ (ns here) as integer (truncated)

## 🔢 Data Conversion: Between Formats

These functions help you convert between different data representations—like translating between languages.

### Real ↔ Bit Conversion

**Analogy:** Like converting between analog voltage readings and their digital binary representation.

- `$realtobits(real_value)`: Converts a real number to its 64-bit IEEE 754 binary pattern
- `$bitstoreal(64-bit_pattern)`: Converts a 64-bit pattern back to a real number

**Example:**

```systemverilog
initial begin
  real pi = 3.14159;
  bit [63:0] pi_bits;

  pi_bits = $realtobits(pi);  // Get IEEE 754 representation
  $display("Pi as 64-bit hex: %h", pi_bits);  // e.g., 400921fb54442d18

  real pi_back = $bitstoreal(pi_bits);
  $display("Pi restored: %f", pi_back);  // Should be 3.14159
end
```

### Integer ↔ Real Conversion

- `$itor(integer_value)`: Integer to real (e.g., 5 → 5.0)
- `$rtoi(real_value)`: Real to integer (truncates fractional part, e.g., 5.9 → 5)

**Example:**

```systemverilog
initial begin
  integer count = 42;
  real voltage = 3.3;

  real count_as_real = $itor(count);  // 42.0
  integer voltage_as_int = $rtoi(voltage);  // 3 (0.3 truncated)

  $display("Count as real: %f", count_as_real);
  $display("Voltage as int: %0d", voltage_as_int);
end
```

### Signed vs. Unsigned Interpretation

**Analogy:** Like interpreting a byte as either an unsigned number (0-255) or signed two's complement (-128 to 127).

- `$signed(expression)`: Treat bits as signed (two's complement)
- `$unsigned(expression)`: Treat bits as unsigned

**Example:**

```systemverilog
logic [7:0] byte_val = 8'hFF;  // Binary: 11111111

$display("Unsigned: %0d", $unsigned(byte_val));  // 255
$display("Signed:   %0d", $signed(byte_val));    // -1 (two's complement)

// Arithmetic behaves differently:
$display("Unsigned math: %0d", $unsigned(byte_val) + 1);  // 256
$display("Signed math:   %0d", $signed(byte_val) + 1);    // 0 (wraps around)
```

## 🔍 Array Inquiry: Understanding Your Data Structures

These functions help you inspect arrays—critical for writing generic, reusable code.

### Key Array Functions

| Function                    | What It Returns                      | Analogy                                     |
| --------------------------- | ------------------------------------ | ------------------------------------------- |
| `$dimensions(arr)`          | Total dimensions (packed + unpacked) | How many directions you can move in a space |
| `$unpacked_dimensions(arr)` | Unpacked dimensions only             | How many separate arrays you have           |
| `$left(arr, dim)`           | Left index of dimension              | Starting point in a dimension               |
| `$right(arr, dim)`          | Right index of dimension             | Ending point in a dimension                 |
| `$low(arr, dim)`            | Smaller of left/right                | Minimum index                               |
| `$high(arr, dim)`           | Larger of left/right                 | Maximum index                               |
| `$size(arr, dim)`           | Size of specific dimension           | How many elements in that dimension         |
| `$size(arr)`                | Total elements in unpacked dims      | Total "slots" for data                      |

**Example:**

```systemverilog
// 2D unpacked array: 3 rows, 4 columns
int matrix[0:2][0:3];

initial begin
  $display("Dimensions: %0d", $dimensions(matrix));      // 2
  $display("Unpacked dims: %0d", $unpacked_dimensions(matrix)); // 2
  $display("Size of dim 0: %0d", $size(matrix, 0));   // 3 (rows)
  $display("Size of dim 1: %0d", $size(matrix, 1));   // 4 (columns)
  $display("Total elements: %0d", $size(matrix));     // 12 (3*4)

  $display("Row bounds: [%0d:%0d]", $low(matrix,0), $high(matrix,0));  // [0:2]
  $display("Col bounds: [%0d:%0d]", $low(matrix,1), $high(matrix,1));  // [0:3]
end
```

## 🧮 Math Functions: Your Scientific Calculator

SystemVerilog provides common mathematical functions—think of them as having a scientific calculator built into your language.

### Rounding Functions

| Function    | Behavior             | Example           |
| ----------- | -------------------- | ----------------- |
| `$ceil(x)`  | Smallest integer ≥ x | `$ceil(3.2) → 4`  |
| `$floor(x)` | Largest integer ≤ x  | `$floor(3.8) → 3` |

### Exponential & Logarithmic

| Function     | Purpose                  | Example                        |
| ------------ | ------------------------ | ------------------------------ |
| `$pow(b, e)` | b raised to power e      | `$pow(2, 3) → 8`               |
| `$sqrt(x)`   | Square root of x         | `$sqrt(16) → 4`                |
| `$clog2(x)`  | Bits needed for x values | `$clog2(10) → 4` (2^4=16 ≥ 10) |
| `$exp(x)`    | e^x                      | `$exp(1) → 2.718`              |
| `$ln(x)`     | Natural log of x         | `$ln(2.718) → 1`               |
| `$log10(x)`  | Base-10 log of x         | `$log10(100) → 2`              |

### Trigonometric (Radians)

| Function      | Purpose                   | Example                  |
| ------------- | ------------------------- | ------------------------ |
| `$sin(x)`     | Sine of x                 | `$sin(0) → 0`            |
| `$cos(x)`     | Cosine of x               | `$cos(0) → 1`            |
| `$tan(x)`     | Tangent of x              | `$tan(0) → 0`            |
| `$asin(x)`    | Arcsine (-1 to 1)         | `$asin(0) → 0`           |
| `$acos(x)`    | Arccos (-1 to 1)          | `$acos(0) → 1.57` (π/2)  |
| `$atan(x)`    | Arctangent                | `$atan(1) → 0.785` (π/4) |
| `$atan2(y,x)` | Arctan(y/x) with quadrant | `$atan2(1,1) → 0.785`    |

**Practical Example: Clock Period Calculation**

```systemverilog
// Calculate clock period for 100 MHz frequency
parameter real FREQ_MHZ = 100.0;
parameter real PERIOD_NS;

initial begin
  // Period (ns) = 1000 / Frequency (MHz)
  PERIOD_NS = 1000.0 / FREQ_MHZ;
  $display("For %0f MHz clock, period = %0f ns", FREQ_MHZ, PERIOD_NS);

  // Or using log2 to find counter width for N states
  integer states = 16;
  int counter_width = $clog2(states);
  $display("To count %0d states, need %0d-bit counter", states, counter_width);
end
```

## 📊 Bit Vector Analysis: Understanding Your Signals

These functions help you analyze binary patterns—essential for debugging state machines, checking encodings, and detecting unknown values.

### Bit Counting Functions

| Function               | Purpose                 | Example                        |
| ---------------------- | ----------------------- | ------------------------------ |
| `$countones(vec)`      | Number of 1 bits        | `$countones(4'b1010) → 2`      |
| `$countbits(vec, val)` | Count bits matching val | `$countbits(4'b1x0z, 1) → 1`   |
| `$countbits(vec, 1,0)` | Count 1s AND 0s         | `$countbits(4'b1x0z, 1,0) → 2` |

### Encoding Checkers

| Function          | Purpose              | Example                   |
| ----------------- | -------------------- | ------------------------- |
| `$onehot(vec)`    | Exactly one bit is 1 | `$onehot(4'b0010) → 1`    |
| `$onehot0(vec)`   | At most one bit is 1 | `$onehot0(4'b0000) → 1`   |
| `$isunknown(vec)` | Any bit is X or Z    | `$isunknown(4'b10x0) → 1` |

**Practical Example: State Machine Validation**

```systemverilog
typedef enum logic [2:0] {
  S_IDLE = 3'b000,
  S_LOAD = 3'b001,
  S_PROC = 3'b010,
  S_DONE = 3'b011
} state_t;

state_t current_state;

// Check if state encoding is valid (one-hot would be different, but this checks for validity)
always @(posedge clk) begin
  if (!$onehot0(current_state)) begin
    $error("Invalid state encoding detected: %b", current_state);
  end

  // Check for unknown bits (X/Z) which often indicate uninitialized logic
  if ($isunknown(current_state)) begin
    $warning("State contains unknown bits at time %0t", $time);
  end
end
```

## 📢 Messaging: Communication During Simulation

These tasks let you print information, warnings, and errors—your simulation's voice.

### Severity Levels: From Info to Fatal

Think of these as different alert levels in a monitoring system:

| Task       | Severity | When to Use                    | Example                             |
| ---------- | -------- | ------------------------------ | ----------------------------------- |
| `$info`    | Low      | General progress, debugging    | `"Starting test sequence..."`       |
| `$warning` | Medium   | Potential issues, recoverable  | `"Clock frequency outside spec"`    |
| `$error`   | High     | Errors that invalidate results | `"Timeout waiting for acknowledge"` |
| `$fatal`   | Critical | Unrecoverable conditions       | `"Memory allocation failed"`        |

**Example:**

```systemverilog
initial begin
  $info("Testbench initialization complete");

  // Simulate some test activity
  repeat (10) begin
    @(posedge clk);
    if (error_detected) begin
      $warning("Potential issue detected at %0t", $time);
      error_count++;
      if (error_count > 5) begin
        $error("Too many errors (%0d), stopping test", error_count);
        $finish;
      end
    end
  end

  $info("Test completed with %0d warnings", warning_count);
end
```

### Controlling Message Output

You can enable/disable message types globally:

```systemverilog
// Turn off info messages to reduce log noise
$infooff();
// Later, turn them back on for debugging
$infoon();

// Same for warnings/errors
$warningsoff();
$errorsoff();
```

## 📋 Assertion Control: Managing Your Checks

Assertions are properties that must hold true during simulation. These tasks let you control when they're checked and what gets reported.

### Global Assertion Control

| Task          | Effect                                |
| ------------- | ------------------------------------- |
| `$asserton`   | Enable all assertions (default state) |
| `$assertoff`  | Disable all assertions                |
| `$assertkill` | Disable AND clear pending checks      |

### Selective Reporting Control

Control what gets reported when assertions pass/fail:

```systemverilog
// Disable reporting of passing assertions (reduces log noise)
$assertpassoff();
// Re-enable when debugging
$assertpasson();

// Disable reporting of failing assertions (use with caution!)
$assertfailoff();
// Re-enable to see failures
$assertfailon();
```

**Practical Use Case:**
During early development, you might disable assertion reporting to reduce simulation noise, then enable it during regression testing:

```systemverilog
initial begin
  // Start with assertions enabled but quiet
  $asserton;
  $assertpassoff;  // Only see failures

  // Run tests...

  // Before final validation, enable full reporting
  $assertpasson;
  $assertfailon;
end
```

## 📊 Coverage Collection: Measuring Test Thoroughness

Coverage tells you how much of your design your tests have exercised—like measuring how much of a city you've explored.

### Controlling Collection

```systemverilog
// Turn coverage collection on/off
$coverage_control(1);  // Start collecting
$coverage_control(0);  // Stop collecting
```

### Querying Coverage Data

```systemverilog
// Get coverage percentage for a covergroup
real cov_percent = $get_coverage(my_cg);

// Get hit count for a specific bin
int hits = $coverage_get(my_cg.my_bin);

// Get maximum possible hits for a bin
int max_hits = $coverage_get_max(my_cg.my_bin);
```

### Saving and Merging Results

```systemverilog
// Set output file for coverage database
$set_coverage_db_name("my_coverage.ucdb");

// Save current coverage data
$coverage_save("End of regression");

// Load coverage from previous run
$load_coverage_db("run1.ucdb");

// Merge with current run's coverage
$coverage_merge(this, top, "run1.ucdb");
```

## 🎲 Randomization: Generating Stimulus

Create realistic test scenarios with statistical distributions—like using different dice for different games.

### Basic Random Number

```systemverilog
// Get random 32-bit integer
int rand_val = $random;

// Reseed for reproducible sequences
int seed = 123;
rand_val = $random(seed);  // Same sequence every time with seed=123
```

### Statistical Distributions

| Function                           | Distribution          | Use Case                    |
| ---------------------------------- | --------------------- | --------------------------- |
| `$dist_uniform(seed, min, max)`    | Uniform               | Random address within range |
| `$dist_normal(seed, mean, stddev)` | Gaussian (bell curve) | Clock jitter, noise         |
| `$dist_exponential(seed, mean)`    | Exponential           | Packet arrival times        |
| `$dist_poisson(seed, mean)`        | Poisson               | Rare event modeling         |
| `$dist_chi_square(seed, dof)`      | Chi-square            | Statistical testing         |

**Example: Modeling Network Packet Arrivals**

```systemverilog
// Model packet arrivals with average 100ns between packets
int seed = 42;
time time_between_packets;

initial begin
  forever begin
    // Exponential distribution for packet inter-arrival
    time_between_packets = $dist_exponential(seed, 100.0);
    #(time_between_packets);
    $display("Packet arrived at %0t", $time);
    // ... process packet ...
  end
end
```

## 💾 File Operations: Interacting with the Outside World

Read from and write to files—essential for loading test data, saving results, and logging.

### Opening Files

```systemverilog
int file_handle;

// Open for writing (creates/overwrites)
file_handle = $fopen("results.txt", "w");
if (file_handle == 0) begin
  $error("Failed to open results.txt");
  $finish;
end

// Open for appending
file_handle = $fopen("log.txt", "a");

// Open for reading
file_handle = $fopen("input_data.txt", "r");
```

### Writing Data

```systemverilog
// Write formatted data (no newline)
$fwrite(file_handle, "Value: %0d\n", sensor_reading);

// Write with automatic newline
$fdisplay(file_handle, "Timestamp: %0t, Value: %0d", $time, sensor_reading);

// Write binary data
$fwrite(file_handle, "%b", 8'hFF);  // Writes 11111111
```

### Reading Data

```systemverilog
string line;
int value;

// Read line by line
while (!$feof(file_handle)) begin
  if ($fgets(line, file_handle)) begin
    if ($sscanf(line, "VALUE: %d", value)) begin
      $display("Read value: %0d", value);
    end
  end
end

$fclose(file_handle);
```

### File Monitoring: Watch for Changes

```systemverilog
int log_file = $fopen("activity.log", "w");

// Monitor signals and log changes
$fmonitor(log_file, "Time %0t: addr=%0d data=%0h", $time, addr, data);

// Later, stop monitoring to that file
$fclose(log_file);
```

## 💾 Memory Operations: Loading and Dumping Data

Efficiently initialize and inspect memory contents—like loading a program into RAM or taking a memory snapshot.

### Loading Memory from Files

```systemverilog
// Memory array: 256 bytes
logic [7:0] memory[0:255];

// Load binary data (each line = binary number)
$readmemb("firmware.bin", memory);

// Load hex data (each line = hex number)
$readmemh("firmware.hex", memory);

// Load with address offsets
$readmemh("data.txt", memory, 16, 47);  // Load into addresses 16-47
```

**File Format Examples:**

```
// For $readmemb (binary):
@00
10101010
11001100
@10
11110000

// For $readmemh (hex):
@00
AA
CC
@10
F0
```

### Dumping Memory to Files

```systemverilog
// Dump entire memory as binary
$writememb("memory_dump.bin", memory);

// Dump as hex
$writememh("memory_dump.hex", memory);

// Dump specific range
$writememh("partial_dump.hex", memory, 100, 150);
```

**Output Format Example:**

```
@00000000
10101010
11001100
@00000010
11110000
```

## ⚡ Command Line Arguments: Configuring Your Test

Make your testbench flexible without recompiling—like having command-line options for your favorite software.

### Testing for Arguments

```systemverilog
// Check if +FAST_SIM is present
if ($test$plusargs("FAST_SIM")) begin
  $info("Running in fast simulation mode");
  // Reduce delays, skip complex checks
end
```

### Extracting Values

```systemverilog
int test_seed;
string test_name;
real timeout;

// Get values from command line:
//   simv +SEED=42 +TEST=mem_test +TIMEOUT=5.0
$value$plusargs("SEED=%d", test_seed);
$value$plusargs("TEST=%s", test_name);
$value$plusargs("TIMEOUT=%f", timeout);

$info("Running test '%s' with seed %0d, timeout %0f ns",
      test_name, test_seed, timeout);
```

**Example Command Line:**

```bash
./simv +SEED=123 +TEST=ethernet +VERBOSE=1 +TIMEOUT=100.0
```

## 📺 Waveform Dumping: Viewing Signals

Generate VCD (Value Change Dump) files for viewing in waveform tools like GTKWave or Verdi.

### Basic VCD Dumping

```systemverilog
initial begin
  // Specify output file
  $dumpfile("waveform.vcd");

  // Dump specific signals (0 means dump the signal itself, not hierarchy)
  $dumpvars(0, tb.clk, tb.reset, tb.data_in, tb.data_out);

  // Or dump everything in this scope
  $dumpvars(0);
end
```

### Controlling Dump During Simulation

```systemverilog
initial begin
  $dumpfile("signals.vcd");
  $dumpvars(0, clk, reset, data);

  // Start dumping
  $dumpon;

  // ... run some tests ...

  // Temporarily stop dumping (saves space)
  $dumpoff;

  // ... skip uninteresting period ...

  // Resume dumping
  $dumpon;

  // ... continue testing ...

  // Final snapshot of all values
  $dumpall;

  $finish;
end
```

## 🎯 Best Practices & Tips

1. **Start Simple:** Begin with `$display`, `$stop`, and `$finish` for basic debugging
2. **Use Severity Levels:** Reserve `$error`/`$fatal` for real problems; use `$info`/`$warning` for diagnostics
3. **Leverage Randomization:** Use distribution functions for realistic stimulus instead of purely random values
4. **Automate Checking:** Use assertions and coverage to automate verification rather than just watching waves
5. **Keep Logs Clean:** Use `$infooff`/`$assertpassoff` during routine runs, enable for debugging
6. **Seed Your Randomness:** Always use seeds for reproducible random stimulus in regression tests
7. **Check File Operations:** Always verify `$fopen` succeeded before reading/writing
8. **Use Time Wisely:** Choose `$realtime` for precision timing, `$time` for scaled comparisons

## 🔚 Conclusion

SystemVerilog's system tasks and functions are powerful tools that, when used effectively, can dramatically improve your verification productivity. They provide standardized ways to:

- Control simulation execution
- Analyze and manipulate data
- Generate realistic stimuli
- Check design properties
- Measure test thoroughness
- Interact with the outside world

By mastering these tools, you'll spend less time writing boilerplate code and more time focusing on the actual verification challenges of your design.

> 💡 **Pro Tip:** Keep this guide handy as a reference, but the best way to learn is by doing! Try incorporating one or two new system tasks/functions into your next testbench and see how they simplify your verification workflow.

---

_Remember: These tools are meant to serve your verification goals—not complicate them. Start with what solves your immediate problem, then gradually expand your toolkit as needed._

##### Copyright (c) 2026 squared-studio
