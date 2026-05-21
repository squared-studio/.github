# Chapter 6: Extending the Environment as a New Verification Engineer

## What You Should Learn in This Chapter

This final chapter focuses on practical growth.

By the end, you should understand:

- how to add a new test without damaging the structure,
- when to reuse existing sequences,
- when the scoreboard must change,
- and what beginner mistakes to avoid.

## 6.1 A Safe Way to Think About Extensions

When a trainee engineer first adds a new test, the most common mistake is to change too many parts of the environment at once.

A safer approach is:

1. decide what behavior you want to verify,
2. identify whether the environment already has the right stimulus path,
3. add the smallest new piece needed,
4. keep common setup in the base test,
5. extend the scoreboard only if the new behavior introduces a new kind of check.

This keeps the environment stable while you learn.

## 6.2 Reuse Before You Create

Before writing a new sequence or a new checker, ask two simple questions.

### Question 1: Do I already have the right traffic type?

If your new test still uses:

- APB register reads and writes,
- UART receive traffic,
- UART transmit observations,

then you may be able to reuse existing sequences or extend them slightly rather than starting from zero.

### Question 2: Is the scoreboard already comparing the behavior I care about?

If your new test is still fundamentally about:

- APB writes matching UART transmit bytes,
- UART receive bytes matching APB read data,

then the current scoreboard may already be sufficient.

That is the first thing to check before adding more infrastructure.

## 6.3 A Minimal Derived Test Template

A good beginner template for a new test looks like this:

```systemverilog
class my_test extends base_test;
    `uvm_component_utils(my_test)

    function new(string name = "my_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task main_phase(uvm_phase phase);
        phase.raise_objection(this);

        // Start APB and or UART sequences here.

        apb_intf.wait_till_idle();
        uart_intf.wait_till_idle();
        phase.drop_objection(this);
    endtask
endclass
```

The key lesson here is what is not present:

- no duplicated reset code,
- no duplicated clock startup,
- no duplicated base configuration.

That setup already belongs to `base_test`.

## 6.4 When the Scoreboard Needs to Grow

A trainee engineer should be careful not to assume the scoreboard magically understands every new feature.

If your new test targets behavior such as:

- interrupts,
- FIFO almost-full thresholds,
- parity error signaling,
- invalid access response behavior,
- flush corner cases,

then the scoreboard may need new compare logic or new state tracking.

A practical rule is this:

If the test is checking something the scoreboard never observes or compares today, the scoreboard probably needs an update.

## 6.5 When Coverage Needs to Grow

The same idea applies to coverage.

If you introduce a new important feature or mode, ask:

- do I have coverage that reflects this feature,
- or am I only relying on pass fail checking?

For example, if you add parity-enabled testing, you may also want coverage points that record whether parity-enabled traffic has really been exercised.

Coverage is how you make sure the new feature is not only supported in code, but also intentionally explored by tests.

## 6.6 Common Beginner Mistakes

This section is especially useful for trainees because these mistakes are very common.

### Mistake 1: Putting scenario logic in the driver

The driver should execute transactions, not invent them.

Scenario intent belongs in tests and sequences.

### Mistake 2: Putting checking inside the monitor

The monitor should observe and report.

The scoreboard should judge correctness.

### Mistake 3: Repeating setup in every test

Reset, clock startup, and common configuration belong in the base test.

### Mistake 4: Ending a phase too early

If you do not raise and drop objections correctly, or if you do not wait for APB and UART activity to drain, the environment may miss valid late-arriving observations.

### Mistake 5: Assuming no errors means enough testing

A test can pass while still covering only a small part of the intended behavior space.

That is why coverage matters.

## 6.7 A Practical Checklist for Writing a New Test

When you add a test, use this checklist.

1. What exact DUT behavior am I trying to prove?
2. Is this behavior visible on APB, UART, or both?
3. Which existing sequence gets me closest to the needed stimulus?
4. Do I need a new sequence or only a new sequence length or constraint?
5. Does the existing scoreboard already compare this behavior?
6. Do I need new coverage for this feature?
7. Have I waited long enough for all activity to complete before ending the phase?

If you can answer these questions clearly, your test will usually be much easier to debug.

## 6.8 Final Takeaway for a New Verification Engineer

At first, UVM can feel like a large framework with many moving parts. But this APB-UART environment shows that the core idea is actually straightforward.

- Tests express intent.
- Sequences generate transactions.
- Drivers create signal activity.
- Monitors observe reality.
- Scoreboards compare intent and observation.
- Coverage tells you what parts of the behavior space were exercised.

If you can hold that model in your head, you already understand the foundation of UVM.

Everything more advanced is usually an extension of those same ideas.

## Previous

Previous: [Chapter 5: Scoreboard, Coverage, and What the Tests Prove](05-scoreboard-coverage-and-what-the-tests-prove.md)

## Back to Index

Return to [Tutorial Index](../readme.md)
##### Copyright (c) 2026 squared-studio

