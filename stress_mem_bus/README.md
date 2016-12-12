# Analysis

This code demonstrates stressing the memory bus
by showing that one unrelated software thrashing L3 cache
can make other unrelated process slower.

## CPU counters

Let's take a look at two perf stat outputs, one of a
`cachemiss` running alone, and the other of 8 `cachemiss`
running.

## Assembly

The critical loop is the following, ignore the post and pre
blocks, it looks correct. Loop, and actually access the given
memory address.

```
  =--------------------------------------------------------=
  |  0x400bb0                                              |
  =--------------------------------------------------------=
              v                         |
              |                         |
       .-------.   .--------------.     |
       | =--------------------=   |     |
       | |  0x400be0          |   |     |
       | | test ebx, ebx ;    | ; ebx = ncachelines
       | | jle 0x400be0 ;[d]  | ; loop while (cachelines > 0)
       | =--------------------=   |     |
       `-------' f                |     |
              .--'                |     |
              |                   |     |
              |                   |     |
      =--------------------=      |     |
      |  0x400be4          |      |     |
      | mov rcx, rax  ; rax = cachelines[] 
      | xor edx, edx       |      |     |
      | nop dword [rax]    |      |     |
      =--------------------=      |     |
          v                       |     |
          |                       |     |
    .-------.                     |     |
    | =--------------------=      |     |
    | | [0x400bf0]         |      |     |
    | | add edx, 1 ; i++   |      |     |
    | | mov byte [rcx], 0  |      |     |
    | | add rcx, rbp ; rcx += ncachelines
    | | cmp ebx, edx ; while (i < ncachelines)
    | | jne 0x400bf0 ;[e]  |      |     |
    | =--------------------=      |     |
    `-------' f                   |     |
              |                   |     |
              |                   |     |
              |                   |     |
      =--------------------=      |     |
      |  0x400bfd          |      |     |
      | sub esi, ebx ; times -= ncachelines
      | test esi, esi ; loop while (times > 0)
      | jg 0x400be0 ;[d]   |      |     |
      =--------------------=      |     |
              f `-----------------'     |
           .--'-------------------------'
           | |
           | |
   =------------------------------------------------=
   |  0x400c03  ....                                |
   =------------------------------------------------=
```
