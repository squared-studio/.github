# SystemVerilog Command Line Arguments: Parameterizing Simulations for Flexibility

## Introduction: Tailoring Simulation Behavior from the Command Line

Imagine you're testing a car engine. Instead of rebuilding the engine for every test (different fuel types, RPM ranges, or load conditions), you adjust dials on the test bench. SystemVerilog command line arguments work similarly—they let you tweak simulation behavior _without_ recompiling code. This flexibility is essential for efficient verification, allowing you to:

- **Adjust simulation parameters** (like data widths or test durations) on the fly
- **Select specific test cases** for targeted verification (e.g., "run only the memory stress test")
- **Control debug output** verbosity to focus on relevant information
- **Configure file paths** for inputs/outputs, making simulations portable across environments

By treating command line arguments as adjustable dials, verification engineers create reusable testbenches that adapt to diverse verification scenarios.

## Accessing Command Line Arguments

SystemVerilog provides two key system functions to access arguments passed when launching the simulator (e.g., `vcs`, `questa`, `xcelium`). Arguments follow the format `+NAME=value` or `+FLAG` (for boolean switches).

### `$value$plusargs`: Extracting Argument Values

Use this function when you need to _retrieve a value_ from an argument (like a test name or number). It searches for arguments matching `+KEYWORD=value` and extracts the `value` into your variables.

**Syntax:**

```systemverilog
result = $value$plusargs("KEYWORD=%format", variable);
```

- **`result`**: Returns the number of variables successfully assigned (1 if found, 0 if not)
- **`KEYWORD`**: The argument name to match (e.g., `TESTCASE`)
- **`%format`**: Specifies how to interpret the value (`%s` for string, `%d` for integer)
- **`variable`**: Where the extracted value is stored

**Example: Configuring Test Parameters**

```systemverilog
module flexible_testbench;
  string test_name;
  integer loop_count;

  initial begin
    // Try to get test name; defaults to "baseline" if not provided
    if ($value$plusargs("TESTCASE=%s", test_name) == 0) begin
      test_name = "baseline";
      $display("INFO: No TESTCASE given. Using default: %s", test_name);
    end else begin
      $display("INFO: Running test: %s", test_name);
    end

    // Get iteration count; defaults to 5 if missing or invalid
    if ($value$plusargs("ITERATIONS=%d", loop_count) == 0) begin
      loop_count = 5;
      $display("INFO: No ITERATIONS given. Using default: %0d", loop_count);
    end else if (loop_count < 1) begin
      $error("FATAL: ITERATIONS must be ≥1. Got %0d", loop_count);
      $fatal(1);
    end

    // Simulate using test_name and loop_count
    repeat (loop_count) begin
      $display("Executing %s...", test_name);
      #10ns; // Simulate some work
    end
  end
endmodule
```

**Run it:**

```bash
# Uses defaults (TESTCASE="baseline", ITERATIONS=5)
vcs flexible_testbench.sv

# Custom test and iterations
vcs +TESTCASE=pcie_link_train +ITERATIONS=20 flexible_testbench.sv
```

> 💡 **Analogy**: Think of `$value$plusargs` like a vending machine: you insert a coin (command line argument) specifying _what_ you want (TESTCASE) and _how much_ (ITERATIONS), and it dispenses the correct selection.

### `$test$plusargs`: Checking Argument Presence

Use this for _flag arguments_ (simple on/off switches) where you only care if the argument exists—not its value. Ideal for enabling debug modes or optional features.

**Syntax:**

```systemverilog
found = $test$plusargs("FLAG"); // Returns 1 if +FLAG exists, else 0
```

**Example: Controlling Debug Verbosity**

```systemverilog
module debug_control;
  bit debug_enabled;

  initial begin
    debug_enabled = $test$plusargs("DEBUG"); // 1 if +DEBUG present, else 0

    if (debug_enabled) begin
      $display("DEBUG: Verbose logging activated.");
      // ... detailed debug statements ...
    end else begin
      $display("INFO: Running in summary mode.");
      // ... minimal output ...
    end
  end
endmodule
```

**Run it:**

```bash
# Summary mode (default)
vcs debug_control.sv

# Debug mode
vcs +DEBUG debug_control.sv
```

> 💡 **Tip**: Flags like `+DEBUG` act like a "master switch"—they turn entire debugging subsystems on/off without changing code.

## Parameter Overriding via Command Line

You can directly override module parameters (e.g., `DATA_WIDTH`, `ADDR_SIZE`) using command line arguments. This avoids recompiling when testing different configurations.

**How it works**:  
The simulator looks for arguments matching `+MODULE_NAME.PARAMETER=value` and overrides _that specific instance_'s parameter.

**Example: Overriding a Memory Module's Width**

```systemverilog
module memory #(parameter WIDTH = 32) (
  input  logic [WIDTH-1:0] wdata,
  output logic [WIDTH-1:0] rdata
);
  assign rdata = wdata; // Simple pass-through for demo
endmodule

module testbench;
  memory mem_inst (); // Instance to be overridden

  initial begin
    $display("Memory instance WIDTH = %0d", mem_inst.WIDTH);
  end
endmodule
```

**Run it:**

```bash
# Uses default WIDTH=32
vcs testbench.sv

# Overrides WIDTH for mem_inst to 64
vcs +memory.WIDTH=64 testbench.sv
```

> ⚠️ **Note**: Only instances _without_ explicit parameter overrides (like `#(.WIDTH=16)`) can be modified via command line. Explicitly set parameters (e.g., `memory #(.WIDTH=16) inst;`) take precedence.

## Best Practices for Robust Command Line Handling

Follow these guidelines to create maintainable, user-friendly simulations:

1. **Use self-documenting names**  
   → `+TCP_TIMEOUT_MS=5000` (clear) vs `+T=5000` (cryptic)  
   _Analogy: Like labeling control knobs on equipment—"Gain" is better than "G"._

2. **Always provide sensible defaults**  
   → Ensures simulations run immediately out-of-the-box, while allowing customization.

3. **Validate inputs rigorously**  
   → Check ranges (e.g., `if (timeout < 10) $error("Timeout too low!");`)  
   → Verify enum values (e.g., `if (mode inside {NORMAL, FAST, TURBO}) ...`)

4. **Distinguish warning vs. error severity**  
   → `$warning`: Non-blocking issue (e.g., "Using default clock period")  
   → `$error` + `$fatal`: Blocks simulation on critical misconfiguration (e.g., invalid file path)

5. **Document all arguments centrally**  
   → Maintain a `README` or header comment listing:  
    _Argument_ | _Purpose_ | _Format_ | _Default_  
    `----------|-----------|----------|---------`  
    `TESTCASE` | Test to run | `+TESTCASE=<name>` | `regression`  
    `VERBOSE` | Enable debug logs | `+VERBOSE` | `off`

## Error Handling: Making Simulations Foolproof

Proactive validation prevents cryptic failures. Here’s a robust pattern:

```systemverilog
module resilient_config;
  string config_file;
  integer max_cycles;
  bit enable_coverage;

  initial begin
    // 1. Get config file path (with default)
    if ($value$plusargs("CONFIG=%s", config_file) == 0) begin
      config_file = "default.cfg";
      $display("INFO: Using default config: %s", config_file);
    end

    // 2. Get and validate max cycles
    if ($value$plusargs("CYCLES=%d", max_cycles) == 0) begin
      max_cycles = 1000;
      $display("INFO: No CYCLES given. Using %0d", max_cycles);
    end else if (max_cycles < 100 || max_cycles > 1_000_000) begin
      $error("FATAL: CYCLES must be between 100 and 1,000,000. Got %0d", max_cycles);
      $fatal(1);
    end

    // 3. Check coverage flag
    enable_coverage = $test$plusargs("COVERAGE");
    if (enable_coverage) $display("INFO: Coverage collection enabled.");

    // 4. Validate config file accessibility
    int fd = $fopen(config_file, "r");
    if (fd == 0) begin
      $error("FATAL: Cannot open config file: %s", config_file);
      $fatal(1);
    end
    $fclose(fd);

    // Proceed with validated configuration
    $display("=== SIM START ===");
    $display("Config: %s | Cycles: %0d | Coverage: %s",
             config_file, max_cycles, enable_coverage ? "ON" : "OFF");
  end
endmodule
```

**Key validation steps:**

- ✅ **Defaults for optional args** (`CONFIG`, `CYCLES`)
- ✅ **Range checks** (`CYCLES` must be 100–1,000,000)
- ✅ **File existence check** (prevents silent failures later)
- ✅ **Clear error messages** guiding user correction

## Practical Exercises: Build Your Skills

### Exercise 1: Parameterizable FIFO Tester

**Goal**: Create a FIFO testbench where `DATA_WIDTH` and `DEPTH` are set via command line.  
**Steps**:

1. Define a FIFO module with parameters `DATA_WIDTH` (default 8) and `DEPTH` (default 16).
2. In the testbench, instantiate the FIFO.
3. Use `+FIFO.DATA_WIDTH` and `+FIFO.DEPTH` to override parameters.
4. Display the actual width/depth used at simulation start.
5. Test with:
   - `vcs fifo_tb.sv` (defaults)
   - `vcs +FIFO.DATA_WIDTH=32 +FIFO.DEPTH=256 fifo_tb.sv`

### Exercise 2: Smart Test Case Dispatcher

**Goal**: Run specific tests based on `+TESTCASE` with validation.  
**Steps**:

1. Implement three test tasks: `test_reset()`, `test_burst()`, `test_timeout()`.
2. Use `$value$plusargs("TESTCASE=%s", name)` to get the test name.
3. Validate against allowed values (`reset`, `burst`, `timeout`).
4. On invalid input:
   ```systemverilog
   $error("FATAL: Invalid TESTCASE '%s'. Allowed: reset, burst, timeout", name);
   $fatal(1);
   ```
5. Test with valid/invalid cases (e.g., `+TESTCASE=burst`, `+TESTCASE=invalid`).

### Exercise 3: Verbosity Levels with Enum Safety

**Goal**: Implement 4 verbosity levels (`QUIET`, `SUMMARY`, `FULL`, `TRACE`) using an enum.  
**Steps**:

1. Define an enum: `typedef enum {QUIET, SUMMARY, FULL, TRACE} verbosity_t;`
2. Retrieve level via `$value$plusargs("VERBOSITY=%s", str)`.
3. Convert string to enum (use a helper function or case statement).
4. Validate the string is a valid enum value.
5. Use conditional blocks to control output:
   ```systemverilog
   if (verbosity inside {FULL, TRACE}) $display("Detailed signal: %h", signal);
   if (verbosity == TRACE) $display("TRACE: Cycle %0d", $time);
   ```
6. Default to `SUMMARY` if unspecified.

> 💡 **Pro Tip**: For enum conversion, create a function:
>
> ```systemverilog
> function automatic verbosity_t parse_verbosity(string str);
>   case (str.to_lower())
>     "quiet": return QUIET;
>     "sum": return SUMMARY;
>     // ... etc ...
>     default: begin
>       $error("Invalid verbosity: %s", str);
>       $fatal(1);
>     end
>   endcase
> endfunction
> ```

## Summary

Command line arguments transform SystemVerilog simulations from rigid scripts into adaptable verification instruments. By mastering `$value$plusargs` (for values) and `$test$plusargs` (for flags), you gain the power to:

- **Reuse testbenches** across projects via parameter overrides
- **Isolate failures** by running specific test cases
- **Optimize debug cycles** with adjustable verbosity
- **Ensure robustness** through validation and clear defaults

Remember: The goal isn’t just to _accept_ arguments—it’s to _guide_ users toward correct usage with helpful defaults, precise validation, and informative feedback. Treat your command line interface like a well-designed instrument panel: intuitive, forgiving of minor errors, and impossible to misconfigure catastrophically.

---

##### Copyright (c) 2026 squared-studio
