---
title: Creating Trivial RISC-V Executables Using Assembly Code
---

# Creating Trivial RISC-V Executables Using Assembly Code #

This post shows an approach for generating (relatively) light-weight executable
files.  We use the ELF format, since it enables us to use existing binutils
tools (such as readelf or nm) but if ELF is too bulky or inflexible for your
needs, it is not too difficult to come up with your own executable format. In
that case, it is perhaps easier to first generate ELF files, then extract the
post-relocation bytes from the ELF sections, and then pack the bytes into your
desired format, although doing so will certainly increase the time to produce
the executable artifacts.

Before we automate the process of generating executable code, we are going to
look at how to do this process manually, for the following reasons:

1. to check whether our approach even works,
1. to define a clear goal for our compiler,
1. to assist in debugging programs (that is, to manually create the smallest
   reproducible example of the problem), and finally,
1. to better understand the behavior of an instruction, or a combination of
   instructions, by executing them and observing their side effects (especially
   when the specification is ambiguous).

However, we are soon going to run into a circular dependency.  Specifically,
several parts related to setting up code to execute are highly dependent on the
execution platform, so we cannot write a complete, functioning program without
first knowing a little about execution platform.  In this post, we are going to
break this dependency by generating executables that are not ready to be
executed yet.  Once we learn more about the simulation platform in the next
post, we will revisit our process of generating executable files.

## A Starter ELF File ##

At the very least, to start creating elemetary ELF files, we need the assembly
source file.  For now, we'll start with one that runs in an infinite loop
(recollect that signaling program termination is entirely dependent on the
execution platform, which we will dive into in a later post).  Our barebones
assembly source is:

```
.text
.global _start

_start:
  j 0   # Jump to self, thus looping indefinitely
```

Compiling this source file into an ELF executable file is trivial (`clang
--target=riscv64 -c -nostdlib -o program-0 program.S`), but not only does this
hide several parts of the ELF file generation but it also adds some (small)
unnecessary bits to the ELF file that we probably don't care about, so let's use
the alternative approach that skips some of the defaults to illustrate various
parts of the process.

First, we can compile the assembly source into an object file (`clang
--target=riscv64 -march=rv64i -c program.S -o program.o`), and although
optional, we have explicitly specified that we want to produce an ELF file for a
processor that only supports the base (integer) ISA.  Now that we have the
object file, we will produce the ELF file, but instead of using the default
linker script (which specifies the placement of instructions and data in
memory), let's supply our own, with only the sections we care about.

```
ENTRY (_start)

SECTIONS
{
  /* specify the sections that are in the assembly source */
  .data : { *(.data) }
  .text : { *(.text) }

  /* include certain sections that are required for ELF processing */
  .shstrtab : { *(.shstrtab) }
  .strtab : { *(.strtab) }
  .symtab : { *(.symtab) }

  /* throw away all other sections */
  /DISCARD/ : { *(*) }
}
```

This linker script trims away sections that we don't care about.  When we invoke
the linker with the object file and the above linker script (`ld.lld --nmagic
--script=program.ld -o program-1 program.o`), we get a relatively smaller ELF
file.  Here's what I see on my machine:

```
> ls -lh program-*
-rwxr-xr-x 1 user user 1.3K Apr  2 19:17 program-0*
-rwxr-xr-x 1 user user  904 Apr  2 19:17 program-1*
```

The `--nmagic` option is key to keeping the binary size small; since we
anticipate only a few sections in the ELF file, having these sections at
page-aligned offsets doesn't help us much, so we use `--nmagic` to pack all
loadable sections as closely as possible in the ELF file.

I am sure that there are more techniques possible to trim the ELF file size
further, but this seems good enough given that we didn't have to expend a lot of
effort to get to 904 bytes.

## ELF File with Real Computation ##

One of the main reasons why writing assembly by hand for non-trivial programs
becomes complicated is because of manual register allocation.  Specifically, we
not only need to reason about register usage in the face of potentially complex
control flows, but we also need to re-analyze the register usage each time we
need to add or remove lines from the assembly code.  For instance, here is a
RISC-V assembly program that computes the sum of the values in each row of a 4x7
matrix.

```
.set ROWS, 4
.set COLS, 7

.text
.global _start

_start:
  la    t0, input     # source pointer
  la    t1, output    # result pointer
  li    t3, ROWS      # outer loop counter

outer:
  li    t2, 0         # result
  li    t4, COLS      # inner loop counter

inner:
  lw    t5, 0(t0)     # read from source pointer into t5
  add   t2, t2, t5    # accumulate result for a single row in t2
  addi  t0, t0, 4     # bump source pointer by four bytes
  addi  t4, t4, -1    # decrement inner loop counter
  bnez  t4, inner

  sw    t2, 0(t1)
  addi  t1, t1, 4     # bump result pointer by four bytes
  addi  t3, t3, -1    # decrement outer loop counter
  bnez  t3, outer

  j     0             # infinite loop as a proxy for termination logic


.data

input:
  # use assembler syntax to create a 4x7 matrix
  .set outer_idx, 0
  .rept ROWS
    .set inner_idx, 0
      .rept COLS
        .word outer_idx + inner_idx
        .set inner_idx, inner_idx + 1
      .endr
    .set outer_idx, outer_idx + 1
  .endr

output:
  # initialize the result with zeros
  .rept ROWS
    .word 0
  .endr
```

Even in this trivial example, correctly deciding which register(s) to use in
each instruction is difficult.  If we need to update the code in inner loop,
we would then need to recompute the liveness of each register.  And all this is
before we even need to spill registers and keep track of spill slots!

Indeed, if the vector extension is available to us, this same snippet of code
becomes a lot shorter, with fewer registers to reason about, but it is still
easy to make mistakes.

```
.set ROWS, 4
.set COLS, 7

.text
.global _start

_start:
  li            t0, 0x600
  csrrc         t1, mstatus, t0
  or            t1, t1, t0
  csrw          mstatus, t1       # set MSTATUS.VS to enable vector instructions
  vsetivli      zero, COLS, e32, m1, tu, ma

  la            t0, input         # source pointer
  la            t1, output        # result pointer
  li            t2, ROWS          # outer loop counter

  vmv.s.x       v4, zero          # v4[0] = 0

loop:
  vle32.v       v0, 0(t0)
  vredsum.vs    v8, v0, v4
  vmv.x.s       t3, v8
  sw            t3, 0(t1)
  addi          t0, t0, COLS * 4  # bump source pointer to the next row
  addi          t1, t1, 4         # bump result pointer to the next element
  addi          t2, t2, -1        # decrement outer loop counter
  bnez          t2, loop

  j             0                 # infinite loop as a proxy for termination


.data

input:
  # use assembler syntax to create a 4x7 matrix
  .set outer_idx, 0
  .rept ROWS
    .set inner_idx, 0
      .rept COLS
        .word outer_idx + inner_idx
        .set inner_idx, inner_idx + 1
      .endr
    .set outer_idx, outer_idx + 1
  .endr

output:
  # initialize the result with zeros
  .rept ROWS
    .word 0
  .endr
```

But all of this becomes a lot easier to do if we use C or C++ with vector
intrinsics, since doing so lets us focus on the instructions, while leaving the
tedious part of register allocation to the LLVM backend.  That's coming up in
the next post.
