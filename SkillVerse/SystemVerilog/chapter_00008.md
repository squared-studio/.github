# Control Flow in SystemVerilog: Directing Execution

## Introduction

Control flow statements are the traffic directors of SystemVerilog, determining the execution order of your code. They empower you to create dynamic and responsive designs and verification environments.  Mastering these constructs is essential for modeling complex hardware behavior, building sophisticated testbenches, and implementing algorithms within SystemVerilog.  Effective control flow leads to code that is not only functional but also readable, maintainable, and efficient for both simulation and hardware synthesis.

## Learning Goals

By the end of this chapter, you should be able to:

- Select `if`, `case`, and loop constructs based on the behavior being modeled.
- Account for four-state `X`/`Z` values when conditions and case expressions are evaluated.
- Use `unique`, `priority`, `default`, and explicit assignment patterns without creating accidental storage.
- Write bounded loops for RTL and time-controlled loops for testbenches.
- Exit loops predictably using conditions, `break`, `return`, or named-block control when appropriate.

## Conditional Statements: Branching Logic

Conditional statements allow your SystemVerilog code to make decisions, executing different code blocks based on whether specific conditions are met.

### `if-else` Statements: Binary and Multi-way Decisions

The `if-else` statement is the cornerstone of conditional logic. It executes one block of code if a condition is true, and optionally another block if the condition is false.  `else if` clauses extend this to handle multiple, mutually exclusive conditions.

**Key Design and Style Points:**

-   **`else if` for Mutually Exclusive Choices**: Use `else if` to efficiently handle a series of conditions where only one branch should execute.
-   **Block Delimiters for Clarity**: While optional for single-line statements following `if`, `else if`, and `else`, using `begin` and `end` consistently enhances readability and avoids potential errors when modifying code. In SystemVerilog, `begin`/`end` are block delimiters; `{}` are concatenation or assignment-pattern delimiters, not procedural braces.

```systemverilog
module if_else_example;
  parameter  THRESHOLD_HIGH = 50;
  parameter  THRESHOLD_MID  = 30;
  logic [7:0] data_value = 42;

  initial begin
    if (data_value > THRESHOLD_HIGH) begin
      $display("%0d: Data is HIGH (above %0d)", data_value, THRESHOLD_HIGH);
    end else if (data_value > THRESHOLD_MID) begin
      $display("%0d: Data is MEDIUM (between %0d and %0d)", data_value, THRESHOLD_MID + 1, THRESHOLD_HIGH); // Executes for data_value = 42
    end else begin
      $display("%0d: Data is LOW (at or below %0d)", data_value, THRESHOLD_MID);
    end
  end
endmodule
```

In a four-state expression, an `X` or `Z` condition is not the same as a known `1`. An `if` branch executes only when its condition evaluates to `1`; an unknown condition does not execute that branch and reaches the `else` path when one exists. Assertions or explicit case equality can be used when unknown values must be diagnosed rather than treated as non-true.

## Case Statements: Multi-Way Branching Based on Value

`case` statements select one branch by comparing an expression with a list of items. The first matching item executes, so item order matters whenever patterns overlap. The three common forms differ mainly in how they treat `X`, `Z`, and `?` values.

### 1. `case`: Exact Value Matching

-   **Four-state matching**: A plain `case` compares all bits, including `X` and `Z`. For example, `4'b10x1` matches `4'b10x1`, but does not match `4'b1011`.
-   **Use for known encodings**: This is the usual choice for an opcode, state, or enum whose value must be known exactly.
-   **`default`**: In combinational logic, assign safe defaults and include a `default` branch so every input has a defined output.

```systemverilog
module case_example (
  input  logic [1:0] opcode,
  output logic [1:0] result
);
  always_comb begin
    result = 2'b00; // Safe default for unused or invalid opcodes
    case (opcode)
      2'b00: result = 2'b01; // add
      2'b01: result = 2'b10; // subtract
      2'b10: result = 2'b11; // multiply
      default: result = 2'b00;
    endcase
  end
endmodule
```

If `opcode` contains `2'b0x`, none of the three known patterns matches, so the `default` branch is selected. That behavior is often useful because an unknown control value does not silently select a real operation.

### 2. `casez`: Wildcards for `Z` and `?`

-   **Pattern matching**: In a case item, `?` means “this bit can be either `0` or `1`.” `casez` also treats `Z` as a wildcard in the expression and in case items.
-   **Unknown `X` is different**: `casez` does not treat `X` as a wildcard. An `X` in a significant position prevents a match against either `0` or `1`, which helps expose unknown control signals.
-   **Use for masked encodings**: `casez` is useful when the protocol intentionally ignores some bits, such as address masks or interrupt vectors. Prefer `?` in the case item to document which bits are intentionally ignored.
-   **Overlapping patterns**: The first matching item wins, so put the more specific pattern first.

```systemverilog
module casez_example (
  input  logic [3:0] request,
  output logic [1:0] source
);
  initial begin
    casez (request)
      4'b1???: source = 2'd3; // Any request beginning with 1
      4'b01??: source = 2'd2; // Any request from source 01
      4'b001?: source = 2'd1; // Any request from source 001
      default: source = 2'd0;
    endcase
  end
endmodule
```

For example, `request = 4'b0110` selects source 2. `request = 4'b1z00` selects source 3 because the `Z` matches the `?` positions. If the first pattern were `4'b????`, it would match everything and make all later branches unreachable.

The difference between an intentional wildcard and an unknown signal is important:

| Expression | Case item | `casez` result | Reason |
| --- | --- | --- | --- |
| `4'b1010` | `4'b10??` | Match | `?` ignores the last two bits |
| `4'b10z0` | `4'b10??` | Match | `Z` is treated as a wildcard |
| `4'b10x0` | `4'b10??` | No match | `X` is not a `casez` wildcard |
| `4'b10x0` | `4'b10x0` | Match | The `X` values match exactly |

The last row is an exact `X` match, not a wildcard match. It only matches another `X` in that same bit position.

### 3. `casex`: Wildcards for `X`, `Z`, and `?`

-   **Aggressive matching**: `casex` treats `X`, `Z`, and `?` as wildcards in both the expression and the case items. A wildcard is not a statement that the signal is valid; it simply removes that bit from the comparison.
-   **Why this is risky**: An uninitialized, disconnected, or not-yet-driven signal can match a valid pattern. Simulation may therefore report a valid operation even though the hardware input is unknown.
-   **No useful distinction between `X` and `Z`**: With `casex`, both unknown (`X`) and high-impedance (`Z`) bits are ignored during matching. This can hide two different classes of wiring or initialization bugs.
-   **RTL guidance**: Avoid `casex` in synthesizable RTL. Prefer plain `case` when values must be known, or a carefully reviewed `casez` pattern when only `Z`/`?` masking is intentional.

```systemverilog
module casex_example;
  logic [3:0] status_flags = 4'b10x1;

  initial begin
    casex (status_flags)
      4'b1011: $display("Valid status"); // Matches because X is treated as a wildcard
      default: $display("Unknown status");
    endcase
  end
endmodule
```

The `casex` example prints `Valid status` even though bit 2 is unknown. That is the important danger: wildcard matching can turn “I do not know” into “this is valid.”

The same input demonstrates the difference directly:

```systemverilog
module casez_vs_casex_example;
  logic [3:0] flags = 4'b10x1;

  initial begin
    casez (flags)
      4'b1011: $display("casez: valid status");
      default: $display("casez: unknown status"); // This branch executes
    endcase

    casex (flags)
      4'b1011: $display("casex: valid status"); // This branch executes
      default: $display("casex: unknown status");
    endcase
  end
endmodule
```

In `casez`, the `X` in `flags` is significant and does not match `1`. In `casex`, that same `X` is ignored, so the pattern matches. This is why `casex` can conceal bugs that `casez` or plain `case` would reveal.

| Statement | Wildcards | Typical use |
| --- | --- | --- |
| `case` | None; `X` and `Z` must match exactly | Known states and opcodes |
| `casez` | `Z` and `?`; `X` remains significant | Explicit masked patterns |
| `casex` | `X`, `Z`, and `?` | Usually avoid in RTL |

### `unique case` and `priority case`

These keywords document intent and enable simulation warnings; they do not change the basic first-match rule.

**Key `case` Statement Best Practices:**

-   **`unique case`**: Use when zero or one item should match. Tools can warn if no item or multiple items match. Keep a `default` when invalid values need an explicit response.
-   **`priority case`**: Use when the first matching item is intentionally highest priority. Tools can warn if no item matches.
-   **Avoid accidental latches**: In `always_comb`, assign outputs a default before the case or handle every possibility with a `default` branch. A `default` in a clocked process does not create reset behavior; reset must still be modeled explicitly.

## Loop Constructs: Repetitive Operations

Loop constructs in SystemVerilog enable you to execute code blocks repeatedly, automating repetitive tasks in testbenches and, under certain constraints, in RTL designs.

### 1. `repeat` Loop: Fixed Iteration Count

-   **Predefined Iterations**: The `repeat` loop executes a block of code a fixed number of times. Its count expression is evaluated when the loop starts, so the count can come from a runtime variable; it does not have to be a compile-time constant.

```systemverilog
module repeat_example;
  parameter NUM_REPEATS = 4;

  initial begin
    $display("Starting repeat loop...");
    repeat (NUM_REPEATS) begin
      $display("- Repeat iteration"); // Executes NUM_REPEATS times
    end
    $display("Repeat loop finished.");
  end
endmodule
```

### 2. `while` Loop: Condition-Based Iteration

-   **Condition-Controlled Execution**: The `while` loop continues to execute its code block as long as a specified condition remains true.

```systemverilog
module while_example;
  integer counter = 0;
  parameter LIMIT = 5;

  initial begin
    $display("Starting while loop...");
    while (counter < LIMIT) begin
      $display("- While loop count: %0d", counter);
      counter++; // Increment counter to eventually exit loop
    end
    $display("While loop finished.");
  end
endmodule
```

### 3. `for` Loop: Compact Iteration with Initialization, Condition, Increment

-   **Combined Loop Control**: The `for` loop provides a concise syntax for loop control, combining initialization, a loop condition, and an increment/decrement step in a single statement.

```systemverilog
module for_example;
  parameter ITERATIONS = 3;

  initial begin
    $display("Starting for loop...");
    for (integer i = 0; i < ITERATIONS; i++) begin // Loop variable 'i' scoped to loop
      $display("- For loop iteration i = %0d", i);
    end
    $display("For loop finished.");
  end
endmodule
```

### 4. `foreach` Loop: Array Element Iteration

-   **Simplified Array Traversal**: The `foreach` loop is specifically designed to iterate over the elements of an array, simplifying array processing.

**Syntax**: `foreach (array_name[index_variable]) begin ... end`

```systemverilog
module foreach_example;
  integer data_values[5] = '{15, 25, 35, 45, 55};

  initial begin
    $display("Iterating with foreach loop:");
    foreach (data_values[index]) begin // 'index' automatically iterates through array indices
      $display("- data_values[%0d] = %0d", index, data_values[index]);
    end
    $display("Foreach loop finished.");
  end
endmodule
```

### 5. `forever` Loop: Continuous Execution (Testbenches)

-   **Infinite Loop**: The `forever` loop executes its code block indefinitely, creating an infinite loop.  It is primarily used in testbenches to generate continuous stimuli or to model systems that run continuously.
-   **Timing Control and Exit Mechanisms**:  **Crucially, always include a timing control (`#delay`) or a loop exit mechanism (like `disable`) within a `forever` loop to prevent simulation from hanging indefinitely.**

```systemverilog
module forever_example;
  initial begin : forever_process
    integer cycle_count = 0;
    $display("Starting forever loop (simulating clock)...");
    begin : forever_loop // Named loop block for disabling
      forever begin
        $display("- Cycle %0d", cycle_count);
        cycle_count++;
        #10; // Simulate clock period - Delay for 10 time units
        if (cycle_count >= 5) disable forever_loop; // Exit loop after 5 cycles
      end
    end
    $display("Forever loop disabled after 5 cycles.");
  end
endmodule
```

**Looping Best Practices for RTL and Verification:**

-   **RTL Loops - Static Bounds for Synthesis**: When using loops in RTL designs (within `always` blocks for sequential logic), ensure that loop bounds are statically determinable at compile time (e.g., using parameters or constants).  Synthesizers typically unroll loops with static bounds into combinational or sequential logic.
-   **Avoid Infinite Loops in RTL Synthesis**:  Do not use `forever` loops or `while(1)` loops directly in synthesizable RTL code, as they represent infinite processes and cannot be directly implemented in hardware.  Use them carefully for initialization or specific modeling scenarios if supported by your synthesis tool.
-   **`forever` Loops in Testbenches - Timing is Key**:  `forever` loops are invaluable in testbenches for tasks like clock generation, continuous monitoring, and stimulus generation.  Always incorporate delays (`#`) to control simulation time and prevent runaway simulations. Use `disable` statements or event-based control to terminate `forever` loops in testbenches when needed.

For a `while` loop, an `X` or `Z` condition is treated as not true, so the loop terminates rather than repeatedly executing on an unknown condition. Guard loop counters and exit conditions explicitly when an unknown value indicates a testbench or DUT failure. `break` exits the nearest loop, `continue` skips to its next iteration, and `return` exits the current task or function; these are often clearer than disabling a large named block.

## Exercises to Solidify Control Flow Understanding

1.  **Number Classifier (`if-else`)**: Write a module that takes an integer input and uses `if-else` statements to classify it as "Positive," "Negative," or "Zero," displaying the classification.
2.  **Weekday Name (`case`)**: Implement a module that takes a number from 1 to 7 as input and uses a `case` statement to output the corresponding weekday name (1=Monday, 2=Tuesday, etc.). Include a `default` case for invalid inputs.
3.  **`repeat` Loop Counter**: Create a module using a `repeat` loop to display numbers from 1 to a parameterized limit (e.g., `parameter LIMIT = 7;`).
4.  **Array Traversal (`while` Loop)**: Write a module that initializes an integer array and uses a `while` loop to iterate through the array, displaying each element's value and index.
5.  **Factorial Calculation (`for` Loop)**: Implement a module that calculates the factorial of a parameterized non-negative integer input using a `for` loop and displays the result.
6.  **Array Summation (`foreach` Loop)**: Write a module that initializes an integer array and uses a `foreach` loop to calculate and display the sum of all elements in the array.
7.  **Controlled Clock Generator (`forever` Loop)**: Create a testbench module that uses a `forever` loop with a `#delay` to simulate a clock signal.  Have the simulation run for a fixed number of clock cycles (e.g., 20 cycles) and then terminate using `disable`. Display the cycle count in each iteration.

By practicing with these exercises and understanding the nuances of each control flow statement, you'll gain the proficiency to write effective and well-structured SystemVerilog code for a wide range of hardware design and verification tasks.

##### Copyright (c) 2026 squared-studio

