# COOL Compiler Front-End Implementation

## ⚠️ Academic Integrity Notice

This repository contains my solution to a programming assignment for CS 426 (Compiler Construction) at the University of Illinois at Urbana-Champaign. If you are currently enrolled in this course or plan to take it in the future:

- **DO NOT** copy or submit this code as your own work
- **DO NOT** use this code as a reference for your own assignment
- **DO NOT** share this code with other students

Doing any of the above constitutes academic dishonesty and can result in serious consequences, including:
- Failing grade in the course
- Academic probation
- Permanent notation on your academic record
- Other disciplinary actions by the University

Instead, develop your own solution to learn and understand the concepts thoroughly.

## Project Overview

This project implements the front-end components of a compiler for the Classroom Object-Oriented Language (COOL). The implementation includes:

- A lexical analyzer (lexer) using Flex
- A syntax analyzer (parser) using Bison
- Extended language features beyond basic COOL

### Key Features

- Extended COOL grammar support for:
  - Hexadecimal number literals
  - Python-style multi-line strings
  - C-style for loops
- Robust error handling and recovery
- Comprehensive test suite
- Integration with LLVM backend

## Project Structure

```
.
├── src/
│   ├── cool.flex          # Lexical analyzer implementation
│   ├── cool.y            # Parser implementation
│   ├── flex_test.cl      # Lexer test file
│   ├── bison_test_good.cl # Parser test file (valid syntax)
│   └── bison_test_bad.cl  # Parser test file (syntax errors)
├── cool-support/         # Support code provided by course staff
└── reference-binaries/   # Reference implementations
```

## Building and Running

### Prerequisites
- Flex
- Bison
- GCC/G++
- LLVM (version 15)

### Build Instructions
```bash
# Build lexer
cd src/
make lexer

# Build parser
make parser

# Build both
make all
```

### Running Tests
```bash
# Test lexer
lexer flex_test.cl

# Test parser
lexer bison_test_good.cl | parser
```

## References

- CoolAid: The Cool Reference Manual
- Flex Documentation
- Bison Documentation
- Course Materials (CS 426 - Compiler Construction)
