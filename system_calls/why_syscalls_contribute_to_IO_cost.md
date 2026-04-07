# 1. Why I/O is expensive

When people say **I/O is expensive**, they usually mean one or both of these:

## A. The **system call overhead**

Example:

* `read()`
* `write()`
* `open()`

These cross from user mode into kernel mode, so they cost more than a normal function call.

## B. The **actual I/O device work**

This is often the much bigger cost.

Examples:

* reading from disk
* waiting for network packets
* writing to terminal
* talking to a pipe/socket
* waiting for keyboard input

The kernel call overhead might be small compared with:

* disk latency
* network latency
* terminal rendering
* blocking while waiting for data

So the clean answer is:

> I/O is expensive partly because it involves syscalls, but often even more because it involves slow external devices or waiting.

---

# 2. What is expensive about switching from user mode to kernel mode?

Good question. It is not that the CPU “walks somewhere else physically.”
The cost comes from the fact that this is a **privilege boundary crossing**.

A syscall is more expensive than a normal function call because the CPU and OS must do extra work:

## a) Enter kernel mode through a special mechanism

Not just:

* push return address
* jump to function

Instead it must:

* use a special trap/syscall instruction
* switch privilege level
* jump to the kernel entry point

That is more heavyweight than a plain `call`.

---

## b) Save user execution state

The kernel has to preserve enough state so your program can resume correctly later.

That means saving things like:

* instruction location
* flags
* some registers
* stack-related state

So there is bookkeeping.

---

## c) Switch to a kernel stack

The kernel does not usually keep using the user stack for sensitive kernel work.

So it uses the thread’s **kernel stack**, which is another controlled context change.

---

## d) Validate everything

A normal function usually trusts its caller much more.

The kernel cannot.

If you call:

```c
read(fd, buf, 100);
```

the kernel must check:

* is `fd` valid?
* is `buf` a legal user-space pointer?
* is the memory writable?
* is the size okay?

That validation is extra work.

---

## e) Safely copy data across the user/kernel boundary

For many syscalls, the kernel must carefully move data between:

* user memory
* kernel memory

Example:

* `write()` copies from your buffer into kernel-controlled paths
* `read()` copies kernel-obtained data into your buffer

That copying adds cost.

---

## f) Return back to user mode

After finishing, the kernel has to:

* restore saved state
* place the return value where expected
* switch privilege level back
* resume user code

Again, more than a normal return instruction.

---

# 3. So is the mode switch itself the main cost?

Sometimes yes, sometimes no.

## For tiny operations

The syscall overhead can matter a lot.

Example:

* writing 1 byte at a time in a loop with `write()`

That is inefficient because you pay syscall overhead again and again.

That is why buffering helps:

* fewer larger writes
* fewer kernel crossings

## For real disk/network I/O

The actual waiting is often far more expensive than the syscall transition itself.

Example:

* reading from disk may take vastly longer than the user→kernel switch
* waiting on a network response is much slower still

So:

> syscall overhead is significant relative to a normal function call, but device latency is often the dominant reason I/O feels expensive.

---

# 4. A good comparison

## Normal function call

```text
user code -> user function -> return
```

Cheap:

* no privilege change
* no kernel entry
* little bookkeeping

## System call

```text
user code -> syscall entry -> kernel validates/works -> return
```

More expensive:

* mode switch
* state save/restore
* validation
* copying
* maybe blocking

## Actual I/O

```text
user code -> syscall -> kernel -> device/network/disk waits -> return later
```

Potentially **much** more expensive:

* includes everything above
* plus real-world waiting

---

# 5. Why buffering exists

This is exactly why higher-level I/O libraries buffer.

Instead of doing:

* 1000 tiny `write()` syscalls

they try to do:

* 1 bigger `write()` syscall

because the fixed syscall overhead gets amortized.

That is one reason `printf()` with buffering can be much nicer than repeated raw tiny writes.

---

# 6. Super short answer

Yes, **syscall overhead is one reason I/O is considered expensive**.

But usually there are two costs:

* **crossing into the kernel** is more expensive than a normal function call
* **the real I/O work** itself, especially waiting on disk/network/devices, is often much more expensive

And what makes the switch expensive is:

* privilege-level transition
* saving/restoring state
* argument validation
* safe copying between user and kernel memory
* possible blocking and scheduling

A good rule of thumb is:

> Function call cost < syscall cost << slow device / network wait cost
