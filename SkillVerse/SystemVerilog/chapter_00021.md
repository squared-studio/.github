# SystemVerilog Macros: Enhancing Code Reusability and Flexibility

## Introduction: Streamlining Code with Textual Macros

Imagine you're writing a cookbook and find yourself typing "preheat the oven to 350 degrees Fahrenheit" over and over. Instead of retyping it each time, you create a shortcut like "PREHEAT" that automatically expands to the full instruction. SystemVerilog macros work similarly—they're a preprocessor feature that performs textual substitution *before* compilation, acting like smart find-and-replace for your code.

**Why use macros? Think of them as productivity tools:**
- **Eliminate repetition**: Define a complex expression once and reuse it everywhere
- **Boost readability**: Replace magic numbers with meaningful names (like `DATA_WIDTH` instead of `32`)
- **Increase flexibility**: Change behavior across your entire design by modifying one definition
- **Enable conditional compilation**: Include or exclude code sections based on project needs

Think of the SystemVerilog preprocessor as a preparation chef that works before your main compiler (the sous chef) sees the ingredients. It handles macros, file includes (\`include), and conditional compilation directives—setting up your code for success.

## Defining and Using Macros

SystemVerilog macros are defined using the `` `define `` directive and undefined using the `` `undef `` directive. They are invoked by preceding the macro name with a backtick `` ` `` (grave accent)—think of this as pressing your shortcut key.

### `` `define ``: Creating Your Code Shortcuts

The `` `define `` directive creates a macro by associating a name with replacement text. Whenever the preprocessor encounters that name (preceded by a backtick), it substitutes the defined text.

**Syntax:**
```systemverilog
`define MACRO_NAME replacement_text
```

**Key points to remember:**
- Macro names are conventionally **UPPERCASE** to distinguish them from regular SystemVerilog identifiers (like variable names)
- The replacement text can be any valid SystemVerilog snippet: constants, expressions, statements, or even multi-line code blocks
- Macros operate at the **file level**—they're visible from their point of definition to the end of the file (like a note in a recipe that applies to the rest of that page)

**Example: Defining a Data Width Constant**
```systemverilog
`define DATA_WIDTH 32

module macro_example;
  // Using the macro to define a bus width
  logic [`DATA_WIDTH-1:0] data_bus;

  initial begin
    // Macro substitution happens here too
    $display("Data bus width: %0d bits", `DATA_WIDTH);
  end
endmodule
```

**What happens during preprocessing:**
1. `` `DATA_WIDTH `` becomes `32`
2. `` [`DATA_WIDTH-1:0] `` becomes `[31:0]`
3. The display statement shows "Data bus width: 32 bits"

### `undef: Removing Your Shortcuts

Just as you might remove a kitchen shortcut that's no longer useful, `` `undef `` removes a macro definition, making it unavailable for subsequent use in the file.

**Syntax:**
```systemverilog
`undef MACRO_NAME
```

**Example: Undefining a Macro**
```systemverilog
`define DATA_WIDTH 32

module undef_example;
  logic [`DATA_WIDTH-1:0] bus_a;  // Works: DATA_WIDTH is defined

  initial begin
    $display("Bus A width: %0d", `DATA_WIDTH);
    
    `undef DATA_WIDTH  // Remove the definition
    
    // This would cause a compilation error:
    // logic [`DATA_WIDTH-1:0] bus_b;  // ERROR: DATA_WIDTH undefined
    
    $display("DATA_WIDTH macro is now undefined.");
  end
endmodule
```

## Types and Applications of Macros

### 1. Simple Text Substitution Macros

These are the most basic macros—direct replacements for constants or frequently used snippets. Think of them as creating aliases for values you use repeatedly, like having "TSP" automatically expand to "teaspoon" in a recipe.

**Example: Clock and Reset Definitions**
```systemverilog
`define CLK_PERIOD 10ns      // Clock period
`define ACTIVE_LOW_RESET 0   // Reset polarity (0 = active low)

module clock_reset_example;
  timeunit 1ns; timeprecision 1ps;
  logic clk;
  logic reset_n;  // Active-low reset

  // Generate clock using the period macro
  initial begin
    clk = 0;
    forever #(`CLK_PERIOD/2) clk = ~clk;
  end

  // Apply reset using the polarity macro
  initial begin
    reset_n = `ACTIVE_LOW_RESET;
    #25ns reset_n = ~`ACTIVE_LOW_RESET;  // Deassert reset
  end
endmodule
```

**Why this helps:** If you later need to change the clock period to 5ns or switch to active-high reset, you only change one line instead of hunting through your code—just like changing "TSP" to mean "tablespoon" updates all your recipes at once.

### 2. Parameterized Macros: Macros with Arguments

Like functions in regular code, macros can accept parameters, making them reusable templates. During preprocessing, the parameters are substituted into the macro body—similar to how a macro might expand "COOK_TIME(5)" to "Cook for 5 minutes".

**Syntax:**
```systemverilog
`define MACRO_NAME(param1, param2, ...) replacement_using_params
```

**Example: Parameterized Assertion Macro**
```systemverilog
// Macro that checks a condition and reports failure with location info
`define ASSERT_TRUE(condition, message) \
  if (!(condition)) begin \
    $error("ASSERTION FAILED: %s at %s:%0d", \
           message, `__FILE__, `__LINE__); \
    $fatal; \
  end

module assertion_example;
  logic enable, ready;

  initial begin
    enable = 1;
    ready = 0;

    // Check that enable is high when expected
    `ASSERT_TRUE(enable == 1, "Enable should be active");
    
    // This will trigger an assertion failure
    `ASSERT_TRUE(ready == 1, "Ready should be active by now");
  end
endmodule
```

**How it works:**
1. When `` `ASSERT_TRUE(enable == 1, "Enable should be active") `` is encountered:
   - `condition` becomes `enable == 1`
   - `message` becomes `"Enable should be active"`
   - The macro expands to the full if-statement with these values substituted
2. Predefined macros `` `__FILE__ `` and `` `__LINE__ `` provide automatic location tracking (like automatically adding the page and line number to your error message)

### 3. Conditional Compilation Macros

These macros let you include or exclude code blocks based on whether a macro is defined—like having different versions of a recipe for dietary restrictions (gluten-free, vegan, etc.).

**Key directives:**
- `` `ifdef MACRO ``: Compiles following code if MACRO is defined
- `` `ifndef MACRO ``: Compiles if MACRO is *not* defined
- `` `else ``: Alternative code block
- `` `endif ``: Ends the conditional block

**Example: Debug vs. Production Builds**
```systemverilog
`define ENABLE_DEBUG  // Comment this line to disable debug output

module traffic_light_controller;
  logic [1:0] state;
  logic [7:0] timer;

  initial begin
    state = 2'b00;  // Red light
    timer = 8'd0;

    `ifdef ENABLE_DEBUG
      $display("DEBUG: Initial state = %b, timer = %0d", state, timer);
    `endif

    // Main controller logic
    #10ns timer = timer + 1;
    
    `ifdef ENABLE_DEBUG
      $display("DEBUG: After 10ns - state = %b, timer = %0d", state, timer);
    `endif
  end
endmodule
```

**Workflow:**
1. With `` `define ENABLE_DEBUG `` active: Debug messages print during simulation
2. To disable debug: Simply comment out or remove the `` `define ENABLE_DEBUG `` line
3. Recompile: Debug code is excluded from the final compiled simulation

This approach is cleaner than manually commenting/uncommenting debug statements throughout your code—like having a master switch for all your recipe notes instead of adding/removing them individually.

## Scope of Macro Definitions

Macros follow **file-level scope**—they're active from their point of definition to the end of the file where they're defined. This is similar to how a term defined in a recipe's notes section applies only to that recipe unless you copy it elsewhere.

**Important implications:**
1. **Visibility**: A macro defined in `file_a.sv` isn't automatically available in `file_b.sv`
2. **Redefinition**: Later definitions override earlier ones in the same file
3. **Sharing**: To use a macro across multiple files, define it in a common header file and `` `include `` it where needed

**Example: Demonstrating Scope**
```systemverilog
// file_definitions.sv
`define SHARED_CONSTANT 42
`define FILE_SPECIFIC_MSG "Defined in file_definitions.sv"

// file_usage.sv
// Note: SHARED_CONSTANT is NOT available here unless we redefine or include
`ifdef SHARED_CONSTANT
  // This block won't compile in file_usage.sv
  $display("This won't execute");
`else
  $display("SHARED_CONSTANT is not defined in this file");
`endif

// To share macros between files, use an include file:
// In both files: `include "shared_macros.svh"
```

## Predefined Macros: Built-in Helpers

SystemVerilog provides several automatically available macros that give you contextual information about your code—like having automatic footnotes that insert the current page number or chapter title.

| Macro | What It Provides | Practical Use Case |
|-------|------------------|---------------------|
| `` `__LINE__ `` | Current line number (integer) | Pinpointing error locations in assertions |
| `` `__FILE__ `` | Current filename (string) | Logging which module generated a message |
| `` `__TIME__ `` | Compilation time (hh:mm:ss) | Timestamping simulation runs |
| `` `__DATE__ `` | Compilation date (Mmm dd yyyy) | Version tracking and build identification |
| `` `__SYSTEMVERILOG__ `` | IEEE 1800 version number | Conditional code for different simulator versions |

**Example: Using Predefined Macros for Diagnostics**
```systemverilog
module diagnostic_example;
  initial begin
    // These macros expand automatically during preprocessing
    $display("=== Simulation Information ===");
    $display("File: %s", `__FILE__);
    $display("Line: %0d", `__LINE__);
    $display("Compiled at: %s on %s", `__TIME__, `__DATE__);
    $display("SystemVerilog version: %0d", `__SYSTEMVERILOG__);
  end
endmodule
```

These predefined macros are invaluable for adding contextual information to simulation outputs, assertions, and log messages—making debugging and tracking much easier.

## Best Practices for Macros

- **Use UPPERCASE for macro names**: Improves readability and distinguishes macros from regular identifiers
- **Keep macros concise**: Best for short, frequently used snippets; avoid overly complex macros
- **Document macros clearly**: Explain purpose, parameters (if any), and usage for maintainability
- **Use parameterized macros judiciously**: Only when parameterization genuinely simplifies code or provides significant reusability
- **Avoid macro redefinition**: Use `` `undef `` explicitly before redefining to prevent confusion
- **Leverage conditional compilation**: Use `` `ifdef ``/`` `else ``/`` `endif `` for managing build configurations and feature flags
- **Utilize predefined macros**: Leverage `` `__LINE__ ``, `` `__FILE__ ``, etc., for contextual information in messages
- **Consider alternatives for complex logic**: For intricate operations, prefer functions, tasks, or classes over macros
- **Parenthesize macro expressions**: When defining macros that represent expressions, enclose them in parentheses to preserve operator precedence
- **Avoid trailing semicolons**: Unless intentionally part of the substitution, don't include semicolons at macro definition ends

## Common Pitfalls and How to Avoid Them

### 1. Operator Precedence Issues
**Problem:** Macros perform simple text substitution, which can alter operator precedence.
```systemverilog
`define MULTIPLY(a, b) a * b  // No parentheses

module precedence_issue;
  initial begin
    $display("Result: %0d", 2 + `MULTIPLY(3, 4)); 
    // Expands to: 2 + 3 * 4 = 2 + 12 = 14 (not 2*(3+4)=20)
  end
endmodule
```
**Solution:** Parenthesize expression macros:
```systemverilog
`define MULTIPLY(a, b) ((a) * (b))
```

### 2. Unexpected Token Pasting
**Problem:** Adjacent tokens can merge unexpectedly after substitution.
```systemverilog
`define BUS_WIDTH 8
logic [`BUS_WIDTH-1:0] data;  // Becomes logic [8-1:0] - WRONG!
```
**Solution:** Ensure proper spacing or use parentheses:
```systemverilog
`define BUS_WIDTH 8
logic [(`BUS_WIDTH)-1:0] data;  // Correct: [7:0]
```

### 3. Multi-line Macro Pitfalls
**Problem:** Forgetting line continuation characters can cause syntax errors in multi-line macros.
**Solution:** Always end lines with `\` except the last line, and ensure proper formatting.

## Practical Exercises

### Exercise 1: Parameterizable FIFO
Create a FIFO module where depth and width are set via macros:
1. Define `FIFO_DEPTH` and `DATA_WIDTH` macros
2. Use them to size internal arrays and port widths
3. Write a testbench that displays the parameters using the macros
4. Experiment by changing the macro values and resimulating

### Exercise 2: Feature Toggles
Design a UART module with optional features:
1. Create `FEATURE_FIFO` and `FEATURE_PARITY` macros
2. Use `` `ifdef `` to conditionally include FIFO buffers and parity logic
3. Test with features enabled/disabled by defining/undefining the macros

### Exercise 3: Self-Documenting Assertions
Create an assertion macro that:
1. Takes a condition, message, and severity (warning/error)
2. Uses `` `__FILE__ `` and `` `__LINE__ `` for location
3. Reports appropriately based on severity
4. Demonstrates in a testbench with various conditions

## Summary

SystemVerilog macros are a powerful preprocessing tool that enhances code maintainability and flexibility through textual substitution. By understanding their scope, types, and best practices, you can:
- Eliminate redundant code with meaningful constants
- Create reusable, parameterized code templates
- Conditionally compile features for different build configurations
- Leverage predefined macros for self-documenting code

Remember that macros operate purely at the text level—they don't understand SystemVerilog syntax. For complex logic, always consider whether functions, tasks, or classes might be a better fit. When used judiciously, macros significantly improve design clarity and adaptability.

> **Remember**: Macros are like kitchen gadgets—excellent for specific tasks (peeling, slicing) but not a replacement for proper cooking techniques (algorithmic thinking). Use them for what they do best: simple, repetitive text substitutions that make your code cleaner and more flexible.

## Introduction: Streamlining Code with Textual Macros

Imagine you're writing a long technical document and find yourself typing the same complex phrase—like "asynchronous transfer mode protocol"—over and over. Instead of retyping it each time, you create a shortcut that automatically expands to the full phrase. SystemVerilog macros work similarly—they're a preprocessor feature that performs textual substitution *before* compilation, acting like smart find-and-replace for your code.

**Why use macros?**
- **Reduce repetition**: Define a complex expression once and reuse it everywhere
- **Improve readability**: Replace cryptic numbers with meaningful names (like `DATA_WIDTH` instead of `32`)
- **Enable flexibility**: Change behavior across your entire design by modifying a single definition
- **Support conditional compilation**: Include or exclude code sections based on project needs

Think of the SystemVerilog preprocessor as a preparation step that runs before your compiler sees the code. It handles macros, file includes (\`include), and conditional compilation directives.

## Defining and Using Macros

SystemVerilog macros are defined using the `` `define `` directive and undefined using the `` `undef `` directive. They are invoked by preceding the macro name with a backtick `` ` `` (grave accent).

### `` `define ``: Defining Macros

The `` `define `` directive creates a macro by associating a name with replacement text. Whenever the preprocessor encounters that name (preceded by a backtick), it substitutes the defined text.

**Syntax:**
```systemverilog
`define MACRO_NAME replacement_text
```

**Key points:**
- Macro names are conventionally **UPPERCASE** to distinguish them from regular SystemVerilog identifiers
- The replacement text can be any valid SystemVerilog snippet: constants, expressions, statements, or even multi-line code blocks
- Macros operate at the **file level**—they're visible from their point of definition to the end of the file

**Example: Defining a Data Width Constant**
```systemverilog
`define DATA_WIDTH 32

module macro_example;
  // Using the macro to define a bus width
  logic [`DATA_WIDTH-1:0] data_bus;

  initial begin
    // Macro substitution happens here too
    $display("Data bus width: %0d bits", `DATA_WIDTH);
  end
endmodule
```

When this code is preprocessed:
1. `` `DATA_WIDTH `` becomes `32`
2. `` [`DATA_WIDTH-1:0] `` becomes `[31:0]`
3. The display statement shows "Data bus width: 32 bits"

### `undef: Removing Macro Definitions

Just as you might remove a text shortcut, `` `undef `` removes a macro definition, making it unavailable for subsequent use in the file.

**Syntax:**
```systemverilog
`undef MACRO_NAME
```

**Example: Undefining a Macro**
```systemverilog
`define DATA_WIDTH 32

module undef_example;
  logic [`DATA_WIDTH-1:0] bus_a;  // Works: DATA_WIDTH is defined

  initial begin
    $display("Bus A width: %0d", `DATA_WIDTH);
    
    `undef DATA_WIDTH  // Remove the definition
    
    // This would cause a compilation error:
    // logic [`DATA_WIDTH-1:0] bus_b;  // ERROR: DATA_WIDTH undefined
    
    $display("DATA_WIDTH macro is now undefined.");
  end
endmodule
```

## Types and Applications of Macros

### 1. Simple Text Substitution Macros

These are the most basic macros—direct replacements for constants or frequently used snippets. Think of them as creating aliases for values you use repeatedly.

**Example: Clock and Reset Definitions**
```systemverilog
`define CLK_PERIOD 10ns      // Clock period
`define ACTIVE_LOW_RESET 0   // Reset polarity

module clock_reset_example;
  timeunit 1ns; timeprecision 1ps;
  logic clk;
  logic reset_n;  // Active-low reset

  // Generate clock using the period macro
  initial begin
    clk = 0;
    forever #(`CLK_PERIOD/2) clk = ~clk;
  end

  // Apply reset using the polarity macro
  initial begin
    reset_n = `ACTIVE_LOW_RESET;
    #25ns reset_n = ~`ACTIVE_LOW_RESET;  // Deassert reset
  end
endmodule
```

**Why this helps:** If you later need to change the clock period to 5ns or switch to active-high reset, you only change one line instead of hunting through your code.

### 2. Parameterized Macros: Macros with Arguments

Like functions in regular code, macros can accept parameters, making them reusable templates. During preprocessing, the parameters are substituted into the macro body.

**Syntax:**
```systemverilog
`define MACRO_NAME(param1, param2, ...) replacement_using_params
```

**Example: Parameterized Assertion Macro**
```systemverilog
// Macro that checks a condition and reports failure with location info
`define ASSERT_TRUE(condition, message) \
  if (!(condition)) begin \
    $error("ASSERTION FAILED: %s at %s:%0d", \
           message, `__FILE__, `__LINE__); \
    $fatal; \
  end

module assertion_example;
  logic enable, ready;

  initial begin
    enable = 1;
    ready = 0;

    // Check that enable is high when expected
    `ASSERT_TRUE(enable == 1, "Enable should be active");
    
    // This will trigger an assertion failure
    `ASSERT_TRUE(ready == 1, "Ready should be active by now");
  end
endmodule
```

**How it works:**
1. When `` `ASSERT_TRUE(enable == 1, "Enable should be active") `` is encountered:
   - `condition` becomes `enable == 1`
   - `message` becomes `"Enable should be active"`
   - The macro expands to the full if-statement with these values substituted
2. Predefined macros `` `__FILE__ `` and `` `__LINE__ `` provide automatic location tracking

### 3. Conditional Compilation Macros

These macros let you include or exclude code blocks based on whether a macro is defined—like having different versions of a document for different audiences.

**Key directives:**
- `` `ifdef MACRO ``: Compiles following code if MACRO is defined
- `` `ifndef MACRO ``: Compiles if MACRO is *not* defined
- `` `else ``: Alternative code block
- `` `endif ``: Ends the conditional block

**Example: Debug vs. Production Builds**
```systemverilog
`define ENABLE_DEBUG  // Comment this line to disable debug output

module traffic_light_controller;
  logic [1:0] state;
  logic [7:0] timer;

  initial begin
    state = 2'b00;  // Red light
    timer = 8'd0;

    `ifdef ENABLE_DEBUG
      $display("DEBUG: Initial state = %b, timer = %0d", state, timer);
    `endif

    // Main controller logic
    #10ns timer = timer + 1;
    
    `ifdef ENABLE_DEBUG
      $display("DEBUG: After 10ns - state = %b, timer = %0d", state, timer);
    `endif
  end
endmodule
```

**Workflow:**
1. With `` `define ENABLE_DEBUG `` active: Debug messages print during simulation
2. To disable debug: Simply comment out or remove the `` `define ENABLE_DEBUG `` line
3. Recompile: Debug code is excluded from the final compiled simulation

This approach is cleaner than manually commenting/uncommenting debug statements throughout your code.

## Scope of Macro Definitions

Macros follow **file-level scope**—they're active from their point of definition to the end of the file where they're defined. This is similar to how a term defined in a glossary applies only to that chapter unless redefined elsewhere.

**Important implications:**
1. **Visibility**: A macro defined in `file_a.sv` isn't automatically available in `file_b.sv`
2. **Redefinition**: Later definitions override earlier ones in the same file
3. **Sharing**: To use a macro across multiple files, define it in a common header file and `` `include `` it where needed

**Example: Demonstrating Scope**
```systemverilog
// file_definitions.sv
`define SHARED_CONSTANT 42
`define FILE_SPECIFIC_MSG "Defined in file_definitions.sv"

// file_usage.sv
// Note: SHARED_CONSTANT is NOT available here unless we redefine or include
`ifdef SHARED_CONSTANT
  // This block won't compile in file_usage.sv
  $display("This won't execute");
`else
  $display("SHARED_CONSTANT is not defined in this file");
`endif

// To share macros between files, use an include file:
// In both files: `include "shared_macros.svh"
```

## Predefined Macros: Built-in Helpers

SystemVerilog provides several automatically available macros that give you contextual information about your code—like having automatic footnotes that insert the current page number or chapter title.

| Macro | What It Provides | Practical Use Case |
|-------|------------------|---------------------|
| `` `__LINE__ `` | Current line number (integer) | Pinpointing error locations in assertions |
| `` `__FILE__ `` | Current filename (string) | Logging which module generated a message |
| `` `__TIME__ `` | Compilation time (hh:mm:ss) | Timestamping simulation runs |
| `` `__DATE__ `` | Compilation date (Mmm dd yyyy) | Version tracking and build identification |
| `` `__SYSTEMVERILOG__ `` | IEEE 1800 version number | Conditional code for different simulator versions |

**Example: Using Predefined Macros for Diagnostics**
```systemverilog
module diagnostic_example;
  initial begin
    // These macros expand automatically during preprocessing
    $display("=== Simulation Information ===");
    $display("File: %s", `__FILE__);
    $display("Line: %0d`, `__LINE__);
    $display("Compiled at: %s on %s", `__TIME__, `__DATE__);
    $display("SystemVerilog version: %0d", `__SYSTEMVERILOG__);
  end
endmodule
```

These predefined macros are invaluable for adding contextual information to simulation outputs, assertions, and log messages—making debugging and tracking much easier.

## Best Practices for Macros

- **Use UPPERCASE for macro names**: Improves readability and distinguishes macros from regular identifiers
- **Keep macros concise**: Best for short, frequently used snippets; avoid overly complex macros
- **Document macros clearly**: Explain purpose, parameters (if any), and usage for maintainability
- **Use parameterized macros judiciously**: Only when parameterization genuinely simplifies code or provides significant reusability
- **Avoid macro redefinition**: Use `` `undef `` explicitly before redefining to prevent confusion
- **Leverage conditional compilation**: Use `` `ifdef ``/`` `else ``/`` `endif `` for managing build configurations and feature flags
- **Utilize predefined macros**: Leverage `` `__LINE__ ``, `` `__FILE__ ``, etc., for contextual information in messages
- **Consider alternatives for complex logic**: For intricate operations, prefer functions, tasks, or classes over macros
- **Parenthesize macro expressions**: When defining macros that represent expressions, enclose them in parentheses to preserve operator precedence
- **Avoid trailing semicolons**: Unless intentionally part of the substitution, don't include semicolons at macro definition ends

## Common Pitfalls and How to Avoid Them

### 1. Operator Precedence Issues
**Problem:** Macros perform simple text substitution, which can alter operator precedence.
```systemverilog
`define MULTIPLY(a, b) a * b  // No parentheses

module precedence_issue;
  initial begin
    $display("Result: %0d", 2 + `MULTIPLY(3, 4)); 
    // Expands to: 2 + 3 * 4 = 2 + 12 = 14 (not 2*(3+4)=20)
  end
endmodule
```
**Solution:** Parenthesize expression macros:
```systemverilog
`define MULTIPLY(a, b) ((a) * (b))
```

### 2. Unexpected Token Pasting
**Problem:** Adjacent tokens can merge unexpectedly after substitution.
```systemverilog
`define BUS_WIDTH 8
logic [`BUS_WIDTH-1:0] data;  // Becomes logic [8-1:0] - WRONG!
```
**Solution:** Ensure proper spacing or use parentheses:
```systemverilog
`define BUS_WIDTH 8
logic [(`BUS_WIDTH)-1:0] data;  // Correct: [7:0]
```

### 3. Multi-line Macro Pitfalls
**Problem:** Forgetting line continuation characters can cause syntax errors in multi-line macros.
**Solution:** Always end lines with `\` except the last line, and ensure proper formatting.

## Practical Exercises

### Exercise 1: Parameterizable FIFO
Create a FIFO module where depth and width are set via macros:
1. Define `FIFO_DEPTH` and `DATA_WIDTH` macros
2. Use them to size internal arrays and port widths
3. Write a testbench that displays the parameters using the macros
4. Experiment by changing the macro values and resimulating

### Exercise 2: Feature Toggles
Design a UART module with optional features:
1. Create `FEATURE_FIFO` and `FEATURE_PARITY` macros
2. Use `` `ifdef `` to conditionally include FIFO buffers and parity logic
3. Test with features enabled/disabled by defining/undefining the macros

### Exercise 3: Self-Documenting Assertions
Create an assertion macro that:
1. Takes a condition, message, and severity (warning/error)
2. Uses `` `__FILE__ `` and `` `__LINE__ `` for location
3. Reports appropriately based on severity
4. Demonstrates in a testbench with various conditions

## Summary

SystemVerilog macros are a powerful preprocessing tool that enhances code maintainability and flexibility through textual substitution. By understanding their scope, types, and best practices, you can:
- Eliminate redundant code with meaningful constants
- Create reusable, parameterized code templates
- Conditionally compile features for different build configurations
- Leverage predefined macros for self-documenting code

Remember that macros operate purely at the text level—they don't understand SystemVerilog syntax. For complex logic, always consider whether functions, tasks, or classes might be a better fit. When used judiciously, macros significantly improve design clarity and adaptability.

> **Remember**: Macros are like kitchen gadgets—excellent for specific tasks (peeling, slicing) but not a replacement for proper cooking techniques (algorithmic thinking). Use them for what they do best: simple, repetitive text substitutions that make your code cleaner and more flexible.

## Introduction: Streamlining Code with Textual Macros

Imagine you're writing a long technical document and find yourself typing the same complex phrase—like "asynchronous transfer mode protocol"—over and over. Instead of retyping it each time, you create a shortcut that automatically expands to the full phrase. SystemVerilog macros work similarly—they're a preprocessor feature that performs textual substitution *before* compilation, acting like smart find-and-replace for your code.

**Why use macros?**
- **Reduce repetition**: Define a complex expression once and reuse it everywhere
- **Improve readability**: Replace cryptic numbers with meaningful names (like `DATA_WIDTH` instead of `32`)
- **Enable flexibility**: Change behavior across your entire design by modifying a single definition
- **Support conditional compilation**: Include or exclude code sections based on project needs

Think of the SystemVerilog preprocessor as a preparation step that runs before your compiler sees the code. It handles macros, file includes (\`include), and conditional compilation directives.

## Introduction: Streamlining Code with Textual Macros

Imagine you're writing a long technical document and find yourself typing the same complex phrase—like "asynchronous transfer mode protocol"—over and over. Instead of retyping it each time, you create a shortcut that automatically expands to the full phrase. SystemVerilog macros work similarly—they're a preprocessor feature that performs textual substitution *before* compilation, acting like smart find-and-replace for your code.

**Why use macros?**
- **Reduce repetition**: Define a complex expression once and reuse it everywhere
- **Improve readability**: Replace cryptic numbers with meaningful names (like `DATA_WIDTH` instead of `32`)
- **Enable flexibility**: Change behavior across your entire design by modifying a single definition
- **Support conditional compilation**: Include or exclude code sections based on project needs

Think of the SystemVerilog preprocessor as a preparation step that runs before your compiler sees the code. It handles macros, file includes (`include`), and conditional compilation directives.

## Defining and Using Macros

SystemVerilog macros are defined using the `` `define `` directive and undefined using the `` `undef `` directive. They are invoked by preceding the macro name with a backtick `` ` `` (grave accent).

### `` `define ``: Defining Macros

The `` `define `` directive is used to create a macro, associating a name with a specific text or code snippet.

**Syntax:**

```systemverilog
`define MACRO_NAME macro_text
```

-   **`\`define**: The directive keyword that initiates macro definition.
-   **`MACRO_NAME`**: The identifier chosen as the name of the macro. Macro names typically follow uppercase convention for better readability and to distinguish them from SystemVerilog identifiers.
-   **`macro_text`**: The text or code snippet that will be substituted wherever `MACRO_NAME` is used in the code. This can be any valid SystemVerilog code, including expressions, statements, or even module declarations.

**Example: Defining a Macro for Data Width**

```systemverilog
`define DATA_WIDTH 32

module macro_example;
  logic [`DATA_WIDTH-1:0] data_bus; // Using the DATA_WIDTH macro

  initial begin
    $display("Data bus width: %0d", `DATA_WIDTH); // Macro substitution in display
  end
endmodule
```

In this example, `` `define DATA_WIDTH 32 `` defines a macro named `DATA_WIDTH` that substitutes to the text `32`. Wherever `` `DATA_WIDTH `` is encountered in the code, it will be replaced by `32` during preprocessing.

### `` `undef ``: Undefining Macros

The `` `undef `` directive is used to remove a macro definition, effectively making the macro name undefined from that point onwards in the code.

**Syntax:**

```systemverilog
`undef MACRO_NAME
```

-   **`\`undef**: The directive keyword for undefining a macro.
-   **`MACRO_NAME`**: The name of the macro to be undefined.

**Example: Undefining the DATA_WIDTH Macro**

```systemverilog
`define DATA_WIDTH 32

module undef_example;
  logic [`DATA_WIDTH-1:0] data_bus_1;

  initial begin
    $display("Data bus 1 width: %0d", `DATA_WIDTH);

    `undef DATA_WIDTH // Undefine the DATA_WIDTH macro

    // logic [`DATA_WIDTH-1:0] data_bus_2; // This would now cause an error as DATA_WIDTH is undefined

    $display("DATA_WIDTH macro is now undefined.");
  end
endmodule
```

After `` `undef DATA_WIDTH ``, any subsequent use of `` `DATA_WIDTH `` will result in a preprocessing error because the macro is no longer defined.

## Types and Applications of Macros

SystemVerilog macros can be broadly categorized based on their usage and complexity:

### Simple Text Substitution Macros

These are the most basic type of macros, primarily used for replacing a macro name with a fixed text or value. They enhance readability and maintainability by providing symbolic names for constants or frequently used expressions.

**Example: Defining Macros for Clock Period and Reset Value**

```systemverilog
`define CLK_PERIOD 10ns
`define RST_VAL 1'b0

module simple_macros;
  timeunit 1ns; timeprecision 1ps;
  logic clk;
  logic rst;

  initial begin
    clk = 0;
    rst = `RST_VAL; // Using RST_VAL macro

    forever #(`CLK_PERIOD/2) clk = ~clk; // Using CLK_PERIOD macro
  end

  initial begin
    #5ns rst = ~`RST_VAL;
    #20ns rst = `RST_VAL;
  end
endmodule
```

### Parameterized Macros

SystemVerilog macros can also accept arguments, making them behave like simple functions during preprocessing. This allows for creating more flexible and reusable code templates.

**Syntax:**

```systemverilog
`define MACRO_NAME(parameter1, parameter2, ...) macro_text_using_parameters
```

-   **`MACRO_NAME(parameter1, parameter2, ...)`**: Macro definition with a parameter list enclosed in parentheses.
-   **`macro_text_using_parameters`**: The macro text that can now include the parameters defined in the parameter list.

**Example: Defining a Parameterized Macro for Assertions**

```systemverilog
`define ASSERT_TRUE(condition, message) \
  if (!(condition)) begin \
    $error("Assertion Failed: %s at line %0d in file %s", message, `__LINE__, `__FILE__); \
    $fatal; \
  end

module parameterized_macro_example;
  logic a, b;

  initial begin
    a = 1; b = 0;

    `ASSERT_TRUE(a == 1, "Variable 'a' should be 1"); // Using parameterized macro
    `ASSERT_TRUE(b == 1, "Variable 'b' should be 1"); // This assertion will fail
  end
endmodule
```

In this example, `ASSERT_TRUE` is a parameterized macro that takes a condition and a message as arguments. When invoked, it checks the condition and reports an error if it's false, along with the provided message, line number, and filename using predefined macros `` `__LINE__ `` and `` `__FILE__ ``.

### Conditional Compilation Macros

Macros are extensively used for conditional compilation, allowing you to include or exclude sections of code based on macro definitions. This is achieved using the `` `ifdef ``, `` `else ``, `` `elsif ``, and `` `endif `` directives.

**Syntax:**

```systemverilog
`ifdef MACRO_NAME
  // Code to be compiled if MACRO_NAME is defined
`else
  // Code to be compiled if MACRO_NAME is not defined
`endif
```

-   **`\`ifdef MACRO_NAME`**: Checks if `MACRO_NAME` is currently defined.
-   **`\`else`**:  Optional clause; code within `` `else `` is compiled if the condition in `` `ifdef `` is false.
-   **`\`elsif (condition)`**: Optional clause for nested conditional compilation.
-   **`\`endif`**: Marks the end of the conditional compilation block.

**Example: Conditional Compilation for Debug Mode**

```systemverilog
`define DEBUG_MODE // Define DEBUG_MODE macro to enable debug code

module conditional_compilation;
  logic [7:0] data;

  initial begin
    data = 8'h55;

    `ifdef DEBUG_MODE
      $display("DEBUG: Data value before processing: %h", data); // Debug output
    `endif

    data = data << 1; // Data processing

    `ifdef DEBUG_MODE
      $display("DEBUG: Data value after processing: %h", data); // Debug output
    `endif

    $display("Final data value: %h", data);
  end
endmodule
```

In this example, the debug display statements are only compiled and executed if the `DEBUG_MODE` macro is defined. To disable debug output, simply comment out or remove the `` `define DEBUG_MODE `` line.

## Scope of Macro Definitions

Macro definitions in SystemVerilog have a file-level scope. Once a macro is defined using `` `define ``, it is effective from that point onwards in the current file.

-   **File Scope**: Macros are only visible and applicable within the file where they are defined. If you need to use a macro in multiple files, you must define it in each file or include a common header file containing the macro definitions.
-   **Definition Order**: The order of macro definitions matters. If you redefine a macro with the same name later in the same file, the new definition will override the previous one from that point forward.
-   **No Module or Package Scope**: Macros are not scoped to modules, packages, or any other SystemVerilog constructs. They are strictly preprocessor directives operating at the file level.

**Example: Macro Scope Demonstration**

```systemverilog
// file1.sv
`define MSG_FILE1 "Message from file1.sv"

module module1;
  initial begin
    $display("Module 1: `%MSG_FILE1`"); // Macro MSG_FILE1 is defined here
  end
endmodule


// file2.sv
// `define MSG_FILE2 "Message from file2.sv" // Uncommenting this line will define MSG_FILE2 in file2.sv

module module2;
  initial begin
    // $display("Module 2: `%MSG_FILE1`"); // This would cause an error in file2.sv if MSG_FILE1 is not defined in file2.sv or included file.
    `ifdef MSG_FILE2
      $display("Module 2: `%MSG_FILE2`"); // Macro MSG_FILE2 is conditionally used
    `else
      $display("Module 2: MSG_FILE2 is not defined in this file.");
    `endif
  end
endmodule
```

In this example, `MSG_FILE1` is defined in `file1.sv` and can be used within `module1`. If `module2` in `file2.sv` attempts to use `MSG_FILE1` without it being defined in `file2.sv` or included, it will result in an error. `MSG_FILE2` is conditionally used in `file2.sv` and will only display a message if `MSG_FILE2` is defined in `file2.sv`.

## Predefined Macros

SystemVerilog provides several predefined macros that are automatically available in all SystemVerilog code. These macros provide useful information about the compilation environment and code context.

| Predefined Macro                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        
| `` `__LINE__ ``                                             | Expands to the current line number in the source code file as an integer. Useful for error reporting and debugging messages to indicate the location of an event.                                                                                                                                                                                                                                                                                                                                                                                                                                     | `42`                                                                                                                                                                                                       |
| `` `__FILE__ ``                                             | Expands to the current file name as a string. Useful for logging and error messages to identify the source file.                                                                                                                                                                                                                                                                                                                                                                                                                                   | `"my_module.sv"`                                                                                                                                                                                                       |
| `` `__TIME__ ``                                             | Expands to the current simulation time as a string in `hh:mm:ss` format. Useful for timestamping simulation events and messages.                                                                                                                                                                                                                                                                                                                                                                       | `"09:30:15"`                                                                                                                                                                                                       |
| `` `__DATE__ ``                                             | Expands to the current date of compilation as a string in `Mmm dd yyyy` format (e.g., "Mar 06 2025"). Useful for version control and build identification.                                                                                                                                                                                                                                                                                                                                                                 | `"Mar 06 2025"`                                                                                                                                                                                                       |
| `` `__SYSTEMVERILOG__ ``                                 | A version number indicating SystemVerilog support by the simulator. Can be used for conditional compilation to handle different SystemVerilog language feature support levels.                                                                                                                                                                                                                                                                                                                                                                       | `201800` (Example - YearMonth * 100)                                                                                                                                                                                                       |

**Example: Using Predefined Macros for Version and Timestamp Information**

```systemverilog
module predefined_macros_example;
  initial begin
    $display("--- Compilation Information ---");
    $display("File name: %s", `__FILE__); // Display current file name
    $display("Line number: %0d", `__LINE__); // Display current line number
    $display("Compilation time: %s", `__TIME__); // Display compilation time
    $display("Compilation date: %s", `__DATE__); // Display compilation date
    $display("SystemVerilog version: %0d", `__SYSTEMVERILOG__); // Display SystemVerilog version
  end
endmodule
```

These predefined macros are invaluable for adding contextual information to simulation outputs, assertions, and log messages, making debugging and tracking easier.

## Best Practices for Macros

-   **Use Uppercase for Macro Names**: Adopt the convention of using uppercase names for macros (e.g., `DATA_WIDTH`, `DEBUG_MODE`). This improves code readability and clearly distinguishes macros from regular SystemVerilog identifiers.
-   **Keep Macros Concise**: Macros are best suited for short, frequently used code snippets or constants. Avoid defining overly complex or lengthy macros, as they can reduce code readability and increase preprocessing time. For complex logic, use functions or tasks instead.
-   **Document Macros Clearly**: Document each macro's purpose, parameters (if any), and usage. This is crucial for maintainability and allows other users to understand and effectively utilize the defined macros.
-   **Use Parameterized Macros Judiciously**: While parameterized macros offer flexibility, overuse can make code harder to understand and debug. Use them when the parameterization genuinely simplifies the code or provides significant reusability.
-   **Avoid Macro Redefinition**: Be cautious about redefining macros, as it can lead to confusion and unexpected behavior. If redefinition is necessary, use `` `undef `` to explicitly undefine the macro before redefining it.
-   **Use Conditional Compilation for Configuration**: Leverage conditional compilation macros (`` `ifdef ``, `` `else ``, `` `endif ``) for managing different build configurations, enabling/disabling features, and targeting specific platforms.
-   **Utilize Predefined Macros**: Take advantage of predefined macros like `` `__LINE__ ``, `` `__FILE__ ``, `` `__TIME__ ``, `` `__DATE__ ``, and `` `__SYSTEMVERILOG__ `` for adding valuable context to your code, especially in assertions, error messages, and version control.
-   **Consider Alternatives for Complex Logic**: For complex code logic or operations, prefer using SystemVerilog functions, tasks, or classes over macros. Macros are primarily for textual substitution and simpler code abstractions.

## Comprehensive Directive Reference Table

| Directive                                      | Description                                                                                                                                                                                                   | Syntax                                                                                                                                                                                                         | Notes                                                                                                                                           |
| :------------------------------------------------- | :--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `` `define MACRO_NAME macro_text ``                 | Defines a macro named `MACRO_NAME` that will be replaced by `macro_text` during preprocessing.                                                                                                                                                                                                                                                                                                                                                                   | `` `define MACRO_NAME macro_text `` | Macro names are conventionally uppercase. `macro_text` can be any valid SystemVerilog code. Macros are file-scoped.                                                                                                                                                                                                                                                                                                                                                               |
| `` `define MACRO_NAME(param1, param2, ...) macro_text `` | Defines a parameterized macro `MACRO_NAME` that accepts parameters.                                                                                                                                                                                                                                                                                                                                                           | `` `define MACRO_NAME(param1, param2) macro_text `` | Parameters are comma-separated and enclosed in parentheses. Parameters can be used within `macro_text`.                                                                                                                                                                                                                                                                                                                                                               |
| `` `undef MACRO_NAME ``                                   | Undefines the macro `MACRO_NAME`, making it no longer recognized by the preprocessor from that point onwards.                                                                                                                                                                                                                                                                                                                                                           | `` `undef MACRO_NAME ``                                                                                                                                                                                                         | Use to limit the scope of a macro or to resolve macro redefinition warnings.                                                                                                                                           |
| `` `ifdef MACRO_NAME ... `else ... `endif ``       | Conditionally compiles code based on whether `MACRO_NAME` is defined.                                                                                                                                                                                                                                                                                                                                                   | `` `ifdef MACRO_NAME ... `else ... `endif `` | Use for conditional compilation, e.g., for debug code, platform-specific code, or feature toggling. `` `else `` and `` `elsif `` are optional.                                                                                                                                                                                                                                                                                                                                                   |

## Robust Macro Usage and Error Prevention

While macros are powerful, improper use can lead to subtle errors. Robust macro usage involves careful definition and application to avoid common pitfalls.

### Avoiding Macro Redefinition

Redefining a macro without undefining it first can lead to warnings or errors, and potentially unexpected behavior if the macro is used in different parts of the code with different intended meanings.

**Best Practice:** If you need to redefine a macro, always use `` `undef `` to explicitly undefine it before providing a new definition.

**Example: Safe Macro Redefinition**

```systemverilog
`define VERSION_MAJOR 1
`define VERSION_MINOR 0

module macro_redefinition_example;
  initial begin
    $display("Initial Version: %0d.%0d", `VERSION_MAJOR, `VERSION_MINOR);

    `undef VERSION_MINOR // Undefine VERSION_MINOR before redefinition
    `define VERSION_MINOR 1 // Redefine VERSION_MINOR

    $display("Updated Version: %0d.%0d", `VERSION_MAJOR, `VERSION_MINOR);
  end
endmodule
```

### Handling Undefined Macros

Using a macro that has not been defined will result in a preprocessing error. Ensure that all macros are defined before they are used, or use conditional compilation to handle cases where a macro might not be defined.

**Best Practice:** Use `` `ifdef `` or `` `ifndef `` to conditionally check if a macro is defined before using it, especially when dealing with optional macros or macros defined in external include files.

**Example: Conditional Usage of a Macro**

```systemverilog
module undefined_macro_check;
  initial begin
    `ifdef FEATURE_ENABLED // Check if FEATURE_ENABLED is defined
      $display("Feature is enabled: %s", `FEATURE_NAME); // Use FEATURE_NAME only if FEATURE_ENABLED is defined
    `else
      $display("Feature is disabled.");
    `endif
  end
endmodule
```

In this example, the code conditionally checks if `FEATURE_ENABLED` is defined. If it is, it proceeds to use `FEATURE_NAME`; otherwise, it executes the `` `else `` block, preventing an error if `FEATURE_NAME` is not defined when `FEATURE_ENABLED` is not set.

### Preventing Unintended Substitutions

Macros perform simple textual substitution, which can sometimes lead to unintended results if not used carefully, especially with complex expressions or operator precedence.

**Best Practices:**

-   **Enclose Macro Text in Parentheses**: When defining macros that represent expressions, especially arithmetic or logical expressions, enclose the macro text in parentheses to ensure correct operator precedence after substitution.
-   **Be Mindful of Semicolons**: Avoid including trailing semicolons at the end of macro definitions unless the semicolon is intended to be part of the substituted text. Unintended semicolons can lead to syntax errors.

**Example: Preventing Operator Precedence Issues**

```systemverilog
`define CALC_SUM(a, b) a + b // Macro without parentheses

module precedence_issue_example;
  initial begin
    $display("Incorrect Sum: %0d", 2 * `CALC_SUM(3, 4)); // Becomes 2 * 3 + 4 = 10 (incorrect)
  end
endmodule

`define CALC_SUM_PARENTHESES(a, b) (a + b) // Macro with parentheses

module precedence_fixed_example;
  initial begin
    $display("Correct Sum: %0d", 2 * `CALC_SUM_PARENTHESES(3, 4)); // Becomes 2 * (3 + 4) = 14 (correct)
  end
endmodule
```

In the `precedence_issue_example`, without parentheses, the macro substitution leads to incorrect operator precedence. In `precedence_fixed_example`, enclosing the macro text in parentheses ensures the intended order of operations.

## Best Practices Checklist for SystemVerilog Macros

- **Use Uppercase for Macro Names**: Yes/No
- **Keep Macros Concise**: Yes/No
- **Document Macros Clearly**: Yes/No
- **Use Parameterized Macros Judiciously**: Yes/No
- **Avoid Macro Redefinition**: Yes/No
- **Use Conditional Compilation for Configuration**: Yes/No
- **Utilize Predefined Macros**: Yes/No
- **Consider Alternatives for Complex Logic**: Yes/No
- **Enclose Macro Expressions in Parentheses**: Yes/No
- **Avoid Trailing Semicolons in Macro Definitions**: Yes/No
- **Conditionally Check for Macro Definition Before Use**: Yes/No

## Practical Exercises to Solidify Macro Skills

1.  **Data Width Parameterization with Macros**:
    -   Create a module that implements a simple FIFO.
    -   Parameterize the FIFO depth and data width using macros (`FIFO_DEPTH`, `DATA_WIDTH`).
    -   Use these macros within the FIFO module to define array sizes and signal widths.
    -   Instantiate the FIFO module in a testbench and display the FIFO depth and data width using the macros.
    -   Compile and simulate the design, experimenting with different macro definitions for `FIFO_DEPTH` and `DATA_WIDTH`.

2.  **Conditional Feature Compilation**:
    -   Design a module with optional features (e.g., error injection, logging).
    -   Use conditional compilation macros (`FEATURE_ERROR_INJECTION`, `FEATURE_LOGGING`) to enable or disable these features.
    -   Implement code blocks for error injection and logging that are conditionally compiled based on the macro definitions.
    -   Create a testbench to exercise the module with and without these features enabled by defining or undefining the corresponding macros.

3.  **Parameterized Assertion Macros**:
    -   Define a parameterized assertion macro `ASSERT_RANGE(value, min, max, message)` that checks if a given `value` is within the specified `min` and `max` range.
    -   Use predefined macros `` `__LINE__ `` and `` `__FILE__ `` in the assertion macro to provide location information in error messages.
    -   In a testbench, use `ASSERT_RANGE` to check various signal values and ranges.
    -   Simulate the testbench and observe the assertion messages when range violations occur.

4.  **Version Control Macro**:
    -   Define macros for `VERSION_MAJOR`, `VERSION_MINOR`, and `VERSION_PATCH` to represent the design version.
    -   Incorporate these version macros into a module that represents the overall design.
    -   Use `` `__DATE__ `` macro to automatically include the compilation date as part of the version information.
    -   Display the complete version information (including version numbers and compilation date) at the start of simulation.
    -   Update the version macros and recompile to observe the version information changes in the simulation output.

5.  **Include File for Common Macros**:
    -   Create a separate include file (e.g., `macros.svh`) and define common macros like `CLK_PERIOD`, `RST_VAL`, `TIMEOUT`, and `DEBUG_MODE` in this file.
    -   In multiple SystemVerilog modules and testbenches, include the `macros.svh` file using the `` `include `` directive.
    -   Use the macros defined in `macros.svh` across different files.
    -   Modify the macro definitions in `macros.svh` and recompile to observe the changes reflected in all files that include this header.

```systemverilog
// Sample Solution for Exercise 2: Conditional Feature Compilation (Logging)
`define FEATURE_LOGGING // Define FEATURE_LOGGING to enable logging

module feature_conditional_compilation;
  logic clk;
  logic [7:0] data_in, data_out;

  always @(posedge clk) begin
    data_out <= data_in;

    `ifdef FEATURE_LOGGING
      $display("LOG: At time %0t, data_in = %h, data_out = %h", $time, data_in, data_out); // Conditional logging
    `endif
  end

  initial begin
    clk = 0;
    forever #5ns clk = ~clk;
  end

  initial begin
    #10ns data_in = 8'hAA;
    #20ns data_in = 8'h55;
    #30ns data_in = 8'hFF;
    #50ns $finish;
  end
endmodule
```

##### Copyright (c) 2026 squared-studio

