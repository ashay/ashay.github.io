---
title: Writing a Compiler
---

# Writing a High-Performance MLIR/LLVM-Based Compiler for RISC-V Processors #

The pages (that will be) linked here describe the key ideas behind writing a
compiler for the RISC-V architecture using the MLIR and LLVM compiler
frameworks.  These pages assume a decent grasp of Computer Architecture and of
programming at a (relatively) low level, like using the C programming language.
Contrary to what the title may suggest, these pages do not assume an in-depth
knowledge of the RISC-V Instruction Set Architecture (ISA).

You might rightfully wonder, since the LLVM backend already includes support for
generating RISC-V instructions, what else is necessary to build a compiler for
RISC-V processors.  The fact is, although LLVM does a lot of the heavy lifting
(for instance, instruction selection, register allocation, various peephole
optimizations, etc.), there are several more parts that need to be built
_around_ LLVM to build a compiler that generates high-performance code for the
processor of your choice.  This includes knowing which parts of LLVM are worth
using while which others are best carefully side stepped with custom code,
knowing how to bootstrap or load the program into device memory (assuming
baremetal execution), generating high quality vector and/or parallel code, and
knowing how to simulate these programs for both functional and performance
debugging.  These pages address the above, secondary aspects of writing a usable
compiler, although one of the chapters does make a brief diversion into what it
would take to write a replacement of LLVM.

## Rationale ##

The foremost reason for writing these pages is that as new technology makes
faster and beefier machines available to us, we (as members of the software
industry) seem to care less and less about code bloat.  Bloat is everywhere now
-- in software that runs on our phones, desktops, laptops, even TVs!

Perhaps the main reason for the omnipresence of bloat is economics: it's often
cheaper to buy or provision a faster machine to the programmer than it is to pay
the programmer to de-bloat the software stack.  Moreover, it's easy to push the
burden to the end user by having short product lifetimes, so that the product
manufacturer has less to plan and maintain.  And when short-term economics is
prioritized over long-term economics, it is clear that it makes no sense to work
on removing bloat.  I have seen this happen often in the companies that I have
worked at.

Now, I am no economist and it's likely that I am missing something crucial,
because this seems like backward thinking.  Hardware is _expensive_ (ask the CFO
of any chip design company).  It seems so much more economical to get the most
of the same hardware by building software carefully, than it is to design and
manufacture new hardware.  But instead, we get severely underutilized hardware.
As examples of specific cases, the Raspberry Pi 3B under my desk (sometimes)
struggles to run a music library software and high-end dedicated
application-specific integrated circuits (ASICs) in state-of-the-art data
centers remain mostly idle.

All this makes me sad, because it means we are all locked into buying newer,
faster machines forever into the future to address the software slop. Not only
are we, as programmers, resigning to this fate, but we're also _forcing the end
users_ of our tools into buying new equipment for perpetuity.  If our end users
cannot or will not go along with this forced choice, we risk leaving them
behind.

Perhaps subtly, these pages are a call to action: to do more for the end users
of our tools, to care more about reducing waste, and to discourage the culture
of prioritizing short-term economics over long-term economics.

Of course, these pages do not describe the pinnacle of high-performance code.
Despite everything I have learnt, there is so much more that I don't know.  It
would incredibly arrogant to say that no one else knows the information in these
pages or that no one else cares.  Instead, my goal in writing this content is to
encourage us to be more open about sharing this knowledge so that we reduce the
barrier to producing lean software.  There is so much for me to learn from
others, and I hope that I can encourage someone else to share what they know.

I fear that without a deliberate effort to share such knowledge or skills, we
risk this information being lost forever.  Perhaps the connection I am about to
make is too grandiose or tenuous, but there are similar concerns in the domain
of manufacturing, where, as a result of outsourcing such jobs, the relevant
knowledge and skills are dying, and there are not enough people left to pass
that information to the next generation.

My hope is that we democratize this knowledge and equip more people to build
better software; software that is lean, flexible, and reliable.

## More Ideas, Less Code ##

I am intentionally not linking a code repository.  The key focus of these pages
is on developing an understanding of the challenges and the ideas to overcome
them. In a way, this content is similar to a graduate seminar: talk about the
principles and the techniques rather that the final artifact.  Besides, this
content is aimed at humans, and not at Large Language Models that might
regurgitate my code into someone else's program.  I want you, dear reader, to
first think, evaluate, critique, and challenge everything that is in these
pages, and _only then_ write your compiler.

## Organization of These Pages ##

I strongly believe that it is easier to build the compiler bottom up instead of
top down.  That is, before _automating_ the code generation, it seems best to
see if you can generate code manually for a smaller, specific instance of the
problem.  Consequently, the first three chapters are specific to the RISC-V
architecture, but the subsequent chapters are broadly applicable to other
instruction sets.

We'll first learn bits of the RISC-V ISA, so that we can start writing tiny
assembly programs by hand.  This will set us up to be able to simulate programs
on Spike, which is a functional simulator for the RISC-V ISA.  Manual register
allocation quickly becomes unwieldy, so we'll switch to writing C/C++ programs
while still having close control over the assembly instructions.  With the goal
of keeping our generated code lean, we'll emit baremetal programs (our programs
will, at least initially, not link against external libraries like libc or
libstdc++), and we'll need to take special steps to be able to bootstrap the
execution.

Programs that operate in a vacuum are hardly useful, so we'll look into how we
can communicate with a (simulated) host for I/O.  The LLVM backend for RISC-V is
still a work in progress, so we'll discuss some workarounds and make a brief
foray into writing our own backend.  We will see how to selectively include
external libraries (such as math functions) while still keeping the bloat fairly
minimal.

Finally, in the last few chapters, we will dive into effective vectorization and
parallelization (for both shared- as well as distributed-memory parallelism),
and in the end, we'll build a domain specific language (DSL) for expressing
programs that we wish to compile to the RISC-V ISA, thus completing our journey
into building the compiler.

## Table of Contents ##

1. [A Primer on the RISC-V ISA](risc-v-primer/)

1. [Creating Trivial RISC-V Executable Files](executable-files/)

1. [Detour: Functional Simulation](functional-simulation/)

1. Baremetal Programming 1: Program Loading

1. Baremetal Programming 2: I/O

1. Working Around LLVM Limitations

1. Selectively Including External Libraries

1. Better Vectorization and Parallelization

1. A DSL for Writing Source Programs
