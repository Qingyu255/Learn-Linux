Signals are the OS’s way of **asynchronously interrupting a process** to tell it that **something happened**.

Think of them as a very small built-in notification mechanism from the kernel to a process.

Examples:

* “You pressed **Ctrl+C**” → send `SIGINT`
* “Your child process exited” → send `SIGCHLD`
* “You divided by zero or touched invalid memory” → send `SIGFPE` or `SIGSEGV`
* “Please terminate” → send `SIGTERM`

## Big picture

A process normally runs instruction by instruction.

But sometimes an external event happens:

* keyboard interrupt
* timer expired
* child changed state
* another process sent a signal
* invalid memory access

The kernel can then deliver a **signal** to that process.

So signals are a form of:

* **software interrupt**
* **event notification**
* **lightweight inter-process communication**, in a limited sense

## Why they matter

Signals let the OS or another process say:

* stop
* continue
* terminate
* wake up, something changed
* handle this exceptional event

They are very old-school Unix, but still important.

---

## Common examples

### `SIGINT`

Interrupt from terminal, usually when you press **Ctrl+C**.

Default action: terminate process.

### `SIGTERM`

Polite request to terminate.

Default action: terminate process.

This is the one programs are generally expected to handle for graceful shutdown.

### `SIGKILL`

Force kill.

Default action: terminate immediately.

Cannot be caught, blocked, or ignored.

### `SIGSTOP`

Stop/suspend process.

Cannot be caught, blocked, or ignored.

### `SIGCONT`

Resume a stopped process.

### `SIGSEGV`

Segmentation fault.

Usually means invalid memory access.

### `SIGALRM`

Timer signal.

### `SIGCHLD`

Sent to parent when child changes state, often exits.

### `SIGPIPE`

Writing to a pipe with no reader.

---

## Where signals come from

Signals can come from:

### 1. The kernel

Example:

* invalid memory access → `SIGSEGV`
* child exits → `SIGCHLD`

### 2. The terminal

Example:

* Ctrl+C → `SIGINT`
* Ctrl+Z → `SIGTSTP`

### 3. Another process

Using calls like:

* `kill()`
* `raise()`

Despite the name, `kill()` does **not** always kill. It just sends a signal.

Example:

```c
kill(pid, SIGTERM);
```

That means: send `SIGTERM` to process `pid`.

---

## What happens when a process receives a signal

For each signal, one of three things can happen:

### 1. Default action

The kernel does the signal’s built-in default.

Examples:

* terminate
* ignore
* stop
* continue

### 2. Ignore it

The process can choose to ignore some signals.

Example:

* it may ignore `SIGINT`

But not all signals can be ignored.

### 3. Catch it with a signal handler

The process can install a function that runs when the signal arrives.

Example idea:

```c
void handler(int sig) {
    printf("Got signal %d\n", sig);
}
```

Then register it with `signal()` or better, `sigaction()`.

So instead of dying immediately, the process can respond.

---

## Mental model

Imagine your process is doing normal work:

```text
run run run run run ...
```

Then suddenly:

```text
"hey, SIGINT arrived"
```

The kernel temporarily diverts control to the signal handler, if one exists.

Then usually the process returns to where it left off.

So it’s kind of like:

* pause current flow
* run handler
* resume

That is why signals feel “out of nowhere”.

---

## Why signals are tricky

Signals are **asynchronous**.

That means they can arrive at almost any time.

So if your code is in the middle of modifying data, and a signal handler runs, things can get messy.

That’s why signal handlers must be very careful.

In practice, inside a handler you should do very little.

Usually:

* set a flag
* write to a pipe
* return

Not:

* complicated memory allocation
* most `printf` usage
* random library calls

Because many functions are **not async-signal-safe**.

---

## Signal disposition

A process has a **disposition** for each signal, meaning what it has decided should happen when that signal arrives.

Possible dispositions:

* default
* ignore
* catch with handler

---

## Can signals queue up?

Sometimes, but classic signals are weird here.

For many standard signals:

* if the same signal arrives multiple times while blocked/pending,
* they may get merged into one pending signal

So signals are not like a normal message queue carrying rich data.

They are more like:

* “this event happened”
  than
* “here are 12 separate event objects”

There are also **real-time signals**, which behave more like queued notifications.

---

## Blocking signals

A process can temporarily **block** signals.

That means:

* signal is not delivered immediately
* it becomes **pending**
* when unblocked, it may then be delivered

This is useful when protecting critical sections.

---

## Example: Ctrl+C

Suppose your program is running in terminal.

You press Ctrl+C.

Flow:

1. Terminal driver notices Ctrl+C
2. Kernel sends `SIGINT` to foreground process group
3. Process receives `SIGINT`
4. If no handler and not ignored, default action happens
5. Process terminates

That is why Ctrl+C often kills programs.

---

## Example: segmentation fault

Suppose code dereferences a bad pointer:

```c
int *p = NULL;
*p = 5;
```

Kernel detects invalid memory access.

It sends `SIGSEGV`.

If unhandled, default action is usually:

* terminate process
* maybe dump core

So the signal is the OS telling the process:
“you touched memory you’re not allowed to.”

---

## Important distinction: signal vs system call

A **system call** is when the process asks the kernel for something.

A **signal** is when the kernel interrupts the process to notify it of something.

So:

* `read()` → process to kernel
* `SIGINT` → kernel to process

---

## Important distinction: signal vs hardware interrupt

A hardware interrupt is lower-level, involving devices/CPU/kernel.

A signal is a **process-level abstraction** exposed by the OS.

So you can loosely think of signals as OS-delivered software notifications, not raw hardware interrupts.

---

## Tiny C example

```c
#include <stdio.h>
#include <signal.h>
#include <unistd.h>

void handle_sigint(int sig) {
    write(STDOUT_FILENO, "Caught SIGINT\n", 14);
}

int main(void) {
    signal(SIGINT, handle_sigint);

    while (1) {
        write(STDOUT_FILENO, "Running...\n", 11);
        sleep(1);
    }
}
```

If you press Ctrl+C:

* instead of exiting immediately,
* the handler runs

Note: in real code, `sigaction()` is preferred over `signal()`.

---

## Super compressed summary

Signals are:

* OS notifications sent to processes
* often asynchronous
* triggered by kernel events, terminal actions, or other processes
* handled by default action, ignore, or custom handler

Common ones:

* `SIGINT` → Ctrl+C
* `SIGTERM` → polite terminate
* `SIGKILL` → force kill
* `SIGSEGV` → invalid memory access
* `SIGCHLD` → child changed state

## Easy analogy

Your process is a person working at a desk.

A signal is like someone barging in and saying:

* “stop now”
* “your child is done”
* “you broke a rule”
* “pause”
* “continue”

The person can:

* obey immediately
* ignore it sometimes
* react with a custom routine

But some orders, like `SIGKILL`, are non-negotiable.

If you want, I can next explain:

1. **signal handlers**
2. **signal vs interrupt vs exception**
3. **kill, raise, signal, sigaction**
4. a **full timeline of what happens on Ctrl+C**
