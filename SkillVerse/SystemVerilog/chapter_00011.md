# Interprocess Communication (IPC) in SystemVerilog: Coordinating Parallel Processes

## Introduction

Imagine simulating a complex system where dozens of components operate simultaneously—like traffic lights coordinating cars at a busy intersection. In SystemVerilog, these concurrent components are modeled as _processes_. For the simulation to behave correctly, these processes need to communicate and synchronize: sharing data, signaling when tasks complete, or controlling access to shared resources (like a single-lane bridge). Without proper coordination, you’d get chaos—race conditions where data gets corrupted, or deadlocks where processes freeze waiting forever.

SystemVerilog provides three essential IPC mechanisms to prevent this chaos:

- **Mailboxes**: For sending structured data between processes (like passing notes in class).
- **Semaphores**: For controlling access to limited resources (like a bouncer managing club entry).
- **Events**: For simple signaling without data (like a traffic light turning green).

Mastering these lets you build realistic testbenches and accurate hardware models. This guide explains each mechanism with practical examples, analogies, and best practices—designed for newcomers to SystemVerilog.

---

## Mailboxes: Message Passing for Data Exchange

Think of a mailbox as a **type-safe post office** for your simulation processes. Processes drop messages (data packets) into it, and other processes pick them up. Crucially, SystemVerilog enforces _what type_ of message can go in—preventing mistakes like putting a letter in a package-only slot.

### Key Concepts

- **Bounded vs. Unbounded**:
  - _Bounded_: Fixed size (like a mailbox with 10 slots). Useful when resources are limited (e.g., modeling a network buffer).
  - _Unbounded_: Grows as needed (like a magical mailbox that never fills). Simpler but risks memory buildup if not managed.
- **Blocking vs. Non-blocking**:
  - _Blocking_: Process waits patiently (e.g., `put()` waits until space is free).
  - _Non-blocking_: Process checks quickly and moves on (e.g., `try_put()` returns immediately if full).

### Mailbox Methods at a Glance

| Method         | Action                                    | When to Use                                                     | Example                         |
| -------------- | ----------------------------------------- | --------------------------------------------------------------- | ------------------------------- |
| `put(msg)`     | **Block until** message is sent           | When you _must_ send data (e.g., critical transaction)          | `mailbox.put(packet);`          |
| `get(msg)`     | **Block until** message is received       | When you _must_ receive data (e.g., waiting for input)          | `mailbox.get(received_packet);` |
| `try_put(msg)` | **Try to send**; returns 1 if success     | When you can handle "no space" (e.g., skip and retry later)     | `if (mailbox.try_put(pkt)) ...` |
| `try_get(msg)` | **Try to receive**; returns 1 if success  | When mailbox might be empty (e.g., polling for data)            | `if (mailbox.try_get(pkt)) ...` |
| `peek(msg)`    | **Peek at next** message without removing | When you need to inspect but not consume (e.g., check priority) | `if (mailbox.peek(pkt)) ...`    |
| `num()`        | **Get current message count**             | For monitoring queue depth (e.g., throttle senders)             | `count = mailbox.num();`        |

### Creating Mailboxes

```systemverilog
// Unbounded: No size limit (default)
mailbox gen_mbox;
mailbox #(transaction) tx_mbox; // Type-safe for 'transaction' objects

// Bounded: Fixed capacity (e.g., 5 slots)
mailbox #(integer) int_mbox = new(5);
mailbox #(string) str_mbox = new(3);

// Instantiate unbounded boxes (required before use)
initial begin
  gen_mbox = new();
  tx_mbox  = new();
end
```

### Real-World Example: Assembly Line Simulation

```systemverilog
module assembly_line;
  typedef struct packed {
    int part_id;
    logic [15:0] weight;
  } part_t;

  // Bounded mailbox: Models conveyor belt with 2-slot buffer
  mailbox #(part_t) belt = new(2);

  // Producer: Robot arm placing parts
  initial begin : robot_arm
    part_t p;
    for (int i = 0; i < 5; i++) begin
      p.part_id = i;
      p.weight  = $urandom_range(10, 50); // Random weight
      if (belt.try_put(p)) begin
        $display("[%0t] Robot: Placed part %0d (weight %0d)", $time, i, p.weight);
      end else begin
        $display("[%0t] Robot: Belt FULL! Waiting...", $time);
        #5; // Brief pause before retry
        i--; // Retry same part
      end
      #($urandom_range(2, 8)); // Variable placement time
    end
  end

  // Consumer: Quality control station
  initial begin : qc_station
    part_t inspected;
    #10; // Start QC slightly later
    forever begin
      if (belt.try_get(inspected)) begin
        $display("[%0t] QC: Inspected part %0d (weight %0d)", $time, inspected.part_id, inspected.weight);
        if (inspected.part_id == 4) break; // Stop after 5 parts
      end else begin
        $display("[%0t] QC: Belt empty. Waiting...", $time);
      end
      #($urandom_range(3, 10)); // Variable inspection time
    end
    $finish;
  end
endmodule
```

**Why this works**:  
The bounded mailbox (`belt = new(2)`) models a real conveyor belt with limited space. The robot arm uses `try_put()` to avoid halting when the belt is full—instead, it waits briefly and retries. The QC station uses `try_get()` to avoid blocking when idle. This mimics real-world flow control!

### Mailbox Best Practices

- **Use bounded mailboxes + `try_put`/`try_get`** when modeling systems with buffer limits (e.g., network packets, FIFO buffers).
- **Always parameterize** (`mailbox #(type)`) to catch type errors early (e.g., accidentally sending an integer where a struct is expected).
- **Prefer blocking `put`/`get`** for simple producer-consumer where guaranteed delivery is critical (e.g., testbench scoreboard).
- **Use `peek()`** for lookahead logic (e.g., checking if a high-priority packet is next without removing it).

---

## Semaphores: Controlling Access to Shared Resources

Imagine a popular restaurant with only 3 tables. A **semaphore** acts like the host stand: it tracks how many tables are free (`count = 3`). Groups (processes) must "acquire" a table (`get()`) before dining. If all tables are taken, they wait until one frees up (`put()` when leaving). This prevents overcrowding and ensures fair access.

### Key Concepts

- **Mutex (Binary Semaphore)**: Semaphore initialized with `count = 1`. Only one process can access the resource at a time (like a single-key office door).
- **Counting Semaphore**: `count > 1` allows limited concurrent access (like the restaurant’s 3 tables).
- **Critical Section**: The code block accessing the shared resource (must be protected by `get()`/`put()`).

### Semaphore Methods Explained

| Method       | Action                                            | When to Use                                                                   | Example                   |
| ------------ | ------------------------------------------------- | ----------------------------------------------------------------------------- | ------------------------- |
| `get(n)`     | **Block until** `n` keys are available            | When exclusive/limited access is _required_ (e.g., updating a shared counter) | `sem.get(1);`             |
| `put(n)`     | Release `n` keys back (non-blocking)              | _Always_ call after finishing with resource                                   | `sem.put(1);`             |
| `try_get(n)` | **Try to acquire** `n` keys; returns 1 if success | When you can proceed without the resource (e.g., non-critical task)           | `if (sem.try_get(1)) ...` |
| `try_put(n)` | **Try to release** `n` keys (rarely used)         | Advanced scenarios (e.g., error recovery)                                     | `if (sem.try_put(1)) ...` |
| `num()`      | **Get current available keys**                    | For monitoring resource availability                                          | `free = sem.num();`       |

### Real-World Example: Shared Printer Queue

```systemverilog
module printer_shared;
  semaphore printer_sem = new(1); // Only 1 printer available (mutex)
  integer pages_printed = 0;

  // Employee 1: Printing a report
  initial begin : emp1
    $display("[%0t] Emp1: Waiting for printer...", $time);
    printer_sem.get(1); // Block until printer free
    $display("[%0t] Emp1: Printing report...", $time);
    pages_printed += 10; // CRITICAL SECTION: Access shared counter
    #15; // Simulate printing time
    printer_sem.put(1); // Release printer
    $display("[%0t] Emp1: Done. Pages printed: %0d", $time, pages_printed);
  end

  // Employee 2: Printing labels
  initial begin : emp2
    #5; // Start slightly later
    $display("[%0t] Emp2: Waiting for printer...", $time);
    printer_sem.get(1); // Waits here if Emp1 is printing
    $display("[%0t] Emp2: Printing labels...", $time);
    pages_printed += 5; // CRITICAL SECTION
    #10;
    printer_sem.put(1);
    $display("[%0t] Emp2: Done. Pages printed: %0d", $time, pages_printed);
  end

  initial begin
    #40 $finish;
  end
endmodule
```

**Output Insight**:  
Even though Emp2 starts at time 5, it _blocks_ at `get(1)` until Emp1 releases the printer at time ~15. This prevents both from incrementing `pages_printed` simultaneously (which could cause corruption).

### Semaphore Best Practices

- **Always pair `get()` with `put()`**: Forgetting to release causes starvation (others wait forever). Use `try-finally` patterns in complex code.
- **Use mutex (`new(1)`)** for simple exclusive access (e.g., protecting a single variable).
- **Use counting semaphores** for pools (e.g., `new(4)` for 4 identical DMA channels).
- **Prefer `try_get()`** when avoiding blocking is preferable (e.g., background tasks that can skip if busy).
- **Monitor with `num()`**: Log `sem.num()` to detect leaks (if count keeps dropping, keys aren’t being released).

---

## Events: Process Synchronization without Data Transfer

Think of an event as a **traffic light** for processes. It doesn’t carry data—it just signals _"Go!"_ or _"Stop!"_. One process turns the light green (`-> event`); others waiting at the red light (`@(event)`) proceed when it changes. Crucially, events have **memory**: if the light turns green _before_ a car arrives, the car still goes (no need to wait).

### Key Concepts

- **Triggering (`-> event`)**: Non-blocking signal (like flipping a switch).
- **Waiting (`@(event)`)**: Blocking pause until signal arrives (like stopping at a red light).
- **Robust Waiting (`wait(event.triggered)`)**: Checks if signal _ever_ happened—critical for avoiding missed signals.

### Event Operations Explained

| Operation               | Action                                    | When to Use                                          | Example                         |
| ----------------------- | ----------------------------------------- | ---------------------------------------------------- | ------------------------------- |
| `-> event_name;`        | Trigger event (non-blocking)              | When a condition is met (e.g., "config done")        | `-> cfg_done;`                  |
| `@(event_name);`        | Block until event triggers                | When you _must_ wait for signal (e.g., "start test") | `@(start_test);`                |
| `wait(event.triggered)` | Block until event _has ever_ triggered    | \*\*Use when timing is uncertain                     | `wait(reset.done.triggered);`   |
| `event.triggered`       | Check if event ever triggered (non-block) | For conditional logic (e.g., "if config done...")    | `if (clk_stable.triggered) ...` |

### Real-World Example: Power-Up Sequence

```systemverilog
module power_sequence;
  event power_ready;   // Signals power stable
  event clocks_ready;  // Signals clocks locked

  // Power Supply Process
  initial begin : power_supply
    $display("[%0t] PSU: Ramping voltage...", $time);
    #20;
    $display("[%0t] PSU: Voltage stable. Signaling power_ready.", $time);
    -> power_ready; // Trigger: Power is good
    @(clocks_ready); // Wait for clocks to lock
    $display("[%0t] PSU: System fully enabled.", $time);
  end

  // Clock Generator Process
  initial begin : clk_gen
    $display("[%0t] CLK: Starting oscillators...", $time);
    #15;
    $display("[%0t] CLK: Oscillators stable. Signaling clocks_ready.", $time);
    -> clocks_ready; // Trigger: Clocks good
    @(power_ready);  // Wait for power to stabilize
    $display("[%0t] CLK: Enabling clock outputs.", $time);
  end

  // Main Controller: Waits for BOTH
  initial begin : controller
    $display("[%0t] CTRL: Waiting for power AND clocks...", $time);
    wait(power_ready.triggered && clocks_ready.triggered); // Robust check
    $display("[%0t] CTRL: All systems GO! Starting mission.", $time);
    #50 $finish;
  end
endmodule
```

**Why `wait(...triggered)` is essential**:  
Suppose clocks lock _fast_ (at time 10) but the controller starts late (at time 15). Without `.triggered`, `@(power_ready && clocks_ready)` would wait forever—even though both events already happened! The `.triggered` check sees the signals occurred in the past and proceeds immediately.

### Event Best Practices

- **Use `wait(event.triggered)`** for startup sequences or when signal timing is unpredictable (avoids race conditions).
- **Use plain `@(event)`** only when you _know_ the signal hasn’t happened yet (e.g., waiting for a clock edge in a known phase).
- **Combine events with `.triggered`** for complex conditions (e.g., `wait(eventA.triggered || eventB.triggered)`).
- **Never rely on events for data transfer**—use mailboxes if data needs to accompany the signal.
- **Name events descriptively** (e.g., `axi_write_complete` instead of `e1`).

---

## Choosing the Right IPC Mechanism: Quick Guide

| Scenario                                      | Best Tool                | Why                                                                |
| --------------------------------------------- | ------------------------ | ------------------------------------------------------------------ |
| Sending structured data (packets, objects)    | **Mailbox**              | Type-safe, built-in queuing, handles flow control                  |
| Protecting a single shared variable           | **Semaphore** (mutex)    | Simple mutual exclusion; `get(1)`/`put(1)` is lightweight          |
| Managing a pool of identical resources        | **Semaphore** (counting) | e.g., 4 DMA channels: `new(4)`, `get(1)` to claim one channel      |
| Signaling "task done" without data            | **Event**                | Lightweight; ideal for phase synchronization (reset, config, etc.) |
| Need to check if signal _ever_ occurred       | **Event + `.triggered`** | Critical for robust startup sequences                              |
| Non-blocking status check (mailbox/semaphore) | **`.num()` or `try_*`**  | Avoid stalls when resource might be busy/unavailable               |

> 💡 **Rule of thumb**:
>
> - **Data to exchange?** → Mailbox
> - **Resource to protect?** → Semaphore
> - **Just a signal?** → Event

---

## Exercises: Apply What You’ve Learned

1. **Priority Mailbox**  
   Create a mailbox for `integer` messages. Implement a sender that puts high-priority values (negative numbers) and low-priority (positive). Use `peek()` in the receiver to check for high-priority messages first—if found, `get()` it; otherwise, get the next message.

2. **Reader-Writer Lock with Semaphores**  
   Model a shared database:
   - Multiple readers can access simultaneously (use counting semaphore).
   - Writers need exclusive access (use mutex semaphore).  
     Hint: You’ll need two semaphores—one for reader count, one for writer access.

3. **Event-Driven Handshake**  
   Design a two-process "data valid" handshake:
   - Sender: Puts data in mailbox, then triggers `data_sent` event.
   - Receiver: Waits for `data_sent` via `@(data_sent)`, then gets data from mailbox.  
     Show how this prevents the receiver from grabbing stale data.

4. **Semaphore for Power Domains**  
   Simulate a chip with 2 power domains (each can be ON/OFF). Use a semaphore initialized with 2 keys. Processes requesting a domain must `get(1)` a key. Demonstrate how only 2 domains can be ON concurrently.

5. **Event with Timeout**  
   Modify the power-sequence example: If `clocks_ready` doesn’t trigger within 50 time units after `power_ready`, the controller triggers an error event and shuts down. (Hint: Use `#50` delays and check `.triggered`.)

6. **Mailbox Depth Monitor**  
   Create a bounded mailbox (size 3). In a sender process, use `num()` to dynamically adjust send rate: if `num() >= 2`, halve the delay between sends; if `num() == 0`, double the delay. Observe how this prevents overflow/underflow.

---

## Best Practices: IPC Done Right

- **Defensive Initialization**:  
  Always instantiate mailboxes/semaphores/events _before_ any process uses them (in an `initial` block or class constructor).

  ```systemverilog
  mailbox mb = new(); // DO THIS FIRST
  initial begin : proc
    mb.get(msg); // Safe: mb exists
  end
  ```

- **Avoid Nested Blocking Calls**:  
  Never call `get()` inside another `get()`’s critical section—this risks deadlock. Break complex operations into steps.

- **Log IPC Activity**:  
  Add `$display` statements in key IPC calls during debug (remove later for performance):

  ```systemverilog
  if (!mbox.try_put(pkt)) $warning("Mailbox full at %0t", $time);
  ```

- **Test Edge Cases**:  
  Simulate scenarios where:
  - A mailbox is full/empty repeatedly
  - A semaphore is starved (keys never released)
  - An event triggers before/after wait starts

- **Keep It Simple**:  
  If an event suffices for synchronization, don’t overcomplicate with a mailbox. If a mutex semaphore works, avoid counting semaphores unless needed.

---

> Remember: IPC is about **trust and timing**. Mailboxes build trust in data delivery, semaphores build trust in resource access, and events build trust in timing. Master these, and your SystemVerilog simulations will mirror real-world precision—no more guessing if data arrived or if a resource is free.

##### Copyright (c) 2026 squared-studio
