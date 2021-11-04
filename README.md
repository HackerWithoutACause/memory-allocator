# Simple Linux x86 Memory Allocator

A simple C compatible memory allocator written in x86 assembly for 64bit Linux
machines.

## Building and Running

To run the example you need varients of the NASM assembler and a C compiler. If
your using GCC and NASM just run the following commands.

```
nasm -f elf64 memory.s
gcc -Wall example.c memory.o -o example.out -no-pie
./example.out
```

## Explanation

TODO
