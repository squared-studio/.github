# SystemVerilog Array Manipulation: Boost Your Design Capabilities

_Arrays are the workhorse of any SystemVerilog testbench or RTL design. Mastering both simple indexing and the rich set of built‑in manipulation methods lets you store, search, sort, and reduce data with just a few lines of code._

---

## 1. Indexing: Getting to the Right Bit

Before we dive into the fancy methods, we need to understand how SystemVerilog lays out arrays in memory. Think of an array as a **multidimensional spreadsheet**:

- **Unpacked dimensions** (`[A][B][C]`) are the _rows, columns, sheets_ that tell the simulator how many separate elements exist.
- **Packed dimensions** (`[M:0]`) live _inside_ each element and describe how the element’s bits are arranged—like the cells inside a spreadsheet column that hold a multi‑digit number.

### 1.1 Example: A 3‑D Bank of Registers

```systemverilog
logic [127:0][7:0] my_array [8][64][32];
```

| Part                     | What it means                                                      | Analogy                                                                                     |
| ------------------------ | ------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| `[8][64][32]` (unpacked) | 8 banks × 64 rows × 32 columns = **16 384** separate elements.     | Imagine a library with 8 floors, each floor has 64 aisles, each aisle holds 32 shelves.     |
| `[127:0][7:0]` (packed)  | Each element is a **128 × 8‑bit matrix** → 1 024 bits (128 bytes). | Every shelf holds a ledger that is 128 lines long, each line containing 8 columns (a byte). |

#### Accessing Data

| Goal                        | Syntax                                      | What you get                                                           |
| --------------------------- | ------------------------------------------- | ---------------------------------------------------------------------- |
| Whole element (one ledger)  | `my_array[2][5][17]`                        | All 1 024 bits of the ledger on floor 2, aisle 5, shelf 17.            |
| One byte (one line)         | `my_array[1][3][20][byte_index]`            | Byte `byte_index` (0‑127) of that ledger.                              |
| One bit                     | `my_array[0][10][5][byte_index][bit_index]` | Bit `bit_index` inside the selected byte.                              |
| Byte slice (range of lines) | `my_array[4][25][10][15:0]`                 | Bytes 0‑15 (the first 16 lines) of the ledger.                         |
| Bit slice (nibble)          | `my_array[7][63][31][127][3:0]`             | Lower 4 bits of byte 127 in the ledger on floor 7, aisle 63, shelf 31. |

#### Iterating with `foreach`

```systemverilog
foreach (my_array[i,j,k])               // i = floor, j = aisle, k = shelf
  foreach (my_array[i][j][k][byte_index]) // walk through each byte of the ledger
    $display("F%0d A%0d S%0d B%0d: %h",
             i, j, k, byte_index,
             my_array[i][j][k][byte_index]);
```

**Key points to remember**

- **Packed dimension order** – the rightmost index changes fastest (least‑significant bit).
- **Memory layout** – packed arrays store bits contiguously (efficient for registers); unpacked arrays use pointers (often map to block RAM).
- **Synthesis hint** – unpacked dimensions tend to become RAM/ROM; packed dimensions become flip‑flops or register files.

---

## 2. Beyond Indexing: Built‑In Array Methods

SystemVerilog supplies a toolbox of methods that work **directly on dynamic arrays, queues, and associative arrays**. They let you search, sort, reduce, and transform data without writing explicit loops.

> **Note:** Fixed‑size arrays (e.g., `logic [7:0] mem[0:3]`) do **not** have these methods. Convert to a dynamic array (`logic [7:0] mem[]`) if you need them.

### 2.1 Searching & Filtering

| Method                           | What it returns                                            | Typical use                                    |
| -------------------------------- | ---------------------------------------------------------- | ---------------------------------------------- |
| `.find()`                        | Queue of **elements** matching a condition                 | “Give me all temperatures below 0°C.”          |
| `.find_index()`                  | Queue of **indices** of matching elements                  | “Where are the odd numbers?”                   |
| `.find_first()` / `.find_last()` | First / last matching element (or empty queue)             | “Locate the first packet with error flag set.” |
| `.unique()`                      | Queue of **distinct** values                               | “Remove duplicate IDs.”                        |
| `.unique_index()`                | Indices of the **first** occurrence of each distinct value | “Show where each unique ID first appears.”     |

**Example – finding bad sensor readings**

```systemverilog
int readings[] = {12, -5, 3, -8, 0, 7};
int below_zero[] = readings.find(x) with (x < 0);
$display("Below zero: %p", below_zero);
// Output: Below zero: '{-5, -8}
```

### 2.2 Sorting & Reordering

| Method       | Effect                      | Example              |
| ------------ | --------------------------- | -------------------- |
| `.sort()`    | Ascending order (in‑place)  | `numbers.sort();`    |
| `.rsort()`   | Descending order (in‑place) | `numbers.rsort();`   |
| `.reverse()` | Flip the order              | `numbers.reverse();` |
| `.shuffle()` | Random permutation          | `numbers.shuffle();` |

You can customize the comparison with a `with` clause:

```systemverilog
string names[] = {"Alice","Bob","Christopher"};
names.sort() with (x.len());   // shortest name first
$display("Sorted by length: %p", names);
// Output: Sorted by length: '{"Bob","Alice","Christopher"}
```

### 2.3 Reduction (Sum, Product, Min, Max)

| Method                        | Returns                                    | When to use                           |
| ----------------------------- | ------------------------------------------ | ------------------------------------- |
| `.sum()`                      | Total of all elements                      | “How many cycles did we see?”         |
| `.product()`                  | Product of all elements                    | Rare in verification; watch overflow. |
| `.min()` / `.max()`           | Smallest / largest value                   | “Find the worst‑case latency.”        |
| `.and()` / `.or()` / `.xor()` | Bitwise reduction across **packed** arrays | Parity, flag aggregation.             |

**Example – parity of a data bus**

```systemverilog
logic [7:0] data_bytes[] = {8'hA5, 8'h3C, 8'h7F};
logic parity = data_bytes.xor();   // XOR of all bytes → parity bit
$display("Parity = %b", parity);
```

### 2.4 Method Chaining

Because most methods return a queue, you can string them together:

```systemverilog
int values[] = {4,7,4,2,9,2};
int sum_unique = values.unique().sum(); // {4,7,2,9} → 22
$display("Sum of unique values: %0d", sum_unique);
```

---

## 3. Worked Examples with Expected Output

### 3.1 Filtering Transaction Amounts

```systemverilog
class transaction;
  rand int amount;
endclass

transaction tx_q[]; // dynamic array of transaction objects
initial begin
  tx_q = new[5];
  foreach (tx_q[i]) begin
    tx_q[i] = new;
    tx_q[i].amount = i*250; // 0,250,500,750,1000
  end

  // Keep only those > $600
  transaction over600[] = tx_q.find(t) with (t.amount > 600);
  $display("Over $600: %p", over600);
end
// Output: Over $600: '{'{amount: 750}, '{amount: 1000}}
```

### 3.2 Bitwise AND Reduction on a Mask Array

```systemverilog
bit [3:0] mask[] = {4'b1100, 4'b1010, 4'b1111};
bit [3:0] combined = mask.and(); // 1100 & 1010 & 1111 = 1000
$display("Combined mask: %b", combined);
// Output: Combined mask: 1000
```

### 3.3 Unique Index Extraction

```systemverilog
int ids[] = {10,20,10,30,20,40};
int first_idx[] = ids.unique_index(); // indices of 10,20,30,40
$display("First occurrence indices: %p", first_idx);
// Output: First occurrence indices: '{0, 1, 3, 5}
```

---

## 4. Practical Exercises

1. **Byte Extraction** – Using the `my_array[8][64][32]` structure, extract bytes 64‑127 from `my_array[0][0][0]` and print them as hex.

2. **High‑Value Transactions** – Given a queue of `transaction` objects (each with an `amount` field), return a queue containing only those with `amount > 1000`.

3. **Packet Checksum** – For a dynamic array `byte packet[]` representing a network packet, compute the XOR checksum of all bytes _after_ the first four (header) bytes.

4. **Unique Random Addresses** – Generate 100 distinct 32‑bit addresses, store them in a dynamic array, then shuffle the array to randomize the order.

5. **Error Log Sorting** – You have an associative array `string err_code[string]` where the _value_ is a simulation time. Sort the error codes by their timestamps (ascending) and display the ordered list.

---

## 5. Pro‑Level Tips

| Tip                                   | Why it helps                                                                                                                                      | Example                                                                                                              |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| **Combine indexing with methods**     | Avoid temporary loops when you need a slice of every element.                                                                                     | `systemverilog logic [7:0] upper[8][64][32]; foreach (my_array[i,j,k]) upper[i][j][k] = my_array[i][j][k][127:64]; ` |
| **Use `with` for complex predicates** | Express multi‑condition filters in one readable line.                                                                                             | `systemverilog int hit = matrix.find_first() with (item inside {[10:20]} && (item % 2 == 0)); `                      |
| **Conditional reduction**             | Sum only the data that meets a criterion.                                                                                                         | `systemverilog int pos_sum = all_vals.sum() with (item > 0 ? item : 0); `                                            |
| **Preserve originals**                | Methods like `.sort()` modify in‑place; copy first if you need the original order.                                                                | `systemverilog int backup = original; original.sort(); // backup unchanged `                                         |
| **Leverage packed arrays for RTL**    | Bitwise reductions map efficiently to gates (XOR trees, AND/OR trees).                                                                            | `systemverilog logic [31:0] reg_file[0:15]; assign parity = reg_file[3].xor(); // one‑cycle parity tree `            |
| **Mind associative‑array cost**       | Operations like `.unique()` or `.sort()` on large associative arrays can be O(n log n); consider indexing keys separately if performance matters. | —                                                                                                                    |

---

### TL;DR

- **Indexing** gets you to the exact bit you need—think of unpacked dimensions as the library’s floors/aisles/shelves and packed dimensions as the lines/columns on each shelf.
- **Built‑in methods** (`.find`, `.sort`, `.sum`, `.xor`, …) let you query, reorder, and reduce data with minimal code.
- **Combine** indexing and methods, use `with` clauses for expressive conditions, and always remember whether a method works in‑place or returns a new queue.

With these tools in your belt, you can move from simple signal probing to sophisticated data‑driven testbenches and efficient RTL constructs—all while keeping your SystemVerilog code readable and maintainable. Happy coding!

##### Copyright (c) 2026 squared-studio
