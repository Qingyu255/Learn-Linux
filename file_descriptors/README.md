Linux file descriptors are just **small integers a process uses to refer to open I/O resources**.

Think of them like this:

* your process has a little table
* each entry in that table points to something open
* the number used to index that entry is the **file descriptor**, or **FD**

So when code does `read(0, ...)` or `write(1, ...)`, the `0` and `1` are file descriptors.

## The default 3

Every process usually starts with these open:

* `0` → **stdin**: standard input
* `1` → **stdout**: standard output
* `2` → **stderr**: standard error

That is why these work:

```bash
command > out.txt
```

This redirects FD `1`.

```bash
command 2> err.txt
```

This redirects FD `2`.

```bash
command < input.txt
```

This redirects FD `0`.

## Why are they called “file” descriptors if they are not always files?

Because in Unix, many things are treated in a file-like way.

A file descriptor can refer to:

* a regular file
* a terminal
* a pipe
* a socket
* a device
* sometimes other kernel-managed I/O objects

So “file descriptor” really means:
**a handle to an open I/O object**.

## How a process gets one

When a process opens something, the kernel returns the lowest unused FD.

Example in C:

```c
int fd = open("notes.txt", O_RDONLY);
```

If `0`, `1`, and `2` are already taken, this might return `3`.

So now:

* `fd == 3`
* FD 3 refers to the open file `notes.txt`

Then the process can do:

```c
read(fd, buf, 100);
close(fd);
```

## Mental model

Imagine this per-process table:

```text
FD table for a process

0  -> terminal input
1  -> terminal output
2  -> terminal error output
3  -> /home/user/notes.txt
4  -> pipe write end
5  -> socket to server
```

The FD is just the number on the left.
The actual open resource is what it points to on the right.

## Important point: file descriptor vs open file

They are related but not the same.

* **file descriptor** = per-process number like `3`
* **open file description** in the kernel = the actual open state

That kernel open state includes things like:

* current file offset
* access mode
* status flags

This matters because two FDs can sometimes refer to the same open file state.

Example: `dup()`.

```c
int fd2 = dup(fd);
```

Now `fd` and `fd2` are different numbers, but they share the same underlying open file state, including file position.

So if one reads 10 bytes, the other sees the offset moved too.

## Shell examples

### Redirect stdout

```bash
echo hello > out.txt
```

The shell opens `out.txt`, gets some FD, and makes FD `1` point to it before starting `echo`.

So `echo` writes to stdout as usual, but stdout now goes to the file.

### Redirect stderr

```bash
ls not_a_file 2> errors.txt
```

The error message goes to FD `2`, which now points to `errors.txt`.

### Pipe

```bash
cat file.txt | grep hello
```

The shell creates a pipe:

* `cat` gets its stdout connected to the pipe’s write end
* `grep` gets its stdin connected to the pipe’s read end

Both ends are represented by FDs.

## Common syscalls involving FDs

* `open()` → open a file, return FD
* `read()` → read from FD
* `write()` → write to FD
* `close()` → close FD
* `dup()` / `dup2()` → duplicate FD
* `pipe()` → create a pipe, return two FDs
* `socket()` → create a socket, return FD

## Why this design is nice

Because programs can do I/O uniformly.

A program often does not need to care whether stdout is:

* your terminal
* a file
* a pipe
* a socket

It just writes to FD `1`.

That is a huge Unix idea:
**same interface, many underlying resource types**.

## Tiny example

```c
write(1, "hi\n", 3);
```

This writes 3 bytes to FD 1.

* if FD 1 is the terminal, you see `hi`
* if FD 1 was redirected to a file, it goes into the file
* if FD 1 was piped, another process receives it

Same call, different destination.

## In `/proc`

On Linux, you can inspect a process’s open FDs:

```bash
ls -l /proc/$$/fd
```

`$$` is the shell’s PID.

You may see something like:

```text
0 -> /dev/pts/0
1 -> /dev/pts/0
2 -> /dev/pts/0
3 -> /home/user/file.txt
```

## One sentence summary

A Linux file descriptor is a **process-local integer handle for an open I/O resource**, used by the kernel APIs like `read()`, `write()`, and `close()`.


Here’s the distinction:

## 1. File descriptor

A **file descriptor** is the low-level Unix/Linux thing.

It is just an **int**.

Example:

```c
int fd = open("data.txt", O_RDONLY);
```

* `open()` is a system call
* `fd` might be `3`
* you use it with `read()`, `write()`, `close()`

Example:

```c
char buf[100];
read(fd, buf, 100);
close(fd);
```

So:

* type: `int`
* layer: **kernel/syscall level**
* used with: `open`, `read`, `write`, `close`

---

## 2. `FILE *`

A `FILE *` is the C standard library’s higher-level stream object.

Example:

```c
FILE *fp = fopen("data.txt", "r");
```

* `fopen()` is from **stdio**
* `fp` is a pointer to a C library structure
* you use it with `fgets()`, `fprintf()`, `fscanf()`, `fclose()`

Example:

```c
char buf[100];
fgets(buf, sizeof(buf), fp);
fclose(fp);
```

So:

* type: `FILE *`
* layer: **C stdio library**
* used with: `fopen`, `fgets`, `fprintf`, `fclose`

---

## 3. “File pointer”

This phrase is annoyingly ambiguous.

People use “file pointer” in **two different ways**:

### Meaning A: they mean `FILE *`

A lot of C programmers say “file pointer” and mean this:

```c
FILE *fp;
```

because it is literally a pointer variable whose type is `FILE *`.

### Meaning B: they mean current file position

Sometimes “file pointer” means the **current offset** in the file, like:

* “the file pointer is at byte 120”

That is not a C pointer variable.
That means the current read/write position.

So this term can be confusing.

---

# The core difference

## File descriptor = kernel-level handle

```c
int fd = open("a.txt", O_RDONLY);
```

This is close to the OS.

You manually use syscalls like:

* `read`
* `write`
* `close`

## `FILE *` = stdio wrapper around a file descriptor

```c
FILE *fp = fopen("a.txt", "r");
```

This is a higher-level C library abstraction.

Internally, stdio usually uses a file descriptor underneath.

So roughly:

```text
your code
  FILE *fp
     ↓
C stdio library buffering / formatting
     ↓
underlying file descriptor
     ↓
kernel
```

---

# Why `FILE *` exists

Because raw file descriptors are pretty low-level and inconvenient.

With `FILE *`, you get:

* buffering
* formatted I/O (`fprintf`, `fscanf`)
* line-oriented functions (`fgets`)
* easier text handling

With file descriptors, you get:

* lower-level control
* direct system-call style I/O
* common use in Unix systems programming

---

# Example comparison

## Using a file descriptor

```c
#include <fcntl.h>
#include <unistd.h>

int main() {
    int fd = open("out.txt", O_WRONLY | O_CREAT | O_TRUNC, 0644);
    write(fd, "hello\n", 6);
    close(fd);
    return 0;
}
```

## Using `FILE *`

```c
#include <stdio.h>

int main() {
    FILE *fp = fopen("out.txt", "w");
    fprintf(fp, "hello\n");
    fclose(fp);
    return 0;
}
```

Both write to a file, but the second is higher-level.

---

# Important: buffering

This is one of the biggest differences.

`FILE *` streams are usually **buffered**.

So when you do:

```c
fprintf(fp, "hello");
```

it may not immediately go to the kernel right away.
It may sit in a user-space buffer first.

Then later it gets flushed:

* when buffer fills
* when you call `fflush(fp)`
* when you call `fclose(fp)`
* sometimes when a newline is written to a terminal stream

By contrast, with:

```c
write(fd, "hello", 5);
```

you are making a syscall directly.

That does **not** mean the disk is updated instantly either, but it does mean you bypass stdio’s user-space buffering layer.

---

# Can you convert between them?

Yes.

## From `FILE *` to FD

```c
int fd = fileno(fp);
```

## From FD to `FILE *`

```c
FILE *fp = fdopen(fd, "r");
```

So they are related.

---

# Very important rule

Do **not** casually mix stdio functions and raw syscalls on the same underlying open file unless you really know what you are doing.

For example, this can get messy:

```c
FILE *fp = fopen("a.txt", "r+");
int fd = fileno(fp);

fgets(buf, sizeof(buf), fp);
read(fd, buf2, 10);
```

Why messy?

Because stdio buffering means the `FILE *` layer may already have read ahead, so the FD’s actual position and the stdio view can get out of sync in ways that surprise you.

For learning purposes, treat them as:

* use **either** `FILE *` APIs
* or use **FD** APIs

Do not mix them unnecessarily.

---

# What about stdin, stdout, stderr?

There are two views of these too.

## File descriptor view

* `0` = stdin
* `1` = stdout
* `2` = stderr

## stdio view

* `stdin`
* `stdout`
* `stderr`

These are `FILE *` objects provided by stdio.

So:

```c
write(1, "hi\n", 3);
```

and

```c
fprintf(stdout, "hi\n");
```

both target standard output, but through different layers.

---

# Super clean mental model

## File descriptor

“Kernel, here is resource number 3 for this process.”

## `FILE *`

“C library, please manage this stream for me, with buffering and convenient functions.”

---

# Tiny analogy

Think of:

* **file descriptor** = raw apartment unit number
* **`FILE *`** = concierge service managing access to that apartment for you

You can interact more directly with the unit number, but the concierge adds convenience and some internal handling.

---

# One-liner summary

* **file descriptor**: low-level integer handle used with Unix syscalls
* **`FILE *`**: high-level C stdio stream object, usually built on top of a file descriptor
* **file pointer**: ambiguous term; usually means `FILE *`, but sometimes means current file position

Here’s the most exam-safe way to say it:

> A file descriptor is an integer handle used by the kernel interface, while `FILE *` is a C standard I/O stream abstraction that usually wraps a file descriptor and adds buffering and higher-level operations.
