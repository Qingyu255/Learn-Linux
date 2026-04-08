`fork()` and `exec()` are the classic Unix way to start a new program.

The big idea is:

* `fork()` = **make a new process**
* `exec()` = **replace the current process with a new program**

They are often used together.

---

## 1. `fork()`

`fork()` creates a **child process** by copying the calling process.

After `fork()`, there are now **two processes** running:

* the **parent**
* the **child**

They both continue execution from the line right after `fork()`.

### Important behavior

They are almost identical right after the fork:

* same code
* same virtual memory contents
* same open file descriptors
* same environment
* same current working directory

But they are still **separate processes** with different PIDs.

### Return value of `fork()`

This is the key to telling parent and child apart:

* returns **0** in the **child**
* returns **child PID** in the **parent**
* returns **-1** on failure

### Example

```c
pid_t pid = fork();

if (pid < 0) {
    // fork failed
} else if (pid == 0) {
    // child process
} else {
    // parent process
}
```

So both parent and child run the same code, but the return value tells each one who it is.

---

## 2. What actually gets copied?

Conceptually, the child gets a copy of the parent’s process state.

But modern systems usually do this efficiently using **copy-on-write**:

* parent and child initially share the same physical memory pages
* if one writes to a page, the kernel makes a separate copy then

So `fork()` does **not** usually copy all memory eagerly byte-for-byte immediately.

---

## 3. `exec()`

`exec()` does **not create a new process**.

This is the part many people mix up.

Instead, `exec()` **replaces the current process image** with a new program.

So after a successful `exec()`:

* same PID
* same process identity
* but now running different code and a different program image

The old program’s code, stack, heap, etc. are thrown away and replaced.

### Common forms

There is no single plain `exec()` syscall in C user code usually. You normally see the **exec family**:

* `execl()`
* `execv()`
* `execle()`
* `execve()`
* `execlp()`
* `execvp()`

The underlying syscall is typically **`execve()`**.

---

## 4. Why use `fork()` and then `exec()`?

Because this lets a shell do:

1. `fork()` a child
2. in the child, `exec()` the command
3. in the parent, maybe `wait()` for the child

That is exactly how shells launch commands.

### Example flow

Suppose you type:

```bash
ls -l
```

A shell might do this:

* shell calls `fork()`
* child process calls `execvp("ls", ...)`
* child becomes `ls`
* parent shell waits for child to finish

So:

* `fork()` gives a new process
* `exec()` turns that new child into the target program

---

## 5. Tiny example

```c
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>

int main() {
    pid_t pid = fork();

    if (pid < 0) {
        perror("fork");
        return 1;
    }

    if (pid == 0) {
        // Child
        printf("Child: my PID is %d\n", getpid());
        execl("/bin/ls", "ls", "-l", NULL);

        // Only reached if exec fails
        perror("execl");
        return 1;
    } else {
        // Parent
        printf("Parent: child PID is %d\n", pid);
    }

    return 0;
}
```

### What happens here

* parent calls `fork()`
* child enters `pid == 0` branch
* child prints its PID
* child calls `execl("/bin/ls", "ls", "-l", NULL)`
* child process is now replaced by `ls`
* if `exec` succeeds, it never comes back to the old code

---

## 6. Very important: `exec()` only returns on failure

This is a huge exam/interview point.

When `exec()` succeeds, the current program is gone.

So code after `exec()` runs **only if `exec()` fails**.

Example:

```c
execvp("ls", argv);
perror("execvp");   // runs only if exec failed
```

---

## 7. Mental model

Think of it like this:

### `fork()`

“Clone me.”

### `exec()`

“Turn me into this other program.”

So a shell does:

* parent shell: “clone me”
* child shell copy: “okay, now turn into `ls`”

---

## 8. Difference in one sentence

`fork()` creates a **new process**, while `exec()` replaces the **current process’s program**.

---

## 9. Common confusion

### Does `exec()` create a child?

No.

### Does `fork()` run a new program?

No, not by itself. It just duplicates the current one.

### Why not just `exec()` directly from the shell?

Because then the shell itself would turn into `ls` and disappear.

That is why the shell `fork()`s first.

---

## 10. Typical shell pattern with `wait()`

```c
pid_t pid = fork();

if (pid == 0) {
    execvp(cmd[0], cmd);
    perror("execvp");
    _exit(1);
} else {
    wait(NULL);
}
```

Parent waits, child becomes the new command.

---

## 11. Summary table

| Aspect | `fork()` | `exec*()` (`execve`, `execvp`, etc.) | `wait()` / `waitpid()` |
| --- | --- | --- | --- |
| Primary purpose | Create a child process | Replace current process image with a new program | Synchronize with child and reap exit status |
| New process created? | Yes | No | No |
| PID behavior | Child gets new PID; parent keeps PID | PID stays the same process identity | No PID creation; returns a child PID that changed state |
| What happens to memory image | Child starts as copy of parent view (copy-on-write) | Old code/stack/heap replaced by new program image | Memory image unchanged |
| Stack behavior | Child has its own virtual stack; pages copied on first write | Old stack discarded; new stack built for new program | Stack unchanged |
| Control flow return | Returns in both parent and child | On success: does not return; on failure: returns `-1` | Returns when child state changes (or immediately with `WNOHANG`) |
| Typical branching value | `<0` error, `0` child, `>0` parent (child PID) | `-1` on failure; success never reaches next line | Child PID on success, `-1` on error, `0` possible with `WNOHANG` |
| Can block? | Usually short kernel work; not a long wait call | Usually not a "wait" call; cost is program loading/linking | Yes, often blocks until child exits unless non-blocking options used |
| Typical shell usage | Shell creates child | Child becomes command (`ls`, `wc`, etc.) | Parent waits/reaps foreground child |
| Common pairings | Often followed by child `exec*()` | Often used after `fork()` in child | Often used after `fork()` in parent |
| Common mistake | Expect deterministic print order without sync | Expect old program to resume after success | Assume long block means heavy syscall work (often child runtime) |

---

## 12. Super short intuition

Before `fork()`:

* 1 process

After `fork()`:

* 2 processes running same code

After child calls `exec()`:

* still 2 processes, but child is now a different program

---

## 13. Visual

```text
Shell process
    |
    | fork()
    v
Shell parent -------- Shell child
                          |
                          | exec("ls")
                          v
                         ls
```

So the child started as a copy of the shell, then got replaced by `ls`.

---

## 14. Terminology note

You wrote `execue()`, but the syscall family is usually called `exec()` or more precisely `execve()`.

If you want, I can also give you:

* a **fork vs exec vs wait** diagram,
* a **full shell-launch example in C**,
* or explain **what exactly gets inherited across fork/exec**.

## Bigger picture: The lifecycle

When a shell launches a command, the usual flow is:

```text
shell
  |
  | fork()
  v
parent shell ---------------- child shell-copy
     |                              |
     | wait()                       | exec(...)
     |                              v
     |                         new program
     v
shell prompt returns
```

So:

* `fork()` creates a **child**
* `exec()` makes the **child become the target program**
* `wait()` lets the parent wait for the child to finish

---

# 1. `fork()` more deeply

## What `fork()` does

`fork()` asks the kernel to create a new process.

After it returns, both processes continue from the **next line of code**.

That’s the weird part at first: you call `fork()` once, but now two processes are running.

## Return values

```c
pid_t pid = fork();
```

* `pid < 0` → error
* `pid == 0` → you are in the **child**
* `pid > 0` → you are in the **parent**, and `pid` is the child’s PID

---

# 2. Why the shell needs `fork()`

Suppose the shell just did `exec("ls")` directly.

Then the shell itself would be replaced by `ls`.

That means after `ls` finishes, your shell is gone.

So the shell must:

1. `fork()` a child
2. let the child `exec()` the command
3. keep the parent shell alive

That is why `fork()` and `exec()` are paired.

---

# 3. `exec()` more deeply

`exec()` does **not** make a new process.

It says:

> “Kernel, throw away my current program and load this other one into me.”

So after a successful `exec()`:

* same PID
* same process slot
* same open file descriptors unless marked close-on-exec
* but brand new code / stack / heap / data for the new program

So it is still the same process identity, just now running a different program.

---

# 4. Why people say “fork creates, exec replaces”

Because that is exactly the clean mental model:

* `fork()` = **copy the process**
* `exec()` = **overwrite that process with a new program**

---

# 5. Tiny example to see both branches

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
    pid_t pid = fork();

    if (pid < 0) {
        perror("fork");
        return 1;
    }

    if (pid == 0) {
        printf("I am the child. PID=%d\n", getpid());
    } else {
        printf("I am the parent. PID=%d, child PID=%d\n", getpid(), pid);
    }

    return 0;
}
```

One call to `fork()`, but both parent and child print.

---

# 6. Example with `exec()`

```c
#include <stdio.h>
#include <unistd.h>

int main(void) {
    printf("Before exec, PID=%d\n", getpid());

    execl("/bin/echo", "echo", "hello from exec", NULL);

    // Runs only if exec fails
    perror("execl");
    return 1;
}
```

If `exec()` succeeds, this process becomes `/bin/echo`.

So the original program does not continue.

That is why code after `exec()` is error-handling code.

---

# 7. Full shell-style example

This is the classic pattern:

```c
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

int main(void) {
    pid_t pid = fork();

    if (pid < 0) {
        perror("fork");
        return 1;
    }

    if (pid == 0) {
        // Child process
        execlp("ls", "ls", "-l", NULL);

        // Only if exec fails
        perror("execlp");
        _exit(1);
    } else {
        // Parent process
        int status;
        waitpid(pid, &status, 0);
        printf("Child finished\n");
    }

    return 0;
}
```

## Step by step

### Parent starts

Only one process exists.

### `fork()` happens

Now there are two:

* parent
* child

### Child branch

Child calls:

```c
execlp("ls", "ls", "-l", NULL);
```

So child is replaced by `ls -l`.

### Parent branch

Parent calls:

```c
waitpid(pid, &status, 0);
```

and waits for child to finish.

That is basically how a shell works.

---

# 8. Why `_exit()` in the child after exec failure?

You’ll often see:

```c
_exit(1);
```

instead of `return 1;`

That is because after `fork()`, the child should often exit cleanly without running higher-level stdio cleanup logic inherited from the parent. `_exit()` is the low-level process exit.

For beginner understanding, just remember:

* after failed `exec()`, child should terminate
* `_exit()` is the safer low-level way

---

# 9. What gets inherited across `fork()`?

After `fork()`, child gets a near-copy of parent.

Common inherited things:

* current working directory
* environment variables
* open file descriptors
* signal dispositions
* memory contents
* user/group IDs

But parent and child are separate processes, so after the fork, changing one process’s normal variables does not change the other.

Example:

```c
int x = 5;
pid_t pid = fork();

if (pid == 0) {
    x = 99;
    printf("child x = %d\n", x);
} else {
    printf("parent x = %d\n", x);
}
```

The child changing `x` does not change the parent’s `x`.

Why? Because each process now has its own virtual address space.

---

# 10. Open file descriptors after `fork()`

This part is super important.

If the parent had an open file before `fork()`, the child inherits it.

So both processes can refer to the same open file description in the kernel.

That is what makes redirection and pipes work.

Example idea:

* shell opens/sets up pipe
* shell `fork()`s
* child inherits the pipe file descriptors
* child `exec()`s a program
* program now reads/writes through those inherited descriptors

That’s the magic behind:

```bash
ls | grep txt
```

---

# 11. What survives across `exec()`?

`exec()` wipes out most of the process memory image:

* old code gone
* old stack gone
* old heap gone
* old globals gone

But some process attributes remain, such as:

* PID
* current working directory
* environment, if passed through
* open file descriptors not marked close-on-exec

This is why a shell can redirect stdout before `exec()`, and the new program still writes to the redirected destination.

---

# 12. The exec family

You usually use library wrappers, not raw “exec”:

* `execl`
* `execv`
* `execlp`
* `execvp`
* `execve`

## Easy intuition

* `l` = pass args as a **list**
* `v` = pass args as an **array/vector**
* `p` = search `PATH`
* `e` = supply environment explicitly

### Example

```c
execl("/bin/ls", "ls", "-l", NULL);
```

Direct path.

```c
execlp("ls", "ls", "-l", NULL);
```

Searches `PATH`, like the shell.

---

# 13. Common beginner confusions

## “Does `fork()` copy memory?”

Conceptually yes.

Practically, usually via **copy-on-write**:
the kernel avoids copying everything immediately.

## “Does `exec()` spawn a new process?”

No. It replaces the current one.

## “After `fork()`, are the variables shared?”

No, not ordinary variables.

## “Why do parent and child both continue after the same line?”

Because the child is created as a copy of the running process state.

---

# 14. Super simple analogy

Imagine a Word document.

* `fork()` = make a duplicate of the document
* `exec()` = erase one duplicate and load a completely different file into it

So after `fork()` you have two docs.
After `exec()` one of them is now an entirely different document.

---

# 15. One compact exam-ready summary

`fork()` creates a child process by duplicating the calling process. Both parent and child continue executing from the next instruction, distinguished by the return value of `fork()`. `exec()` does not create a new process; instead, it replaces the current process image with a new program. Shells use `fork()` followed by `exec()` so the child becomes the requested command while the parent shell remains alive and can wait for the child.

---

# 16. The minimal mental model you should remember

```text
fork()  -> now there are two processes
exec()  -> current process becomes another program
wait()  -> parent waits for child
```

If you want, next I can explain `fork()` and `exec()` using:

1. a memory diagram,
2. a real shell command like `grep foo file.txt`,
3. or how pipes/redirection depend on them.

---

# 17. `wait()` / `waitpid()` in a bit more depth

`wait()` and `waitpid()` do not create or replace a process. Their job is synchronization and cleanup.

## What problem they solve

When a child exits, the kernel keeps a small exit record (PID + status) until the parent collects it.
If parent never collects it, child stays as a zombie entry.

`wait()` / `waitpid()` let parent collect that record ("reap" the child).

## `wait()` vs `waitpid()`

- `wait(&status)`
    - waits for any child
    - blocks until one child changes state
- `waitpid(pid, &status, options)`
    - can wait for a specific child PID
    - supports non-blocking mode with `WNOHANG`

Typical foreground shell behavior:

```c
pid_t child = fork();
if (child == 0) {
        execvp(cmd[0], cmd);
        perror("execvp");
        _exit(1);
}
int status;
waitpid(child, &status, 0);
```

---

# 18. Cost comparison: `fork()` vs `exec()` vs `wait()`

Costs depend on OS, hardware, cache state, and process size, but this is the practical ordering intuition.

| Call | Main work done by kernel | Relative cost intuition |
| --- | --- | --- |
| `wait()` / `waitpid()` | sleep/wake + collect child status record | usually lowest |
| `fork()` | create child task, PID, page tables, kernel bookkeeping (memory is mostly copy-on-write) | medium |
| `exec*()` | discard old image and load new executable + dynamic libs + setup new stack/env | often highest |

## Which is usually more costly: `fork()` or `exec*()`?

In most real command launches, **`exec*()` is usually more costly than `fork()`**.

Why:

- `fork()` mostly sets up a new process structure and page tables; memory pages are usually not copied immediately because of copy-on-write.
- `exec*()` must replace the process image, map/load the new executable, load dynamic libraries, build a new stack, and prepare runtime state.

### `fork()` copy-on-write vs `exec*()` replacement (important contrast)

- After `fork()`, the child has its **own virtual stack/heap/address space**, but most physical pages are initially shared read-only via copy-on-write.
- On first write (for example, changing a local variable on the stack), kernel copies only that page for the writing process.
- So `fork()` gives two independent processes quickly, without eagerly copying every memory page.

- `exec*()` is different: it throws away old code/stack/heap and builds a new process image for the new program.
- That means old copy-on-write sharing from `fork()` is no longer relevant after successful `exec*()`.
- Process identity (PID) stays the same across `exec*()`, but memory image and stack are replaced.

### Does `exec*()` restore the old process state afterward?

No. On success, `exec*()` does **not** come back and does **not** restore old code/stack/heap.

- Successful `exec*()` permanently replaces the old process image.
- The PID is the same process identity, but it is now running a different program image.
- If `exec*()` returns to your code, that means it failed.

### When to choose `fork()`, `exec*()`, or both

- Choose `fork()` when you want parent and child to continue independently from current program logic.
- Choose `exec*()` (without `fork`) when you want the current process to become another program and never return to old logic.
- Choose `fork()` + `exec*()` when parent must stay alive (shell/server), but child should run a different program.
- Add `wait()` / `waitpid()` when parent should synchronize with or reap child.

So `fork()` is often a lighter setup step, while `exec*()` often does the heavier program-loading work.

### Caveat

This is a common pattern, not a strict rule. Relative cost can change with workload:

- Very large parent process metadata can make `fork()` more expensive.
- Very small/static binaries (or warm filesystem cache) can make `exec*()` cheaper than expected.

## Important nuance

- `fork()` used to be very expensive when full memory copy happened eagerly.
- Modern systems use copy-on-write, so `fork()` is much cheaper than old mental models.
- `exec*()` can still dominate when program loading/linking is heavy.

## How to read this table (most common confusion)

There are two different "cost" ideas:

1. **Kernel-work cost** (how much OS setup/teardown work the syscall itself does)
2. **Wall-clock wait time** (how long your program appears blocked)

The table above is mainly about **kernel-work cost**.

- `waitpid()` is usually low kernel work, but it can block for a long wall-clock time if the child runs for a long time.
- That long wait is mostly child runtime, not expensive `waitpid()` internal work.

## Concrete timeline example

Suppose:

- `fork()` setup takes about `0.2 ms`
- child `exec*()` loading takes about `3 ms`
- child program itself runs for `200 ms`
- parent calls `waitpid(child, ...)`

Then parent may sit in `waitpid()` for about `200 ms`, but that does **not** mean `waitpid()` is the heaviest syscall.
It means the child took time to finish.

## Real shell command launch cost

For a normal foreground command, you usually pay:

1. one `fork()`
2. one `exec*()` in child
3. one `waitpid()` in parent

So total launch latency is mostly from process creation + program loading; `waitpid()` is usually not the bottleneck.
