# Control Flow in SystemVerilog: Directing Execution

## Introduction

Imagine your SystemVerilog code as a busy city intersection. Control flow statements are the traffic lights and signs that determine _which_ cars (code blocks) get to go, _when_ they go, and _how many times_ they loop around the block. Mastering these constructs lets you build hardware that responds dynamically to inputs, creates precise test sequences, and models complex behaviors—all while keeping your code clean and synthesizable.

## Conditional Statements: Making Decisions

### `if-else` Statements: Your Code's Fork in the Road

Think of `if-else` as a decision point: _"If it's raining, take an umbrella; else, wear sunglasses."_ SystemVerilog evaluates a condition (true/false) and executes the corresponding code block.

**Key Points:**

- Use `else if` for **mutually exclusive** choices (only one condition can be true, like grading: A, B, C, or F).
- Always wrap multi-line blocks in `begin`/`end` for clarity and safety—even if optional for single lines. This prevents bugs when you later add statements.

```systemverilog
module grade_classifier;
  logic [7:0] score = 85; // Example score

  initial begin
    if (score >= 90) begin
      $display("Grade: A");
    end else if (score >= 80) begin
      $display("Grade: B"); // Executes for score=85
    end else if (score >= 70) begin
      $display("Grade: C");
    end else begin
      $display("Grade: F");
    end
  end
endmodule
```

> 💡 **Why `else if`?** Without it, checking `score >= 80` _after_ `score >= 90` would be redundant (since 85 isn’t ≥90). `else if` stops checking once a match is found—saving simulation time.

### `case` Statements: Switching on Values

When you need to match a value against many specific options (like a menu selector), `case` statements shine. SystemVerilog offers three variants for different matching needs—all require a `default` clause in synthesizable code to avoid latches (unintended memory elements that break hardware).

#### 1. `case`: Exact Match (Like a Precise Key)

Matches _only_ if bits are identical. Ideal for enums or fixed values (e.g., opcode decoders).

```systemverilog
module traffic_light;
  enum logic [1:0] {RED=2'b00, YELLOW=2'b01, GREEN=2'b10} light;
  light current_state = GREEN;

  initial begin
    case (current_state)
      RED:    $display("Stop!");
      YELLOW: $display("Slow down.");
      GREEN:  $display("Go!"); // Matches: current_state == GREEN
      default: $display("Error: Invalid light state!"); // Critical for synthesis
    endcase
  end
endmodule
```

#### 2. `casez`: Ignoring `z` and `?` (Like a Key with Worn Teeth)

Treats `z` (high-Z) and `?` as "don't care"—useful when certain bits don’t matter (e.g., masked address checks).

```systemverilog
module addr_decoder;
  logic [3:0] addr = 4'b10xz; // x=unknown, z=high-Z (only bits 3:2 matter)

  initial begin
    casez (addr)
      4'b10?? : $display("Selecting Bank 0"); // Matches: addr[3:2] = 2'b10
      4'b01?? : $display("Selecting Bank 1");
      default : $display("No bank selected");
    endcase
  end
endmodule
```

#### 3. `casex`: Ignoring `x`, `z`, and `?` (Like a Master Key—Use Sparingly)

Matches if non-wildcard bits align. **Caution:** Overuse in RTL can cause synthesis mismatches since `x` implies uncertainty. Best for verification (e.g., flexible pattern matching in protocol headers).

```systemverilog
module status_checker;
  logic [3:0] flags = 4'b10x1; // Bit 1 unknown (x), others fixed

  initial begin
    casex (flags)
      4'b101x: $display("Priority Alert!"); // Matches if bit2=1 & bit0=1 (bit1 ignored)
      4'b10x1: $display("Standard Status"); // Exact match on known bits
      default: $display("Unknown state");
    endcase
  end
endmodule
```

> 🔑 **Pro Tips for `case`:**
>
> - **`unique case`**: Flags errors if _zero or multiple_ cases match (great for catching incomplete specs).
> - **`priority case`**: Executes the _first_ matching case (top-down)—use when order matters (e.g., interrupt prioritization).
> - **Always include `default`**: Prevents latches in synthesis by defining behavior for all possible inputs.

## Loop Constructs: Automating Repetition

Loops let you execute code repeatedly—like a robot arm assembling parts on a conveyor belt. Choose the loop type based on _how_ you know when to stop.

### 1. `repeat` Loop: Fixed Count (Like Doing 10 Push-Ups)

Runs a set number of times (known at compile time). Ideal for fixed-delay sequences or initializing arrays.

```systemverilog
module blink_led;
  parameter BLINK_COUNT = 5;

  initial begin
    repeat (BLINK_COUNT) begin
      $display("LED ON");  // Simulate LED toggle
      #5;
      $display("LED OFF");
      #5;
    end
    $display("Blinking sequence complete.");
  end
endmodule
```

### 2. `while` Loop: Condition-Driven (Like Filling a Cup Until Full)

Continues _while_ a condition holds true. Use when exit depends on dynamic state (e.g., waiting for a signal).

```systemverilog
module counter_until_full;
  integer count = 0;
  parameter FULL = 10;

  initial begin
    while (count < FULL) begin
      $display("Count = %0d", count);
      count++;
      #1; // Simulate time passing
    end
    $display("Container full!");
  end
endmodule
```

### 3. `for` Loop: Compact Counter (Like a Numbered To-Do List)

Combines initialization, condition, and increment—perfect for indexed operations (e.g., array processing).

```systemverilog
module sum_array;
  logic [7:0] data[4] = '{10, 20, 30, 40};
  integer sum = 0;

  initial begin
    for (int i = 0; i < $size(data); i++) begin // 'i' scoped to loop
      sum += data[i];
    end
    $display("Total = %0d", sum); // Outputs 100
  end
endmodule
```

### 4. `foreach` Loop: Array-Focused (Like Visiting Every House on a Street)

Iterates over _all_ array indices automatically—simplifies array traversal without manual index management.

```systemverilog
module find_max;
  logic [7:0] scores[5] = '{85, 92, 78, 96, 88};
  logic [7:0] max_score;

  initial begin
    max_score = scores[0];
    foreach (scores[i]) begin
      if (scores[i] > max_score) max_score = scores[i];
    end
    $display("Highest score: %0d", max_score); // Outputs 96
  end
endmodule
```

### 5. `forever` Loop: Infinite Runner (Like a Clock Generator—Use with Care!)

Runs indefinitely until explicitly stopped. **Essential in testbenches** for clocks/monitors—but _must_ include timing control (`#delay`) or an exit condition to avoid freezing simulation.

```systemverilog
module clock_gen;
  initial begin : clock_block // Named block for clean disable
    int cycle = 0;
    forever begin
      $display("Clock cycle %0d", cycle);
      cycle++;
      #5; // 10-timeunit period (5 high, 5 low)
      if (cycle == 20) disable clock_block; // Stop after 20 cycles
    end
    $display("Simulation ended.");
  end
endmodule
```

> ⚠️ **Critical Notes for Loops in Hardware (RTL):**
>
> - **`repeat`/`while`/`for` in RTL**: Only use if bounds are **static** (known at compile time, e.g., parameters). Synthesis tools "unroll" these into equivalent logic.
> - **Never use `forever` or `while(1)` in RTL**: These imply infinite hardware—unsynthesizable. Reserve for testbenches or initial blocks.
> - **Testbench `forever` loops**: _Always_ include `#delay` to advance simulation time. Use `disable` or event-based exits (e.g., `wait (done)`) to terminate cleanly.

## Exercises: Build Your Control Flow Intuition

1. **Signal Classifier (`if-else`)**:  
   Create a module that classifies a 3-bit signal (`000`=idle, `001`=start, `010`=data, `100`=stop) using `if-else`. Handle invalid combinations.

2. **Opcode Decoder (`case`)**:  
   Design a module that takes a 4-bit opcode and uses a `case` statement to output the corresponding instruction (e.g., `0000`=NOP, `0001`=ADD). Use `default` for undefined opcodes.

3. **Timer with `repeat`**:  
   Build a countdown timer that prints "T-minus %0d" from a parameterized value (e.g., 10) down to 0 using a `repeat` loop.

4. **Stack Monitor (`while`)**:  
   Simulate a stack pointer that increments until it reaches a threshold, using a `while` loop to check for overflow each cycle.

5. **Polynomial Evaluator (`for`)**:  
   Calculate \( f(x) = 2x^2 + 3x + 1 \) for x=0 to 4 using a `for` loop. Print each result.

6. **Packet Validator (`foreach`)**:  
   Check if all bytes in a 8-byte array are non-zero using a `foreach` loop. Flag if any byte is 0.

7. **Watchdog Timer (`forever`)**:  
   Create a testbench where a `forever` loop resets a counter every 100 cycles. Use `disable` to stop after 500 cycles, printing "System stable."

## Why This Matters

Effective control flow turns rigid code into adaptive, intelligent hardware. By mastering these constructs—understanding _not just the syntax, but when and why_ to use each one—you’ll write SystemVerilog that’s efficient, synthesizable, and a joy to maintain. Now go build something amazing! 🚀

##### Copyright (c) 2026 squared-studio
