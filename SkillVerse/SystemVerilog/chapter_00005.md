# Arrays in SystemVerilog: A Deep Dive

_Arrays let you store collections of data—whether a handful of bits in a hardware register or thousands of test‑bench transactions. SystemVerilog offers several array styles, each tuned for a different use‑case. Understanding when and how to use each style makes your code clearer, faster, and easier to debug._

---

## Why Arrays Matter in SystemVerilog

| Analogy                                                                                                                         | SystemVerilog Concept                                                                                 |
| ------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| **A toolbox with labeled drawers** – each drawer holds a specific type of screw or nail.                                        | **Unpacked array** – each element is a separate “drawer” you can read or write individually.          |
| **A row of light‑switches on a wall** – you flip them together to set a binary pattern.                                         | **Packed array** – the switches are wired side‑by‑side so the whole row behaves as one binary number. |
| **A sticky‑note board** – you can add or remove notes whenever you need, and you look them up by a keyword written on the note. | **Associative array** – size changes at run‑time and you index by any key (string, enum, etc.).       |
| **A conveyor belt** – items are added at one end and removed from the other, preserving order.                                  | **Queue** – a FIFO/LIFO structure that grows and shrinks automatically.                               |

The rest of this chapter walks through each array type, shows how to declare and manipulate them, and points out the built‑in methods that SystemVerilog provides for common operations.

---

## Packed vs. Unpacked Arrays

### Packed Arrays – Bit‑Contiguous Storage

_Think of a packed array as a single hardware register: all its bits live next to each other in memory, just like the bits in a CPU register._

- **Declaration**: dimensions appear **before** the variable name.
- **Use case**: modeling registers, data buses, memory‑mapped interfaces, or any situation where you need to treat the whole group as a binary number.

```systemverilog
// 8‑bit register (one dimension)
logic [7:0] ctrl_reg;

// 4 × 16‑bit register file (two dimensions)
// Total width = 4 * 16 = 64 bits, stored contiguously
logic [3:0][15:0] register_file;

// Initialise the whole register file with a 64‑bit hex constant
register_file = 64'h1234_5678_9ABC_DEF0;

// Extract the high byte of the second register (index 1)
logic [7:0] high_byte;
high_byte = register_file[1][15:8];
```

**Why it matters**: Because the bits are contiguous, SystemVerilog can perform bit‑wise operations (e.g., `&`, `|`, `^`, shifts) on the whole array as if it were a single integer. This maps directly to hardware and yields optimal synthesis results.

### Unpacked Arrays – Element‑Based Storage

_An unpacked array is like a conventional software array: each element occupies its own slot in memory, and you access them with an index._

- **Declaration**: dimensions appear **after** the variable name.
- **Use case**: test‑bench data storage, scoreboards, FIFOs modeled in software, or any scenario where you need to manipulate individual elements rather than bits.

```systemverilog
// Storage for 1024 32‑bit transaction IDs
int transaction_ids [1024];

// Initialise all entries to 0 (using array literal with default)
transaction_ids = '{default:0};

// Write a value into the middle of the array
transaction_ids[512] = 32'hDEAD_BEEF;

// Read it back
int mid_val = transaction_ids[512];
```

**Key difference**: Packed arrays are _bit‑level_ containers; unpacked arrays are _element‑level_ containers. Choose packed when you need to treat the group as a binary word; choose unpacked when you need to work with each item separately.

---

## Fixed‑Size Arrays – Compile‑Time Length with Handy Methods

A fixed‑size array’s length is known when the code is compiled. This lets the tool allocate storage upfront and provides a rich set of built‑in methods for common tasks (sorting, summing, searching, etc.).

### Declaration & Basic Use

```systemverilog
// 5‑element array of signed integers
int scores[5] = '{95, 88, 76, 99, 82};

// Copy the array (element‑wise)
int sorted_scores[5] = scores;

// Sort in‑place (ascending)
sorted_scores.sort();

// Retrieve the largest value (last element after sort)
int max_score = sorted_scores[sorted_scores.size() - 1];
```

### Frequently Used Built‑In Methods

| Method                           | What it does                                             | Example                                           |
| -------------------------------- | -------------------------------------------------------- | ------------------------------------------------- |
| `.size()`                        | Number of elements                                       | `int n = scores.size();`                          |
| `.sort()` / `.rsort()`           | Sort ascending / descending (in‑place)                   | `scores.sort();`                                  |
| `.reverse()`                     | Flip element order (in‑place)                            | `scores.reverse();`                               |
| `.sum()`                         | Add all elements together                                | `int total = scores.sum();`                       |
| `.min()` / `.max()`              | Smallest / largest value                                 | `int lo = scores.min(); int hi = scores.max();`   |
| `.unique()`                      | Return a new array with duplicates removed               | `int uniq[$] = scores.unique();`                  |
| `.find()` / `.find_index()`      | Return indices of elements matching a condition          | `int idx[$] = scores.find(x) with (x > 90);`      |
| `.find_first()` / `.find_last()` | Return the first / last matching element                 | `int first = scores.find_first(x) with (x > 90);` |
| `.reduce()`                      | Apply a binary operator across the array (e.g., product) | `int prod = scores.reduce(*);`                    |

**Analogy**: Think of these methods as “ready‑made tools” in a workshop—you don’t have to write a loop to sum numbers; you just call `.sum()` and the tool does the work for you.

---

## Dynamic Arrays – Size Can Change at Run‑Time

When you don’t know how many items you’ll need until the simulation runs (e.g., variable‑length packets), a **dynamic array** is the right choice. You must explicitly allocate storage with `new[]`; you can later resize or free it.

### Basic Workflow

```systemverilog
// Declaration – no size yet
int packet_payload[];

// Allocate space for 6 packets
packet_payload = new[6];

// Fill with random data
foreach (packet_payload[i]) packet_payload[i] = $random;

// Double the capacity, preserving existing data
packet_payload = new[12] (packet_payload);

// Release the memory (size becomes 0)
packet_payload.delete();
```

### Core Methods

| Method                                                                         | Purpose                                        | Example                                      |
| ------------------------------------------------------------------------------ | ---------------------------------------------- | -------------------------------------------- |
| `.size()`                                                                      | Current number of allocated elements           | `int cur = packet_payload.size();`           |
| `new[N]`                                                                       | Allocate (or re‑allocate) N elements           | `packet_payload = new[20];`                  |
| `new[N](old)`                                                                  | Resize to N, copying as much as fits           | `packet_payload = new[15] (packet_payload);` |
| `.delete()`                                                                    | Free all storage                               | `packet_payload.delete();`                   |
| `.sort()`, `.rsort()`, `.reverse()`, `.sum()`, `.min()`, `.max()`, `.unique()` | Same element‑wise methods as fixed‑size arrays | `packet_payload.sort();`                     |

**When to use**: Use a dynamic array whenever the array length can vary during simulation (e.g., storing a list of received packets, building a histogram, or collecting coverage data).

---

## Associative Arrays – Key‑Value Look‑Up (Sparse Storage)

_An associative array works like a dictionary or hash table: you store a value and retrieve it later by supplying a key. The key can be any type—string, enum, even a struct—making this ideal for sparse memories, configuration tables, or error‑message look‑ups._

### Declaration & Simple Operations

```systemverilog
// Mapping from error code (string) to message (string)
string err_msg[string];

// Populate a couple of entries
err_msg["E001"] = "Invalid instruction";
err_msg["W010"] = "Clock glitch detected";

// Check existence before accessing
if (err_msg.exists("E001")) begin
  $display("Error: %s", err_msg["E001"]);
end

// How many entries do we have?
$display("Defined errors: %0d", err_msg.num());

// Iterate over all keys
string key;
if (err_msg.first(key)) begin
  $display("First: %s -> %s", key, err_msg[key]);
  while (err_msg.next(key)) begin
    $display("Next:  %s -> %s", key, err_msg[key]);
  end
end
```

### Essential Methods

| Method            | What it does                                           | Example                         |
| ----------------- | ------------------------------------------------------ | ------------------------------- |
| `.num()`          | Number of key‑value pairs                              | `int cnt = err_msg.num();`      |
| `.exists(key)`    | True if `key` is present                               | `if (err_msg.exists("E001")) …` |
| `.delete()`       | Remove all entries                                     | `err_msg.delete();`             |
| `.delete(key)`    | Remove a single entry                                  | `err_msg.delete("W010");`       |
| `.first(ref key)` | Assigns the smallest key (by iteration order) to `key` | `string k; err_msg.first(k);`   |
| `.next(ref key)`  | Returns the key after `key`                            | `err_msg.next(k);`              |
| `.prev(ref key)`  | Returns the key before `key`                           | `err_msg.prev(k);`              |
| `.last(ref key)`  | Assigns the largest key to `key`                       | `err_msg.last(k);`              |

**Why it’s useful**: If you need to model a memory with only a few used addresses (e.g., a sparse RAM with holes), an associative array uses far less memory than a huge flat array and still gives O(1) average lookup time.

---

## Queues – Ordered Lists with Fast Push/Pop

_A queue behaves like a line at a coffee shop: new customers join the back (`push_back`) and the person at the front is served first (`pop_front`). SystemVerilog queues also let you add or remove from the front (`push_front` / `pop_back`) and provide indexing, sorting, and reversal._

### Basic Example

```systemverilog
// Queue of transaction IDs (int)
int txn_q[$];

// Add two IDs to the back
txn_q.push_back(101);
txn_q.push_back(202);

// Peek at the front without removing
if (txn_q.size()) $display("Front ID = %0d", txn_q[0]);

// Remove and retrieve the front element
int served = txn_q.pop_front();   // served = 101

// Add an ID to the front (like a priority insert)
txn_q.push_front(999);

// Current queue now holds: {999, 202}
$display("Queue size = %0d", txn_q.size());
```

### Core Queue Methods

| Method                   | Action                       | Example                          |
| ------------------------ | ---------------------------- | -------------------------------- |
| `.size()`                | Number of elements           | `int qlen = txn_q.size();`       |
| `push_front(item)`       | Insert at front              | `txn_q.push_front(5);`           |
| `push_back(item)`        | Insert at back               | `txn_q.push_back(7);`            |
| `pop_front()`            | Remove & return front item   | `int x = txn_q.pop_front();`     |
| `pop_back()`             | Remove & return back item    | `int y = txn_q.pop_back();`      |
| `insert(index, item)`    | Insert at arbitrary position | `txn_q.insert(1, 42);`           |
| `delete(index)`          | Remove element at index      | `txn_q.delete(0);`               |
| `delete()`               | Clear the queue              | `txn_q.delete();`                |
| `.sort()` / `.reverse()` | Sort or reverse in‑place     | `txn_q.sort(); txn_q.reverse();` |

**Analogy**: A queue is a **conveyor belt** that can also run backward; you can slap items onto either end, pull them off either end, or even jump into the middle with `insert`.

---

## Quick‑Reference Cheat Sheet

| Array Type      | When to Use                                          | Declaration Example          | Key Methods                                                        |
| --------------- | ---------------------------------------------------- | ---------------------------- | ------------------------------------------------------------------ |
| **Packed**      | Bit‑level hardware (registers, buses)                | `logic [3:0][7:0] reg_file;` | Bitwise ops (`&`, `\|`, `^`, shifts), `.slice()` (via part‑select) |
| **Unpacked**    | Element‑level storage (test‑bench data, scoreboards) | `int data[1024];`            | `.size()`, `.sort()`, `.sum()`, `.find()`, etc.                    |
| **Fixed‑Size**  | Known constant length, want built‑in helpers         | `short unsigned vals[8];`    | All element methods plus `.size()`                                 |
| **Dynamic**     | Length unknown until run‑time, can grow/shrink       | `logic payload[];`           | `new[N]`, `delete()`, `.size()`, element methods                   |
| **Associative** | Sparse look‑ups, keyed by non‑int types              | `string cache[string];`      | `.exists()`, `.num()`, `.first()`, `.next()`, `.delete(key)`       |
| **Queue**       | FIFO/LIFO streams, reordering, priority inserts      | `int fifo[$];`               | `push_front/back`, `pop_front/back`, `insert`, `.size()`           |

---

## Exercises (with Solutions)

> **Tip:** Try to solve each problem on your own before peeking at the answer.

1. **Packed Array – Slice Extraction**  
   Declare a 24‑bit packed array `cfg` and assign it the value `24'hABCDEF`. Then extract the middle 8‑bits (`BC`) into a variable `mid`.

   ```systemverilog
   logic [23:0] cfg = 24'hABCDEF;
   logic [7:0]  mid = cfg[15:8];   // bits 15 downto 8 → 0xBC
   ```

2. **Unpacked Array – String List**  
   Create an unpacked array holding the names `["Ana","Ben","Cara","Dav"]`. Print each name with its index using a `foreach` loop.

   ```systemverilog
   string names[4] = '{"Ana","Ben","Cara","Dav"};
   foreach (names[i]) $display("[%0d] = %s", i, names[i]);
   ```

3. **Fixed‑Size Array – Sum & Average**  
   Given an array `int vals[6] = '{4,7,1,9,3,5};`, compute the sum and the average (as a real number).

   ```systemverilog
   int total = vals.sum();
   real avg  = vals.sum() / vals.size();
   $display("Sum = %0d, Avg = %0.2f", total, avg);
   ```

4. **Dynamic Array – Packet Buffer**  
   Build a dynamic array that stores packet lengths. Start with space for 4 packets, fill them with lengths `[10,20,30,40]`, then double the capacity and add two more packets of length 50 and 60. Finally print the whole array.

   ```systemverilog
   int pkt_len[];
   pkt_len = new[4];
   pkt_len = '{10,20,30,40};   // via array literal after allocation
   pkt_len = new[8] (pkt_len); // resize, keep existing data
   pkt_len[4] = 50;
   pkt_len[5] = 60;
   $display("Packet lengths: %p", pkt_len);
   ```

5. **Associative Array – Configuration Table**  
   Model a simple configuration where keys are module names (`string`) and values are enable flags (`bit`). Enable `"uart"` and `"spi"`, disable `"i2c"`. Then print whether `"uart"` is enabled.

   ```systemverilog
   bit cfg[string];
   cfg["uart"] = 1;
   cfg["spi"]  = 1;
   cfg["i2c"]  = 0;
   if (cfg["uart"]) $display("UART is enabled");
   else             $display("UART is disabled");
   ```

6. **Queue – Reverse and Discard Front**  
   Create a queue with `{5,10,15,20}`, reverse it, then remove the front element. Show the final queue contents.

   ```systemverilog
   int q[$] = '{5,10,15,20};
   q.reverse();   // now {20,15,10,5}
   q.pop_front(); // remove 20 → {15,10,5}
   $display("Final queue: %p", q);
   ```

---

## Wrap‑Up

SystemVerilog’s array families give you the flexibility to model anything from a single hardware register to a vast, sparsely populated memory map. By matching the array type to the problem—packed for bit‑wise hardware, unpacked for element‑wise test‑benches, dynamic for variable‑sized data, associative for keyed look‑ups, and queues for ordered streams—you write code that is **clearer**, **more efficient**, and **easier to maintain**.

Keep this cheat sheet handy, practice with the exercises, and soon you’ll reach for the right array instinctively, just like a seasoned engineer reaches for the right tool in a well‑organized workshop. Happy coding!

---

##### Copyright (c) 2026 squared-studio
