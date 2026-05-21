# Lab 2 Extra — CMake Build System Reference

[![Hardware](https://img.shields.io/badge/Hardware-STM32_NUCLEO--F412ZG-03234B.svg?logo=stmicroelectronics&logoColor=white)](https://www.st.com/en/evaluation-tools/nucleo-f412zg.html)
[![Toolchain](https://img.shields.io/badge/Toolchain-arm--none--eabi--gcc-A8B9CC.svg?logo=arm&logoColor=white)](https://developer.arm.com/downloads/-/arm-gnu-toolchain-downloads)
[![Build system](https://img.shields.io/badge/Build_system-CMake_3.22+-064F8C.svg?logo=cmake)](https://cmake.org)

> **Read-only reference.** This lab has no deliverables and is not graded.
> Its purpose is to show the same Lab 1 firmware built with CMake so you can
> compare it directly against the Makefile you wrote in Lab 2.1.

---

## Table of Contents

- [Lab 2 Extra — CMake Build System Reference](#lab-2-extra--cmake-build-system-reference)
  - [Table of Contents](#table-of-contents)
  - [Why this exists](#why-this-exists)
  - [How to build](#how-to-build)
  - [Directory structure](#directory-structure)
  - [Make vs CMake — concept map](#make-vs-cmake--concept-map)
    - [The one concept with no Make equivalent: the toolchain file](#the-one-concept-with-no-make-equivalent-the-toolchain-file)
  - [When to prefer CMake over Make](#when-to-prefer-cmake-over-make)
  - [When Make is still the right tool](#when-make-is-still-the-right-tool)
  - [How CMake works under the hood](#how-cmake-works-under-the-hood)

---

## Why this exists

In Lab 2 you wrote a Makefile from scratch. Make is the traditional build
system for C/embedded projects, and understanding it is essential.

CMake is a **build-system generator**: instead of describing _how_ to compile
(tab-indented shell commands), you describe _what_ to build (targets, sources,
flags). CMake then generates the actual build files — Makefiles, Ninja files,
Visual Studio projects — for whatever platform you are on.

Most real-world embedded projects (STM32CubeIDE, Zephyr, ESP-IDF) use CMake.
After Lab 2 you have the foundations to read and understand them.

---

## How to build

```bash
# 0 — Copy your completed Lab 1 solution into this workspace
#     (the repo ships with the unresolved Lab 1 skeleton)
bash scripts/copy_lab1.sh <path-to-your-lab1-repo>

# 1 — Configure: CMake reads CMakeLists.txt and generates build files in build/
#     Linux / WSL (default generator = Unix Makefiles):
cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake
#
#     Windows Git Bash — specify the generator and make program explicitly:
#       GnuWin32 Make:  cmake -B build -G "MinGW Makefiles" -DCMAKE_MAKE_PROGRAM=make -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake
#       Ninja:          cmake -B build -G "Ninja" -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake

# 2 — Build: compile and link (equivalent to: make all)
cmake --build build

# 3 — Size report (equivalent to: make size)
cmake --build build --target size

# 4 — Flash to board (equivalent to: make flash)
cmake --build build --target flash

# 5 — Clean (equivalent to: make clean)
cmake --build build --target clean
# or simply delete the build directory:
rm -rf build
```

Override flags at configure time (equivalent to `make all EXTRA_CFLAGS="-DDEBUG"`):

```bash
cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake \
      -DEXTRA_CFLAGS="-DDEBUG"
cmake --build build
```

Artifacts after a successful build:

```text
build/
  lab2.elf   ← ELF with debug symbols (used by GDB / OpenOCD)
  lab2.bin   ← raw binary (used by some programmers)
  lab2.hex   ← Intel HEX (used by STM32CubeProgrammer)
```

---

## Directory structure

```text
Lab2_extra_CMake_Build_System/
├── CMakeLists.txt           ← main build definition (read alongside Lab 2.1 Makefile)
├── cmake/
│   └── arm-none-eabi.cmake  ← cross-compilation toolchain file
├── src/
│   ├── main.c               ← same firmware as Lab 1 / Lab 2.1
│   └── gpio.c
├── inc/
│   ├── board.h              ← pin assignments (PB7 = LD2, PC13 = B1)
│   ├── gpio.h               ← register definitions and driver interface
│   └── rcc.h
├── startup/
│   └── startup_stm32f412zg.s ← Cortex-M4 vector table (provided)
├── linker/
│   └── stm32f412zg.ld       ← memory layout (provided)
└── scripts/
    └── flash.sh             ← OpenOCD flash helper (same logic as Lab 2.1)
```

The C source files and headers are **identical** to the Lab 2.1 reference solution.
Only the build system files (`CMakeLists.txt`, `cmake/`) are new.

---

## Make vs CMake — concept map

Read `CMakeLists.txt` and `cmake/arm-none-eabi.cmake` side-by-side with the
Lab 2.1 `Makefile`. Every concept has a direct equivalent.

| Makefile concept                          | CMake equivalent                                                                                                                           |
| ----------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `CC = arm-none-eabi-gcc`                  | `set(CMAKE_C_COMPILER arm-none-eabi-gcc)` in toolchain file                                                                                |
| `OBJCOPY = arm-none-eabi-objcopy`         | `find_program(CMAKE_OBJCOPY arm-none-eabi-objcopy)` in toolchain file                                                                      |
| `CPU_FLAGS = -mcpu=cortex-m4 ...`         | `CMAKE_C_FLAGS_INIT` / `CMAKE_EXE_LINKER_FLAGS_INIT` in toolchain file                                                                     |
| `EXTRA_CFLAGS ?=`                         | `set(EXTRA_CFLAGS "" CACHE STRING "...")` in CMakeLists.txt                                                                                |
| `TARGET = lab2`                           | `add_executable(lab2 ...)`                                                                                                                 |
| `SRCS = src/main.c src/gpio.c`            | source list inside `add_executable(lab2 ...)`                                                                                              |
| `ASM_SRC = startup/startup_stm32f412zg.s` | same source list — CMake detects `.s` files automatically                                                                                  |
| `OBJS = $(SRCS:$(SRCDIR)/%.c=...)`        | not needed — CMake manages object files internally                                                                                         |
| `-I$(INCDIR)`                             | `target_include_directories(lab2 PRIVATE inc)`                                                                                             |
| `CFLAGS = -O0 -g3 -ffreestanding ...`     | `target_compile_options(lab2 PRIVATE -O0 -g3 ...)`                                                                                         |
| `LDFLAGS = -nostdlib -T linker/...`       | `target_link_options(lab2 PRIVATE -nostdlib -T ...)`                                                                                       |
| `-MMD -MP` + `-include $(wildcard *.d)`   | built-in — CMake tracks header dependencies automatically                                                                                  |
| `$(ELF): $(OBJS) $(ASM_OBJ)` link rule    | implicit — `add_executable` generates the link step                                                                                        |
| `$(OBJCOPY) -O binary ...` (P1.8)         | `add_custom_command(TARGET lab2 POST_BUILD ...)`                                                                                           |
| `clean:` + `.PHONY`                       | `cmake --build build --target clean` (built-in)                                                                                            |
| `size:` + `.PHONY`                        | `add_custom_target(size ...)`                                                                                                              |
| `flash:` + `.PHONY`                       | `add_custom_target(flash ...)`                                                                                                             |
| `$(BUILDDIR):` (output directory)         | not needed — CMake creates `build/` automatically                                                                                          |
| ELF file extension (implicit)             | `set_target_properties(lab2 PROPERTIES SUFFIX ".elf")` — required because CMake's bare-metal `Generic` system adds no extension by default |
| `make all EXTRA_CFLAGS="-DDEBUG"`         | `cmake -B build -DEXTRA_CFLAGS="-DDEBUG"` at configure time                                                                                |

### The one concept with no Make equivalent: the toolchain file

In the Makefile, `CC`, `OBJCOPY`, and `CPU_FLAGS` are variables in the same
file as the build rules. CMake separates these into a **toolchain file**
(`cmake/arm-none-eabi.cmake`) that is loaded before `CMakeLists.txt`. This
separation means the same `CMakeLists.txt` can target different architectures
just by switching the toolchain file — with Make you would need to edit the
Makefile directly.

---

## When to prefer CMake over Make

| Scenario                                    | Why CMake helps                                                                                     |
| ------------------------------------------- | --------------------------------------------------------------------------------------------------- |
| **Multiple target platforms**               | One `CMakeLists.txt`, multiple toolchain files (x86 for unit tests, ARM for firmware)               |
| **Large projects with many subdirectories** | `add_subdirectory()` composes cleanly; Make subdirectory recursion is error-prone                   |
| **IDE integration**                         | VS Code, CLion, STM32CubeIDE all read `CMakeLists.txt` natively; Make requires manual configuration |
| **Dependency management**                   | `FetchContent` / `find_package` fetch and link libraries; Make has no equivalent                    |
| **Out-of-source builds**                    | `cmake -B build` puts all generated files in `build/`; with Make you manage this manually           |
| **Cross-platform CI**                       | CMake generates Ninja on Linux and MSBuild on Windows from the same source                          |
| **Industry standard**                       | Zephyr RTOS, ESP-IDF, STM32Cube ecosystem, LLVM, Qt — all use CMake                                 |

---

## When Make is still the right tool

- **Single-file or very small projects** where a 3-line Makefile suffices.
- **Shell-heavy build pipelines** — Make's recipe syntax is natural for orchestrating arbitrary shell commands; CMake's `add_custom_command` is more verbose.
- **Legacy codebases** already using Make with no multi-platform requirement.
- **Learning builds from first principles** — Make is transparent (you write every rule); CMake hides the generated files.

In this course you wrote the Makefile first for exactly this reason: Make makes the compilation pipeline explicit. CMake is more powerful, but its generated Makefiles or Ninja files are not meant to be read.

---

## How CMake works under the hood

```text
You write:         CMakeLists.txt  +  cmake/arm-none-eabi.cmake
                         │
                   cmake -B build
                         │
CMake generates:   build/Makefile  (or build.ninja if -GNinja)
                         │
                cmake --build build
                         │
  build/ runs:    arm-none-eabi-gcc ...  (same commands as Lab 2.1)
                  arm-none-eabi-objcopy ...
```

The commands that actually compile the code are **identical** to what the Lab 2.1
Makefile runs. CMake is a layer of abstraction that generates those commands for
you. Open `build/CMakeFiles/lab2.dir/build.make` after configuring to see the
generated rules — they mirror the Lab 2.1 Makefile exactly.
