# Fork-Join in SystemVerilog: Concurrent Processes and Synchronization

## Introduction

SystemVerilog procedural statements normally execute in order within a process. The `fork` construct lets one process start multiple child processes so they can make progress concurrently. This is especially useful in testbenches, where independent drivers, monitors, timeouts, and background checks often need to run at the same time.

The matching join keyword determines when the parent process continues: after every child ends, after the first child ends, or immediately. Choosing the right form—and managing any children that remain active—is essential for predictable simulations.

## Learning Goals

By the end of this chapter, you should be able to:

- Explain how a `fork` block creates concurrent child processes.
- Choose among `join`, `join_any`, and `join_none`.
- Synchronize with outstanding processes using `wait fork`.
- Stop processes deliberately and understand the scope of `disable fork`.
- Avoid races caused by shared variables and loop-variable capture.
- Recognize that fork-join is primarily a simulation and verification construct, not synthesizable RTL.

## The `fork` Construct: Starting Concurrent Processes

A `fork` block creates a child process for each statement in its body. Each branch begins as a separate process; statements within a branch still execute sequentially unless that branch contains its own concurrency or timing controls. The parent process reaches the join keyword after starting the branches.

Use `begin` and `end` to group multiple statements into a single branch:

```systemverilog
initial begin
  fork
    begin
      #5  $display("First branch finished at %0t", $time);
    end
    begin
      #12 $display("Second branch finished at %0t", $time);
    end
  join

  $display("All branches finished at %0t", $time);
end
```

Both branches run concurrently. Their completion order depends on their timing and any other synchronization in the simulation. If two branches act in the same time slot, do not rely on their source order to determine which side effect occurs first.

### `fork` Does Not Mean Parallel Hardware

Forked processes are simulator processes, not a request to synthesize parallel hardware. They are useful in `initial` blocks, testbench tasks, and other verification code. Do not use fork-join as a substitute for describing RTL with `always_comb`, `always_ff`, or continuous assignments.

## `join`: Wait for Every Branch

`join` suspends the parent process until all branches spawned by that fork have completed. It is the right choice when the parent must not continue until every concurrent activity is done.

```systemverilog
initial begin
  $display("Starting parallel checks");

  fork
    begin
      #10 $display("Data check complete at %0t", $time);
    end
    begin
      #4;
      #9 $display("Protocol check complete at %0t", $time);
    end
  join

  $display("Both checks completed at %0t", $time);
end
```

The parent resumes only after both branches finish. In this example, the second branch takes 13 time units, so the final message is printed after that branch completes.

Use `join` for work that has a definite end and for which every branch must finish before the caller proceeds. A branch that never completes—for example, an unbounded clock generator—will keep a `join` from returning.

## `join_any`: Continue After the First Branch

`join_any` suspends the parent until at least one branch completes. Other branches are not automatically stopped; they continue running after the parent resumes.

```systemverilog
initial begin
  fork
    begin
      #20 $display("Transaction completed at %0t", $time);
    end
    begin
      #100 $error("Transaction timed out");
    end
  join_any

  $display("At least one branch finished at %0t", $time);
end
```

This pattern is useful for racing an operation against a timeout, but the timeout branch remains active if the transaction branch finishes first. If it should no longer run, explicitly terminate or otherwise coordinate the remaining branch before continuing. Leaving it active can cause a misleading timeout later in the simulation.

If two or more branches complete in the same time slot, the parent resumes after a branch completes; do not depend on a particular branch winning a same-time race.

## `join_none`: Continue Without Waiting

`join_none` lets the parent continue immediately without waiting for any child to complete:

```systemverilog
initial begin
  fork
    begin
      #10 $display("Background task completed at %0t", $time);
    end
  join_none

  $display("Parent continues at %0t", $time);
  #20;
end
```

The child process remains active after the parent moves on. As with `join_any`, `join_none` does not cancel child processes.

There is an important scheduling detail: child processes spawned by `join_none` do not begin executing until the parent process suspends or terminates. For example, if the parent starts several children in a loop and does not block until after the loop, those children begin when the parent reaches that blocking point. This behavior matters when a child reads a loop variable or other state that the parent changes first.

## Waiting for Outstanding Children with `wait fork`

The procedural statement `wait fork;` suspends the calling process until all of its currently active child processes have completed. It is commonly used after `join_none` when background work should be allowed to run concurrently but must be finished before the current procedure exits.

```systemverilog
initial begin
  fork
    begin
      #5 $display("Worker A done at %0t", $time);
    end
    begin
      #8 $display("Worker B done at %0t", $time);
    end
  join_none

  $display("Parent performs other work at %0t", $time);
  #3;
  $display("Parent now waits at %0t", $time);
  wait fork;
  $display("All child processes are done at %0t", $time);
end
```

`wait fork` concerns the calling process's child processes, not every process in the simulation. Use it at a point where the parent is responsible for waiting on those children; otherwise, it may wait for additional outstanding children created by that same parent.

## Ending Processes Deliberately

Some concurrent branches are intended to run only until another branch completes. A named fork block can be disabled when its remaining processes are no longer needed:

```systemverilog
initial begin
  fork : transaction_or_timeout
    begin
      #20 $display("Transaction completed at %0t", $time);
    end
    begin
      #100 $error("Transaction timed out");
    end
  join_any

  disable transaction_or_timeout;
  $display("No transaction or timeout process remains active");
end
```

Disabling the named fork block terminates its still-active branch processes. This is a useful way to clean up the losing side of a bounded race, such as a transaction versus a timeout.

`disable fork;` is another process-control statement, but it terminates active descendants of the calling process. It is broader than disabling a carefully scoped named fork: it can affect other child work owned by that process, including nested descendants. Use it only when that broader cancellation is intended. Keep forked work grouped and scoped so cleanup cannot accidentally stop unrelated activity.

Cancellation is not the same as graceful completion. If a branch must release resources, report a result, or perform cleanup, design an explicit completion protocol rather than assuming that terminating the process will run ordinary code after the termination point.

## A Practical Race: Timeout Versus Completion

A transaction test often needs to wait for either a completion event or a timeout. The following example uses a named fork to ensure the losing branch does not keep running:

```systemverilog
module transaction_watchdog;
  bit transaction_done;

  initial begin
    transaction_done = 0;

    fork : completion_race
      begin
        wait (transaction_done);
        $display("Transaction completed at %0t", $time);
      end
      begin
        #100;
        if (!transaction_done)
          $error("Transaction timed out at %0t", $time);
      end
    join_any

    disable completion_race;
  end

  initial begin
    #30 transaction_done = 1;
  end
endmodule
```

The completion branch and timeout branch run concurrently. Once either branch completes, the parent resumes and disables the named fork, stopping the other branch if it is still active. In a real testbench, define what should happen if completion and timeout become true in the same time slot; use clocking blocks, event regions, or an explicit synchronization protocol when deterministic sampling is required.

## Shared Variables and Race Conditions

Concurrent processes can access the same variables. If multiple branches write a shared variable without synchronization, the resulting value can depend on scheduling order. That is a race condition.

```systemverilog
integer result;

initial begin
  fork
    result = 1;
    result = 2;
  join

  // Do not assume result is 1 or 2 based on source order.
  $display("result = %0d", result);
end
```

Avoid simultaneous, unsynchronized writes to the same variable. Prefer separate per-branch results and combine them after `join`, or use a mailbox, semaphore, event, or other explicit synchronization mechanism appropriate to the testbench.

Clocked RTL has its own assignment and scheduling rules. Do not try to resolve races by arbitrarily adding delays; instead, define which process owns each signal and how processes coordinate.

## Loop Variables with `join_none`

Because `join_none` child processes can start only after their parent suspends or ends, a loop variable may have advanced by the time a child reads it. Capture a separate automatic variable for each iteration:

```systemverilog
initial begin
  for (int i = 0; i < 3; i++) begin
    automatic int index = i;

    fork
      begin
        #1 $display("Worker %0d at %0t", index, $time);
      end
    join_none
  end

  wait fork;
end
```

Each child refers to that iteration's `index`, rather than racing to read the loop variable after it has changed. The final `wait fork` lets all workers finish before the parent exits.

## Best Practices and Common Pitfalls

1. **Choose the join behavior intentionally**:
   - Use `join` when every branch must complete before the parent continues.
   - Use `join_any` when the parent can continue after the first completion, and decide what to do with the remaining branches.
   - Use `join_none` when the parent should proceed immediately, and arrange explicit synchronization or cleanup later.

2. **Do not assume source order between branches**: Each branch is a separate process. If ordering matters, add an event, mailbox, semaphore, or another explicit synchronization mechanism.

3. **Clean up losing branches**: A timeout or background watcher can outlive the operation it was meant to supervise. Use a named fork or another deliberate process-control strategy to stop work that is no longer needed.

4. **Keep cancellation scoped**: `disable fork` affects active descendants of the calling process. Prefer a named fork when only one group of branches should be terminated.

5. **Capture changing loop values**: For forked work started with `join_none`, use a per-iteration automatic variable when a child needs the loop index or other changing state.

6. **Avoid unsynchronized shared writes**: Give concurrent branches separate state or coordinate access explicitly.

7. **Keep fork-join in verification code**: Forked procedural processes are simulation constructs and are generally not synthesizable hardware descriptions.

## Summary

`fork` starts concurrent child processes, while the join keyword controls when the parent may continue. `join` waits for all branches, `join_any` waits for one and leaves the others active, and `join_none` does not wait. Use `wait fork` when a parent needs to wait for its outstanding children, and use named process scopes or other explicit coordination to clean up work safely. Predictable fork-join code depends on deliberate synchronization, scoped process ownership, and avoiding unsynchronized access to shared state.

##### Copyright (c) 2026 squared-studio
