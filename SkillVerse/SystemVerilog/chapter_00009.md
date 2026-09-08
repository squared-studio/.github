# Procedural Blocks in SystemVerilog: Behavioral Modeling Core

## Introduction

Procedural blocks are the engines of behavioral modeling in SystemVerilog. They allow you to describe the dynamic behavior of your hardware designs, create testbench environments, and control simulation flow. Unlike continuous assignments that react instantly to input changes, procedural blocks execute **sequentially**, step-by-step, making them essential for modeling sequential logic, state machines, memory elements, and complex control algorithms. Understanding and effectively using procedural blocks is fundamental for both RTL design and robust verification.

Procedural processes run concurrently with one another, but statements within a single process execute in source order until the process reaches a delay, event control, or other blocking synchronization point. This distinction is central to understanding race conditions and the difference between simulation time and source-code order.

## Learning Goals

By the end of this chapter, you should be able to:

- Distinguish `initial`, `final`, general `always`, `always_comb`, `always_ff`, and `always_latch` processes.
- Choose blocking or nonblocking assignments according to the behavior being modeled.
- Explain simulation scheduling, including concurrent processes and nonblocking update timing.
- Write complete combinational logic and intentional sequential or latch behavior.
- Recognize synthesis-tool dependencies and avoid race-prone or multiply driven procedural code.

## Initial Blocks: Simulation Setup and Initialization

`initial` blocks are executed **once at the very beginning of simulation**, at time 0. Their primary role is to set up the simulation environment, initialize signals and variables, and kickstart simulation activities.

**Key Characteristics and Usage:**

-   **Single Execution**:  Code within an `initial` block runs only once, sequentially from top to bottom, at the start of the simulation.
-   **Concurrent Execution of Multiple Blocks**: If you have multiple `initial` blocks in your design, they all begin execution concurrently at time 0. Their relative ordering at the same simulation time is not a reliable synchronization mechanism.
-   **Testbench Focus**: `initial` blocks are primarily used in testbenches and simulation environments. Many RTL synthesis flows do not synthesize arbitrary `initial` behavior, although FPGA tools may support declaration or `initial`-block initialization for selected memories and registers. Follow the target technology's synthesis rules.
-   **Common Use Cases**:
    -   **Testbench Initialization**: Setting initial values for input signals, design variables, and memory contents.
    -   **Signal Stimulation**: Generating initial stimulus or sequences of input patterns to drive the design under test (DUT).
    -   **One-Time Configuration**: Loading configuration data, setting up simulation parameters, and opening output files.

```systemverilog
module testbench;
  logic clk;
  logic rst_n;
  logic [7:0] data_in;
  logic start_transaction;

  initial begin // Initialization block 1
    clk = 0;          // Initialize clock
    rst_n = 0;        // Assert reset
    data_in = 0;
    start_transaction = 0;

    $display("Testbench: Simulation starting at time %0t", $time);
    #20 rst_n = 1;     // De-assert reset after 20 time units
    #50 start_transaction = 1; // Start transaction after reset
    #100 start_transaction = 0;
  end

  initial begin // Initialization block 2 (runs concurrently with block 1)
    #1000 $finish;     // End simulation after 1000 time units
  end

  always #5 clk = ~clk; // Clock generation (runs continuously)

  // ... (DUT instantiation and other testbench logic) ...

endmodule
```

## Final Blocks: Simulation Wrap-up and Reporting

`final` blocks are executed **once when the simulation is about to terminate**. They provide a mechanism to perform cleanup tasks, report simulation results, and generate summary information at the end of a simulation run.

**Key Characteristics and Usage:**

-   **End-of-Simulation Execution**: Code in a `final` block executes only once when simulation termination is being completed. A call such as `$finish` can terminate active processes and then trigger `final`; `final` should not be understood as waiting for every free-running `always` block to end naturally.
-   **Non-Synthesizable**: Like `initial` blocks, `final` blocks are **not synthesizable** and are used exclusively in simulation and verification environments.
-   **Reporting and Cleanup**:
    -   **Result Reporting**: Displaying simulation statistics, error counts, coverage metrics, and overall test status.
    -   **File Closing**: Closing log files, output data files, and any other files opened during simulation.
    -   **Resource Cleanup**: Releasing any simulation-specific resources or memory allocations (though typically handled automatically by the simulator).

```systemverilog
module verification_environment;
  integer transaction_count = 0;
  integer error_count = 0;
  integer log_file_desc;

  initial begin
    log_file_desc = $fopen("simulation_log.txt", "w"); // Open log file
    // ... (rest of testbench and simulation setup) ...
  end

  // ... (simulation logic, transaction processing, error checking, incrementing transaction_count and error_count) ...

  final begin
    $display("\n--- Simulation Summary ---");
    $display("Total Transactions Processed: %0d", transaction_count);
    $display("Total Errors Detected: %0d", error_count);
    if (error_count > 0) begin
      $display("SIMULATION FAILED!");
    end else begin
      $display("SIMULATION PASSED!");
    end
    $fclose(log_file_desc); // Close the log file
    $display("Log file 'simulation_log.txt' closed.");
  end
endmodule
```

## Always Blocks: Continuous, Reactive Behavior

`always` blocks are the workhorses of SystemVerilog behavioral modeling, especially for RTL design. They describe blocks of code that execute **repeatedly** in response to events or conditions defined by their sensitivity lists or timing controls.

### 1. General `always` Block: Continuous Processes (Testbench Clock Generation)

-   **Continuous, Unconditional Execution**: A general `always` block, when combined with timing control statements (like `#delay`), creates a continuously running process.
-   **Primary Testbench Use**:  In RTL design, general `always` blocks without sensitivity lists are **rarely synthesizable**. They are primarily used in testbenches for tasks like clock generation and background processes.

The `always` keyword repeats its statement forever. An `always` process without a timing control can execute indefinitely at one simulation time and prevent time from advancing. For RTL, use an explicit `always_comb`, `always_ff`, or `always_latch` block when its intent matches one of those constructs; use a timed general `always` primarily for testbench activity.

```systemverilog
module clock_generator (
  output logic clk_out
);

  initial clk_out = 0; // Initialize clock

  always #5 clk_out = ~clk_out; // Toggle clock every 5 time units (period = 10)
                                 // Creates a free-running clock signal
endmodule
```

### 2. `always_comb` Block: Combinational Logic Inference

-   **Combinational Logic Description**: `always_comb` blocks are specifically designed to model combinational logic. They infer combinational circuits based on the code within the block.
-   **Automatic Sensitivity List**:  The key feature of `always_comb` is its **automatic sensitivity list**. The simulator automatically infers all input signals that the output depends on. Whenever any of these input signals change value, the `always_comb` block is re-evaluated, ensuring the output is always up-to-date with the inputs.
-   **Single Execution at Time 0**:  `always_comb` blocks are also evaluated once at the beginning of simulation (time 0) to establish initial output values. This initial evaluation does not make an incomplete block combinational; every output still needs a value on every intended path.
-   **Blocking Assignments (`=`)**: Use **blocking assignments** inside `always_comb` blocks. This ensures that the logic is evaluated and updated immediately when inputs change, reflecting the behavior of combinational circuits.

```systemverilog
module combinational_adder(
  input  logic [7:0] input_a,
  input  logic [7:0] input_b,
  output logic [7:0] sum
);
  always_comb begin // Combinational logic block
    sum = input_a + input_b; // Sum is re-calculated whenever input_a or input_b changes
  end
endmodule
```

### 3. `always_ff` Block: Sequential Logic (Flip-Flop) Inference

-   **Sequential Logic Modeling**: `always_ff` blocks are specifically for modeling sequential logic elements, primarily flip-flops and registers.
-   **Explicit Event Control Required**:  `always_ff` requires an event control, typically a clock edge such as `posedge clk`, plus asynchronous control edges such as `negedge rst_n` when the design has an asynchronous reset. Data inputs are not placed in the event control because a flip-flop samples them at the clock event. The exact restrictions are enforced by the simulator and lint tools.
-   **Non-Blocking Assignments (`<=`)**:  **Use non-blocking assignments (`<=`)** inside `always_ff` blocks. The right-hand side is evaluated when the event occurs and the update is scheduled for the NBA region, allowing all registers triggered by the same clock edge to update without source-order dependence.

```systemverilog
module d_flip_flop(
  input logic clk,
  input logic rst_n,
  input logic data_in,
  output logic data_out
);
  always_ff @(posedge clk or negedge rst_n) begin // Sequential logic block
    if (!rst_n) begin // Asynchronous reset (active low)
      data_out <= 1'b0; // Reset output to 0
    end else begin      // Clocked behavior
      data_out <= data_in; // Update output on positive clock edge
    end
  end
endmodule
```

### 4. `always_latch` Block: Latch Inference (Use with Caution)

-   **Latch Modeling**: `always_latch` blocks are intended to model latches. Latches are level-sensitive memory elements, unlike flip-flops which are edge-triggered.
-   **Conditional Assignments for Latch Behavior**: Latches are typically inferred when a signal is assigned a value conditionally within an `always_latch` block, and there is no `else` clause or default assignment to cover all conditions. `always_latch` communicates that this storage is intentional and lets tools check the construct; it does not remove the latch.
-   **Use Sparingly in RTL**: Latches are often **undesirable in synchronous digital designs** because they can introduce timing hazards and make timing analysis more complex.  Avoid intentional latch inference in most RTL designs unless specifically required by the architecture.

```systemverilog
module level_sensitive_latch(
  input logic enable,
  input logic data_in,
  output logic data_out
);
  always_latch begin // Latch inference block
    if (enable) begin
      data_out = data_in; // Latch is transparent when enable is high
    end // No 'else' - latch holds previous value when enable is low
  end
endmodule
```

## Assignment Types within Procedural Blocks: Blocking vs. Non-Blocking

The type of assignment used within procedural blocks (`always`, `initial`, `final`) significantly impacts the behavior of your SystemVerilog code, especially in RTL design.

### Blocking Assignments (`=`): Sequential Execution

-   **Sequential Execution**: Blocking assignments (`=`) execute in the order they appear within the procedural block. When a blocking assignment is encountered, the assignment is performed **immediately**, and the procedural block execution **pauses** until the assignment is complete.
-   **Immediate Value Update**: The variable on the left-hand side of a blocking assignment is updated with the new value **before** the execution proceeds to the next statement in the block.
-   **Combinational Logic and Testbenches**: Blocking assignments are primarily used:
    -   **Inside `always_comb` blocks** to model combinational logic accurately.
    -   **In `initial` and `final` blocks** and in testbench procedures where sequential, step-by-step execution is desired.

```systemverilog
module blocking_assignment_example;
  integer variable_x, variable_y;

  initial begin
    variable_x = 5;          // Line 1: variable_x becomes 5 immediately
    variable_y = variable_x + 3; // Line 2: variable_y becomes 5 + 3 = 8 (using the updated value of variable_x)
    $display("variable_x = %0d, variable_y = %0d", variable_x, variable_y); // Output: variable_x = 5, variable_y = 8
  end
endmodule
```

### Non-Blocking Assignments (`<=`): Concurrent Updates

-   **Concurrent Scheduling**: Non-blocking assignments (`<=`) evaluate their right-hand sides immediately and schedule updates for the simulator's **NBA region**. When a non-blocking assignment is encountered, the assignment is scheduled, but the procedural block execution **does not pause**. It continues to the next statement.
-   **Delayed Value Update**: The actual update of the variable on the left-hand side of a non-blocking assignment happens after the active-region statements for the current time slot have run. The right-hand side expression is evaluated when the non-blocking assignment is encountered, but the result is not assigned until the NBA region. Other delta-cycle activity may still follow.
-   **Sequential Logic Modeling**: Non-blocking assignments are **essential for modeling sequential logic** (flip-flops, registers) correctly, particularly within `always_ff` blocks. They ensure that all register updates triggered by the same clock edge happen concurrently, reflecting real hardware behavior.

```systemverilog
module non_blocking_assignment_example;
  logic [1:0] register_a = 2'b00;
  logic [1:0] register_b = 2'b00;

  initial begin
    register_a <= 2'b10; // Line 1: Schedule update for register_a at the end of the time step
    register_b <= register_a; // Line 2: Schedule update for register_b at the end of the time step, using the *original* value of register_a (before update)

    #1 $display("register_a = %b, register_b = %b", register_a, register_b);
    // Output at time 1: register_a = 10, register_b = 00
    // register_a gets updated to 2'b10 as scheduled.
    // register_b gets the *old* value of register_a (which was 0 at the start of the time step)
  end
endmodule
```

**Key Rules for Assignment Types:**

-   **Continuous assignments**: In `assign a = b`, `=` is a simple continuous-assignment operator. It is not a blocking assignment because `assign` is not a procedural block.
-   **Procedural assignments**: Only assignments inside procedural constructs such as `task`, `always`, and `initial` blocks use `=` and `<=` as blocking and non-blocking assignments. A procedural `=` updates immediately and a procedural `<=` schedules an update for the NBA region.
-   **Driving signals**: Use non-blocking assignments (`<=`) when driving signals, especially clocked signals in `always_ff` and testbench stimulus that must update concurrently.
-   **Sampling signals**: Use blocking assignments (`=`) when sampling signals into temporary variables or when calculating intermediate values in procedural code. This makes the sampled value available immediately to subsequent statements.
-   **Combinational procedures**: Use blocking assignments (`=`) for intermediate calculations and combinational outputs in `always_comb`. This is a procedural use of `=`, not a continuous assignment.
-   **Sequential procedures**: Use non-blocking assignments (`<=`) for registers and other state updated in `always_ff` blocks.
-   **Do not mix assignment types for the same variable in one procedural block.** Keep each variable's procedural assignment style consistent to avoid race-prone, simulation-dependent behavior.

## Best Practices and Common Pitfalls with Procedural Blocks

1.  **Synthesis Guidelines for `always` Blocks**:
    -   **`always_comb` for Combinational**:  Use `always_comb` for all combinational logic descriptions. It provides automatic sensitivity lists and helps prevent latches.
    -   **`always_ff` for Sequential**: Use `always_ff` exclusively for flip-flop and register modeling. Always include the clock and relevant reset signals in the sensitivity list.
    -   **Avoid General `always` in RTL**:  Minimize the use of general `always` blocks in synthesizable RTL designs, as they can be less clear about the intended logic type (combinational or sequential) and may lead to synthesis issues. Reserve general `always` for testbench clock generation or specific, well-understood cases.

2.  **Latch Prevention - Completeness in Combinational Logic**:
    -   **Problem: Incomplete `if` or `case` in `always_comb` can infer latches.** If not all possible conditions are explicitly handled in an `always_comb` block, and a signal is assigned a value only under certain conditions, the synthesizer may infer a latch to "hold" the previous value when none of the specified conditions are met.

    ```systemverilog
    // BAD - Latch Inferred (incomplete conditional assignment)
    always_comb begin
      if (enable)
        output_signal = input_data; // What happens to output_signal when 'enable' is false? - Latch!
    end

    // GOOD - Full Combinational Logic (using conditional operator)
    always_comb begin
      output_signal = enable ? input_data : 1'b0; // Explicitly define output for both 'enable' true and false
    end

    // GOOD - Full Combinational Logic (using if-else)
    always_comb begin
      if (enable) begin
        output_signal = input_data;
      end else begin
        output_signal = 1'b0; // Explicit 'else' branch prevents latch
      end
    end
    ```
    -   **Solution**: Ensure that within `always_comb` blocks, for every output signal, you have a **complete assignment** that covers all possible input conditions. Use `else` clauses in `if` statements and `default` cases in `case` statements to explicitly define the output value in all scenarios.

3.  **Event Controls in `always_ff`**:
    -   **Include Clock and Asynchronous Resets**:  For `always_ff` blocks modeling flip-flops, the sensitivity list **must include the clock edge** (e.g., `posedge clk`) and **any asynchronous reset signals** (e.g., `negedge rst_n`).
    -   **Do Not Add Data Inputs**: Data and enable signals are sampled inside the clocked block and should not be added as sensitivity events. Missing a required asynchronous control event can cause simulation to disagree with the intended hardware behavior.

4.  **Avoid Mixing Assignment Types**:
    -   **Never mix blocking and non-blocking assignments to the same variable within a single `always`, `initial`, or `final` block.** This is a common source of subtle errors and unpredictable simulation behavior.
    -   **Consistent Assignment Style**:  Choose the appropriate assignment type (blocking or non-blocking) for each procedural block based on whether you are modeling combinational or sequential logic, and stick to that type consistently within the block.

## Exercises to Practice Procedural Blocks

1.  **Initial Block Message**: Create a testbench module with an `initial` block that displays the message "System Initialization Started..." at the beginning of the simulation.
2.  **Final Block Simulation Time Report**: Write a testbench module that uses a `final` block to report the total simulation time elapsed using the `$time` system function at the end of the simulation.
3.  **100MHz Clock Generator**: Design a clock generator module using a general `always` block to produce a 100MHz clock signal with a 50% duty cycle.
4.  **Combinational 8-bit Multiplier**: Implement a combinational 8-bit multiplier module using an `always_comb` block. The module should take two 8-bit inputs and output their 16-bit product.
5.  **4-bit Synchronous Counter with Asynchronous Reset**: Design a 4-bit synchronous counter module using an `always_ff` block. The counter should have a clock input, an active-low asynchronous reset input, and a 4-bit count output.
6.  **Transparent Latch**: Create a module that implements a transparent latch using an `always_latch` block. The latch should be enabled by an `enable` input and pass the `data_in` to `data_out` when enabled, holding the last value when disabled.
7.  **Blocking vs. Non-blocking Assignment Value Swap**: Write two separate modules to demonstrate value swapping between two variables:
    -   One module using **blocking assignments** to swap the values.
    -   Another module using **non-blocking assignments** to attempt to swap the values (and observe the outcome). Display the variable values after the assignments in both modules to illustrate the difference in behavior.

By working through these exercises and carefully considering the best practices, you will develop a strong foundation in using SystemVerilog procedural blocks effectively for both RTL design and verification.

##### Copyright (c) 2026 squared-studio

