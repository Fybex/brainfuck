# Brainfuck Interpreter in Assembly

This repository contains an Assembly language implementation of a Brainfuck interpreter. It's designed to be compiled into a `.com` executable for DOS.

## File Structure

- `main.asm`: The main Assembly source code file for the Brainfuck interpreter.

## How to Use

1. Write your Brainfuck program into a file.
2. Run the Brainfuck interpreter with the Brainfuck program file as an argument.
3. The interpreter will read the Brainfuck program and interpret it.

## Building

```bash
tasm /s /m /n /q /zn main.asm
tlink /3 /t /n /x main.obj
main code.b <input.txt >output.txt
```
