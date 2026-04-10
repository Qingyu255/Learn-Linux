## The big idea

A running program does **not** access RAM directly.

Instead, Linux gives each process a **virtual address space**. The CPU and OS then translate those virtual addresses into **physical RAM addresses** using **page tables**, with a **TLB** to speed things up.

So the mental pipeline is:

```text
program
-> running process
-> process virtual address space
-> page tables
-> physical RAM
```

---

# 1. Program vs process

A **program** is just the executable file on disk.

A **process** is a running instance of that program. Once the program starts running, Linux gives it:

* CPU state like registers and program counter
* open file descriptors
* a virtual address space
* page tables
* other kernel bookkeeping

So the process is the live thing. The file on disk is just the template.

---

# 2. Virtual address space

Each process gets its own **virtual address space**, which looks like a big private memory world.

Typical conceptual layout:

```text
high addresses
┌──────────────────────────────┐
│ stack                        │
├──────────────────────────────┤
│ mmap region / shared libs    │
├──────────────────────────────┤
│ heap                         │
├──────────────────────────────┤
│ data / bss                   │
├──────────────────────────────┤
│ code / text                  │
└──────────────────────────────┘
low addresses
```

Important point:

This is **not** raw RAM.
It is the memory layout the process *sees*.

The process uses virtual addresses like `0x12345678`, but those are not directly physical hardware addresses.

---

# 3. Pages and frames

Memory is managed in chunks called **pages**.

A process’s virtual memory is divided into **virtual pages**. Physical RAM is divided into equally sized chunks called **physical frames**.

Common page size: **4 KB**

A virtual address is conceptually split into:

* **virtual page number**
* **offset within the page**

Then Linux/CPU translate:

* **virtual page number -> physical frame number**
* keep the **offset the same**

So if page size is 4 KB, the lower 12 bits are usually the offset.

---

# 4. Page tables

A **page table** is the data structure that records how a process’s virtual pages map to physical RAM frames.

A page table entry usually contains:

* physical frame number
* whether the page is present
* permissions like read/write/execute
* whether user mode can access it
* accessed/dirty bits and similar metadata

So it is not just “where is this page,” but also “what are the rules for using it.”

---

# 5. Multi-level page tables

We talked about page tables not being one giant flat structure.

Modern Linux systems typically use **multi-level page tables**.

That means the CPU resolves a virtual address by moving through multiple levels of lookup structures, eventually finding the final entry that gives the physical frame.

This is called a **page table walk**.

Important clarification:

**Walk** does **not** mean “searching for an empty address.”

It means:

* take bits from the virtual address
* use some bits to index one table
* that entry points to the next-level table
* keep going until the final mapping is found

So “walk” just means **traversing the page-table hierarchy to resolve a translation**.

---

# 6. Is it a B-tree?

You asked whether page tables are using something like a B-tree.

Answer: **not in the usual sense**.

Page tables are **tree-like**, but they are not B-trees with key comparisons and balancing.

They are better thought of as:

* a **multi-level hierarchical table**
* a **radix-tree-like structure**
* a tree of **fixed-size arrays**

The virtual address bits are split into chunks, and each chunk is used as an **array index** at one level.

So page-table lookup is more like:

```text
[address bits] -> index level 1 array
               -> index level 2 array
               -> index level 3 array
               -> final entry
```

Not:

* compare keys
* choose subtree by range
* rebalance nodes

---

# 7. The TLB

The **TLB** stands for **Translation Lookaside Buffer**.

It is a **small, fast cache inside the CPU** that stores recent **virtual-page -> physical-frame** translations.

This exists because checking multi-level page tables on every memory access would be too slow.

So the memory access path is roughly:

1. process uses a virtual address
2. CPU checks the TLB
3. if translation is cached, that is a **TLB hit**
4. if not cached, that is a **TLB miss**
5. CPU performs a **page table walk**
6. result is often inserted into the TLB for next time

Important clarification:

When we say the TLB stores “translations,” we mean:

* **virtual address translation**
* more precisely **virtual page number -> physical frame number**

The offset inside the page stays the same.

---

# 8. TLB miss vs page fault

These are different.

## TLB miss

Means:

* “I do not currently have this translation cached.”

This does **not** automatically mean an error.

The page may still be valid and present. The CPU just has to walk the page tables.

## Page fault

Means:

* “The translation cannot be completed normally without kernel help.”

This can happen because:

* the address is invalid
* the page is valid but not yet loaded into RAM
* copy-on-write needs to happen
* lazy allocation needs to happen

So a **page fault is more serious than a TLB miss**, but it is not always fatal.

---

# 9. What `mmap()` is

We then moved into `mmap()`.

`mmap()` is a system call that asks Linux to:

**create a region in the process’s virtual address space, backed either by a file or by anonymous memory.**

So `mmap()` lets Linux add a new virtual memory region to your process.

Two big cases:

## File-backed mapping

A region of the process’s virtual memory corresponds to bytes in a file.

So instead of calling `read()` and copying file contents into your own buffer, the file is exposed through memory addresses.

## Anonymous mapping

Memory not backed by a file.

Used for things like:

* fresh zeroed memory
* large allocations
* thread stacks
* shared anonymous memory between processes

---

# 10. How virtual memory supports `mmap()`

This was one of your key questions.

Virtual memory supports `mmap()` because Linux can define **different kinds of virtual memory regions** with different backing rules.

So Linux can say:

* this virtual range is stack
* this one is heap
* this one is code
* this one is shared library
* this one is a mapped file
* this one is anonymous memory

All of them are just regions in the process’s virtual address space, but the kernel treats them differently.

So `mmap()` is basically Linux using the virtual memory abstraction to create a new mapping rule.

---

# 11. Lazy loading and “not in RAM yet”

This was the subtle part that confused you, so it is worth reviewing carefully.

When you `mmap()` a file, Linux often does **not** immediately read the whole file into RAM.

Instead, it sets up the **virtual mapping first**.

So after `mmap()`:

* the virtual region exists
* the address range is valid
* Linux knows it is backed by a file

But the actual page contents may **not yet be loaded into physical memory**

This is **lazy loading**.

So there are two separate questions:

## 1. Is the virtual address valid?

Meaning: does this address belong to a legal mapped region?

## 2. Is the page currently in physical RAM?

Meaning: has Linux loaded or allocated the backing page yet?

A page can be:

* valid in the virtual address space
* but not yet present in RAM

That is normal.

When the process first touches such an address:

1. CPU tries the access
2. page fault occurs
3. kernel checks and sees it is part of a valid mapping
4. kernel loads the file page into RAM or allocates a zero page
5. updates the page table
6. retries the instruction
7. access succeeds

So “not in RAM yet” does **not** mean the address is invalid. It means the mapping exists, but the physical backing page has not been materialized yet.

---

# 12. `read()` vs `mmap()`

We also discussed the intuition:

## With `read()`

You explicitly ask the kernel to copy file contents into a user buffer.

## With `mmap()`

The file is represented as part of your virtual memory.

You access bytes like ordinary memory, and Linux loads pages on demand.

So `mmap()` blurs the distinction between “file” and “memory.”

---

# 13. Shared vs private mappings

We touched on two important `mmap()` modes:

## `MAP_SHARED`

The mapping is shared.

If multiple processes map the same file shared, they may see each other’s modifications. Writes may propagate back to the file.

## `MAP_PRIVATE`

The mapping is private.

Usually implemented with **copy-on-write**.

That means processes can initially share physical pages, but when one writes, Linux gives it its own private copy.

This is closely related to how `fork()` works too.

---

# 14. Shared libraries and `mmap()`

We noted that shared libraries are a classic example.

When a process uses something like `libc.so`, Linux can map the library file into the process’s virtual address space.

Read-only code pages can often be shared among many processes, which saves RAM.

So one physical copy of the library code can serve many processes.

---

# 15. Physical RAM, virtualization, and time sharing

You asked whether physical RAM “partakes in time sharing or virtualization.”

The clean answer is:

## RAM is definitely virtualized

That is what virtual memory is doing.

Processes see private virtual address spaces, while Linux maps those onto a shared physical RAM pool.

## RAM is not time-shared in the same direct way as CPU

CPU is classically time-shared:

* process A runs now
* process B runs next

Only so many threads can run at once, so CPU execution gets sliced over time.

RAM is different. It is more naturally:

* **space-shared**
* **virtualized**
* **reused over time**

Meaning:

* multiple processes can have pages resident in RAM at the same time
* frames can later be freed and reused
* pages can be swapped out, reclaimed, or remapped

So RAM is not time-sliced in the same sense as CPU. It is better described as a virtualized and space-shared resource, with reuse over time.

---

# 16. One integrated picture

Putting it all together:

1. **Program on disk** exists as an executable file
2. Linux starts it and creates a **process**
3. That process gets a **virtual address space**
4. The virtual space is divided into **pages**
5. Linux keeps **page tables** that map virtual pages to physical RAM frames
6. The CPU uses the **TLB** to cache recent translations
7. On a TLB miss, the CPU does a **page table walk**
8. On certain missing conditions, a **page fault** occurs and the kernel handles it
9. `mmap()` uses this same system to add new memory regions, possibly backed by files
10. Physical RAM is the real underlying storage resource, but processes interact with the virtual abstraction

---

# 17. The most important distinctions we clarified

These are the ones worth memorizing.

## Program vs process

* program = file on disk
* process = running instance with memory, registers, resources

## Virtual memory vs physical memory

* virtual memory = what the process sees
* physical memory = actual RAM

## Virtual page vs physical frame

* page = chunk of virtual address space
* frame = chunk of physical RAM

## Page table vs TLB

* page table = full mapping structure
* TLB = small fast cache of recent mappings

## TLB miss vs page fault

* TLB miss = translation not cached
* page fault = translation needs kernel intervention

## Valid virtual address vs page present in RAM

* an address can be valid
* yet its page may not be loaded into RAM yet

## Page table walk

* traversal of page-table levels to resolve a mapping
* not searching for empty space

## Page-table hierarchy vs B-tree

* tree-like, yes
* B-tree, no

## CPU time sharing vs RAM virtualization

* CPU is time-sliced
* RAM is virtualized and space-shared

---

# 18. Best one-line mental model

If you only remember one thing, remember this:

**A process uses virtual addresses; Linux and the CPU translate those through page tables into physical RAM, with the TLB accelerating recent translations.**

And for `mmap()` specifically:

**`mmap()` makes a file or memory object appear as a region in the process’s virtual address space.**

---

# 19. Even shorter cheat sheet

```text
Program = executable file on disk
Process = running program

Virtual address space = the memory layout a process sees
Physical RAM = the real hardware memory

Page = virtual-memory chunk
Frame = physical-memory chunk

Page table = maps virtual pages to physical frames
TLB = tiny CPU cache of recent mappings

TLB miss = not cached
Page fault = kernel must step in

mmap() = create a new virtual memory region,
         backed by a file or anonymous memory

Valid address != already in RAM
```