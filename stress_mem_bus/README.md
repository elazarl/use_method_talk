# Thrashing the LLC cachce

## Introduction

This code tries to demonstrate the effects of stressing the
memory bus by showing that one unrelated software thrashing
the L3 cache can make other unrelated process slower.

While the effect is visibile in the PMU counters, that is
thrashing the L3 cache in one process leads to higher number
of LLC cache misses in another process,
the process who have high LLC cache misses is consistently
wall-clock-faster.

Why?

## How do I run it myself

To simply run the two cases

```
$ ./do_bench_with_background_process.sh </dev/null
```

In order to sample the process run it with

```
$ PERFCMD="sudo perf record -e LLC-loads:u -c 10" \
    ./do_bench_with_background_process.sh </dev/null
```

You would end with `perf.data`, and `perf.data.old` files for running with and without thrashing
respectively.

## The Problem

Let me explain how I run the trial:

### Case 1 - LLC Cache at Rest

One background `cachemiss` is running with `-c 1 -T 16`. That is,
it runs 16 threads each thread touches a single byte in the memory.

This `cachemiss` instance  is running on all CPUs but the first.

While the background `cachemiss` process is running, we'll run
a single `cachemiss -c 1` process on the first CPU which is at
rest.

I expect the LLC cache of the foreground process not to have many cache
misses.

### Case 2 - Thrashing the LLC Cache

One background `cachemiss` process is running with `-c 1,000 -T 16`. That is,
it runs 16 threads each thread touches 1,000 bytes, each byte is
in a different L1 cacheline.

This `cachemiss` instance  is running on all CPUs but the first.

While the background `cachemiss` process is running, we'll run
a single `cachemiss -c 1` process on the first CPU which is at
rest.

I expect the LLC cache miss rate to be higher on the foreground process,
since the background process is thrashing the LLC cache.

### The Surprising results

I tried to eliminate all other effects but the cache effect in the two
cases. In both we have the same total number of threads.

While indeed, as we expect, in the first case the foreground process
consistently get much less LLC cache misses than the background one,
we also observe a strange phenomena.

In the second case, the total wallclock run time of the foreground process is
consistently _lower_ than the total wallclock run time of the foreground process
in the first case.

This happens even if both have a similar number of L1 cache misses, and
similar number of context switches.

## CPU counters

Let's take a look at the CPU counters in an example run:

In userspace we have for LLC consistently more misses for the process
running with LLC thrashing in the background.

```
No-Thrash  Thrash
-------------------------------------------------------------------------------
 4,729     10,676     LLC-loads:u
 1,074      4,999     LLC-load-misses:u
   394      7,313     LLC-store-misses:u
 5,751    426,785     LLC-stores:u
60,014    100,751     LLC-loads:k
14,921     31,411     LLC-load-misses:k
 1,065      1,013     LLC-store-misses:k
 8,813     10,692     LLC-stores:k
```

Other PMU counters are simliar between both processes, with or without thrashing in the background

```
No-Thrash              Thrash
-------------------------------------------------------------------------------
           669             660   context-switches
    17,730,370      29,133,586   cycles:k
     7,840,629       9,064,612   instructions:k
 8,834,335,587   8,320,404,401   cycles:u
 5,918,218,343   5,794,756,495   instructions:u
        12,719          22,215   cache-misses:u
   355,741,591     325,581,855   L1-dcache-load-misses
         1,978           4,626   L1-dcache-loads
        58,686          60,161   branch-misses
        65,550          73,758   branch-load-misses
 1,209,621,756   1,200,712,033   branches
 1,213,306,763   1,201,974,160   branch-loads
```

Yet, the total run time of the process who makes a lot of LLC cache misses is by far lower than
the total run time of the process who uses the LLC cache.

```
No-Thrash 5.919917684 seconds time elapsed
Thrash    3.060153113 seconds time elapsed
```

## The mystery

Why is it happening?

The process is most definitely CPU-bound, and something is blocking it.

The effects of the background process thrashing the cache shouldn't be too bad, after all, it
runs on different CPUs.

Obviously, the cache is not the limiting factor, and I assume the OS is playing a role in here,
but what is the limiting factor?

## Raw run

```
But wait! We might be innocent! Let's run again the base benchmark with -c 1
taskset 0xfffe ./cachemiss -t -1 -T 16 -c 1
Using 1 cachelines, touching memory -1 times L3 Cache size 4,194,000, 16 threads
perf stat -e context-switches,cycles:k,instructions:k,cycles:u,instructions:u,cache-misses:u,LLC-loads:u,LLC-load-misses:u,LLC-store-misses:u,LLC-stores:u,LLC-loads:k,LLC-load-misses:k,LLC-store-misses:k,LLC-stores:k,L1-dcache-load-misses:u,L1-dcache-loads:u,branch-misses,branch-load-misses,branches,branch-loads ./cachemiss -c 10 -t 1,000,000,000

Using 10 cachelines, touching memory 1,000,000,000 times L3 Cache size 4,194,000, 1 threads

 Performance counter stats for './cachemiss -c 10 -t 1,000,000,000':

               669      context-switches
        17,730,370      cycles:k                                                      (21.04%)
         7,840,629      instructions:k            #    0.44  insns per cycle          (26.25%)
     8,834,335,587      cycles:u                                                      (26.46%)
     5,918,218,343      instructions:u            #    0.67  insns per cycle          (26.57%)
            12,719      cache-misses:u                                                (26.90%)
             4,729      LLC-loads                                                     (26.81%)
             1,074      LLC-load-misses           #   22.71% of all LL-cache hits     (26.92%)
               394      LLC-store-misses                                              (10.40%)
             5,751      LLC-stores                                                    (10.73%)
            60,014      LLC-loads                                                     (10.86%)
            14,921      LLC-load-misses           #   24.86% of all LL-cache hits     (10.86%)
             1,065      LLC-store-misses                                              (10.61%)
             8,813      LLC-stores                                                    (10.39%)
       355,741,591      L1-dcache-load-misses     #  17984913.60% of all L1-dcache hits    (15.51%)
             1,978      L1-dcache-loads                                               (15.73%)
            58,686      branch-misses             #    0.00% of all branches          (10.48%)
            65,550      branch-load-misses                                            (10.22%)
     1,209,621,756      branches                                                      (15.45%)
     1,213,306,763      branch-loads                                                  (20.63%)

       5.919917684 seconds time elapsed

NOTE: last LLC stats are for kernel
./do_bench_with_background_process.sh: line 8: 19552 Terminated              taskset 0xfffe ./cachemiss -t -1 -T $THREADS "$@"
Now, let's run in a different CPU a process that thrashes the cache
taskset 0xfffe ./cachemiss -t -1 -T 16 -c 1,000 -A
Using 1,000 cachelines, touching memory -1 times L3 Cache size 4,194,000, 16 threads
and run the exact same benchmark
taskset 0x1 perf stat -e context-switches,cycles:k,instructions:k,cycles:u,instructions:u,cache-misses:u,LLC-loads:u,LLC-load-misses:u,LLC-store-misses:u,LLC-stores:u,LLC-loads:k,LLC-load-misses:k,LLC-store-misses:k,LLC-stores:k,L1-dcache-load-misses:u,L1-dcache-loads:u,branch-misses,branch-load-misses,branches,branch-loads ./cachemiss -c 10 -t 1,000,000,000
Using 10 cachelines, touching memory 1,000,000,000 times L3 Cache size 4,194,000, 1 threads

 Performance counter stats for './cachemiss -c 10 -t 1,000,000,000':

               660      context-switches
        29,133,586      cycles:k                                                      (20.33%)
         9,064,612      instructions:k            #    0.31  insns per cycle          (25.63%)
     8,320,404,401      cycles:u                                                      (25.98%)
     5,794,756,495      instructions:u            #    0.70  insns per cycle          (26.80%)
            22,215      cache-misses:u                                                (26.87%)
            10,676      LLC-loads                                                     (26.78%)
             4,999      LLC-load-misses           #   46.82% of all LL-cache hits     (26.54%)
             7,313      LLC-store-misses                                              (10.60%)
           426,785      LLC-stores                                                    (10.73%)
           100,751      LLC-loads                                                     (10.68%)
            31,411      LLC-load-misses           #   31.18% of all LL-cache hits     (10.73%)
             1,013      LLC-store-misses                                              (10.86%)
            10,692      LLC-stores                                                    (11.04%)
       325,581,855      L1-dcache-load-misses     #  7038085.93% of all L1-dcache hits    (16.29%)
             4,626      L1-dcache-loads                                               (16.06%)
            60,161      branch-misses             #    0.01% of all branches          (10.68%)
            73,758      branch-load-misses                                            (10.25%)
     1,200,712,033      branches                                                      (15.11%)
     1,201,974,160      branch-loads                                                  (20.34%)

       3.060153113 seconds time elapsed

./do_bench_with_background_process.sh: line 8: 19599 Terminated              taskset 0xfffe ./cachemiss -t -1 -T $THREADS "$@"
```

## Assembly

The critical loop is the following, ignore the post and pre
blocks, it looks correct. Loop, and actually access the given
memory address.

```
=--------------------------------------------------------=
|  0x400c00                                              |
| (fcn) sym.touchcache 106                               |
|   sym.touchcache ();                                   |
| push rbp                                               |
| push rbx                                               |
| sub rsp, 8                                             |
| movsxd rdi, dword [obj.ncachelines]                    |
| movsxd rbp, dword [obj.L1CACHELINE]                    |
| mov rbx, rdi                                           |
| imul rdi, rbp                                          |
| call sym.imp.malloc ;[a];  void *malloc(size_t size);  |
| mov rsi, qword [obj.times]                             |
| test rsi, rsi                                          |
| jle 0x400c59 ;[b]                                      |
=--------------------------------------------------------=
        f t
        '---------.-------------------.
                  |                   |
                  |                   |
          =--------------------=      |
          |  0x400c2c          |      |
          | lea edi, [rbx - 1] |      |
          | nop                |      |
          =--------------------=      |
              v                       |
              |                       |
              |       .---------.     |
       =--------------------=   |     |
       |  0x400c30          |   |     |
       | test ebx, ebx      |   |     | ; ebx = ncachelines
       | jle 0x400c30 ;[d]  |   |     | ; ebx = ncachelines
       =--------------------=   |     |
             t f                |     |
            .--'                |     |
            |                   |     |
            |                   |     |
    =--------------------=      |     |
    |  0x400c34          |      |     |
    | mov rcx, rax       |      |     | ; rax = cachelines[]
    | xor edx, edx       |      |     |
    | nop dword [rax]    |      |     |
    =--------------------=      |     |
        v                       |     |
        '-----------------.     |     |
                          |     |     |
                          .     .     .
                          |     |     |
        .-----------------'     |     |
        |                       |     |
  .-------.                     |     |
  | =--------------------=      |     |
  | |  0x400c40          |      |     |
  | | add edx, 1         |      |     |
  | | mov byte [rcx], 0  |      |     |
  | | add rcx, rbp       |      |     | ; rcx += ncachelines
  | | cmp ebx, edx       |      |     | ; while (i < ncachelines)
  | | jne 0x400c40 ;[e]  |      |     |
  | =--------------------=      |     |
  `-------' f                   |     |
            |                   |     |
            |                   |     |
            |                   |     |
    =--------------------=      |     |
    |  0x400c4d          |      |     |
    | sub rsi, 1         |      |     | ; times -= ncachelines
    | sub rsi, rdi       |      |     |
    | test rsi, rsi      |      |     | ; loop while (times > 0)
    | jg 0x400c30 ;[d]   |      |     |
    =--------------------=      |     |
            f `-----------------'     |
         .--'-------------------------'
         | |
         | |
 =------------------------------------------------=
 |  0x400c59                                      |
 | mov rdi, rax                                   |
 | call sym.imp.free ;[c]; void free(void *ptr);  |
 | add rsp, 8                                     |
 | xor eax, eax                                   |
 | pop rbx                                        |
 | pop rbp                                        |
 | ret                                            |
 =------------------------------------------------=
```

# Update: Architectures it happened on

Here is an example output with CPU info

```
But wait! We might be innocent! Let's run again the base benchmark with -c 1
taskset 0xfffe ./cachemiss -t -1 -T 16 -c 1
Using 1 cachelines, touching memory -1 times L3 Cache size 4,194,000, 16 threads
perf stat -e context-switches,cycles:k,instructions:k,cycles:u,instructions:u,cache-misses:u,LLC-loads:u,LLC-load-misses:u,LLC-store-misses:u,LLC-stores:u,LLC-loads:k,LLC-load-misses:k,LLC-store-misses:k,LLC-stores:k,L1-dcache-load-misses:u,L1-dcache-loads:u,branch-misses,branch-load-misses,branches,branch-loads ./cachemiss -c 10 -t 1,000,000,000
Using 10 cachelines, touching memory 1,000,000,000 times L3 Cache size 4,194,000, 1 threads

 Performance counter stats for './cachemiss -c 10 -t 1,000,000,000':

               779      context-switches                                            
        30,376,493      cycles:k                                                      (21.49%)
         8,902,740      instructions:k            #    0.29  insns per cycle          (27.20%)
     9,108,443,365      cycles:u                                                      (26.93%)
     5,793,664,558      instructions:u            #    0.64  insns per cycle          (26.89%)
             4,540      cache-misses:u                                                (27.11%)
             6,740      LLC-loads                                                     (26.56%)
             1,082      LLC-load-misses           #   16.05% of all LL-cache hits     (26.07%)
               514      LLC-store-misses                                              (10.50%)
             7,937      LLC-stores                                                    (10.63%)
            86,815      LLC-loads                                                     (10.67%)
            10,582      LLC-load-misses           #   12.19% of all LL-cache hits     (10.56%)
             1,431      LLC-store-misses                                              (10.48%)
            10,829      LLC-stores                                                    (10.68%)
       364,086,818      L1-dcache-load-misses     #  15151344.90% of all L1-dcache hits    (15.92%)
             2,403      L1-dcache-loads                                               (15.69%)
            99,659      branch-misses             #    0.01% of all branches          (10.35%)
           114,561      branch-load-misses                                            (10.71%)
     1,178,683,400      branches                                                      (15.97%)
     1,183,829,828      branch-loads                                                  (21.15%)

       3.926921046 seconds time elapsed

NOTE: last LLC stats are for kernel
./do_bench_with_background_process.sh: line 10:  9298 Terminated              taskset 0xfffe ./cachemiss -t -1 -T $THREADS "$@"

Now, let's run in a different CPU a process that thrashes the cache
taskset 0xfffe ./cachemiss -t -1 -T 16 -c 1,000 -A
Using 1,000 cachelines, touching memory -1 times L3 Cache size 4,194,000, 16 threads
and run the exact same benchmark 
taskset 0x1 perf stat -e context-switches,cycles:k,instructions:k,cycles:u,instructions:u,cache-misses:u,LLC-loads:u,LLC-load-misses:u,LLC-store-misses:u,LLC-stores:u,LLC-loads:k,LLC-load-misses:k,LLC-store-misses:k,LLC-stores:k,L1-dcache-load-misses:u,L1-dcache-loads:u,branch-misses,branch-load-misses,branches,branch-loads ./cachemiss -c 10 -t 1,000,000,000
Using 10 cachelines, touching memory 1,000,000,000 times L3 Cache size 4,194,000, 1 threads

 Performance counter stats for './cachemiss -c 10 -t 1,000,000,000':

               666      context-switches                                            
        29,144,298      cycles:k                                                      (20.50%)
         8,094,386      instructions:k            #    0.28  insns per cycle          (25.94%)
     8,366,756,226      cycles:u                                                      (26.02%)
     5,896,569,104      instructions:u            #    0.70  insns per cycle          (25.98%)
            25,381      cache-misses:u                                                (25.92%)
            11,425      LLC-loads                                                     (26.56%)
             3,615      LLC-load-misses           #   31.64% of all LL-cache hits     (26.47%)
            19,821      LLC-store-misses                                              (10.93%)
            32,976      LLC-stores                                                    (11.04%)
           110,609      LLC-loads                                                     (11.06%)
            19,012      LLC-load-misses           #   17.19% of all LL-cache hits     (10.52%)
               931      LLC-store-misses                                              (10.64%)
            16,118      LLC-stores                                                    (11.11%)
       325,894,683      L1-dcache-load-misses     #  8116928.59% of all L1-dcache hits    (16.21%)
             4,015      L1-dcache-loads                                               (15.86%)
            59,982      branch-misses             #    0.01% of all branches          (10.65%)
            69,266      branch-load-misses                                            (10.29%)
     1,199,149,524      branches                                                      (15.50%)
     1,200,763,042      branch-loads                                                  (20.62%)

       3.020254079 seconds time elapsed

# dmidecode 3.0
Getting SMBIOS data from sysfs.
SMBIOS 2.7 present.

Handle 0x0042, DMI type 4, 42 bytes
Processor Information
	Socket Designation: SOCKET 0
	Type: Central Processor
	Family: Core i7
	Manufacturer: Intel
	ID: 51 06 04 00 FF FB EB BF
	Signature: Type 0, Family 6, Model 69, Stepping 1
	Flags:
		FPU (Floating-point unit on-chip)
		VME (Virtual mode extension)
		DE (Debugging extension)
		PSE (Page size extension)
		TSC (Time stamp counter)
		MSR (Model specific registers)
		PAE (Physical address extension)
		MCE (Machine check exception)
		CX8 (CMPXCHG8 instruction supported)
		APIC (On-chip APIC hardware supported)
		SEP (Fast system call)
		MTRR (Memory type range registers)
		PGE (Page global enable)
		MCA (Machine check architecture)
		CMOV (Conditional move instruction supported)
		PAT (Page attribute table)
		PSE-36 (36-bit page size extension)
		CLFSH (CLFLUSH instruction supported)
		DS (Debug store)
		ACPI (ACPI supported)
		MMX (MMX technology supported)
		FXSR (FXSAVE and FXSTOR instructions supported)
		SSE (Streaming SIMD extensions)
		SSE2 (Streaming SIMD extensions 2)
		SS (Self-snoop)
		HTT (Multi-threading)
		TM (Thermal monitor supported)
		PBE (Pending break enabled)
	Version: Intel(R) Core(TM) i7-4600U CPU @ 2.10GHz
	Voltage: 1.2 V
	External Clock: 100 MHz
	Max Speed: 2100 MHz
	Current Speed: 2100 MHz
	Status: Populated, Enabled
	Upgrade: Socket rPGA988B
	L1 Cache Handle: 0x0043
	L2 Cache Handle: 0x0044
	L3 Cache Handle: 0x0045
	Serial Number: Not Specified
	Asset Tag: Fill By OEM
	Part Number: Fill By OEM
	Core Count: 2
	Core Enabled: 2
	Thread Count: 4
	Characteristics:
		64-bit capable

```
