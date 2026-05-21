# CMakeLists.txt — Lab 2 Extra: CMake reference build for STM32 NUCLEO-F412ZG
#
# This file is READ-ONLY for students. Read it alongside the Lab 2.1 Makefile
# to see how every Make concept maps to its CMake equivalent.
#
# Build commands:
#   cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake
#   cmake --build build
#   cmake --build build --target size
#   cmake --build build --target flash

cmake_minimum_required(VERSION 3.22)

# ---------------------------------------------------------------------------
# Project declaration
# Equivalent to:  TARGET = lab2  in the Makefile
#
# - NAME sets the project namespace (used in CMake internals).
# - LANGUAGES tells CMake which compilers to activate. ASM is needed for
#   the startup file; without it CMake would not know how to compile .s files.
# ---------------------------------------------------------------------------
project(lab2_extra
    VERSION 0.1
    LANGUAGES C ASM
)

# ---------------------------------------------------------------------------
# Optional extra flags (equivalent to:  EXTRA_CFLAGS ?=  in the Makefile)
#
# Override from the command line:
#   cmake -B build ... -DEXTRA_CFLAGS="-DDEBUG"
# Or from the environment via a cmake preset / CI env var.
# ---------------------------------------------------------------------------
set(EXTRA_CFLAGS "" CACHE STRING "Additional compiler flags passed to all C targets")

# ---------------------------------------------------------------------------
# Executable target + source files
# Equivalent to the combination of:
#   SRCS    = src/main.c src/gpio.c
#   ASM_SRC = startup/startup_stm32f412zg.s
#   $(ELF): $(OBJS) $(ASM_OBJ)   ← the link rule
#
# add_executable declares the build artifact and ALL its source files in one
# place. There is no separate "pattern rule" needed — CMake auto-detects the
# language of each file by extension (.c → C compiler, .s → ASM compiler).
# ---------------------------------------------------------------------------
add_executable(lab2
    src/main.c
    src/gpio.c
    startup/startup_stm32f412zg.s
)

# Force the .elf suffix. CMake's "Generic" bare-metal system does not add
# any extension by default, so without this the output is just "lab2".
set_target_properties(lab2 PROPERTIES SUFFIX ".elf")

# ---------------------------------------------------------------------------
# Include directories (equivalent to:  -I$(INCDIR)  in CFLAGS)
#
# PRIVATE means these directories are only for this target, not propagated
# to anything that links against it (irrelevant here — no other targets link
# against lab2, but the keyword makes intent explicit).
# ---------------------------------------------------------------------------
target_include_directories(lab2 PRIVATE inc)

# ---------------------------------------------------------------------------
# Compile options (equivalent to: CFLAGS in the Makefile, minus CPU_FLAGS)
#
# CPU flags (-mcpu, -mthumb, -mfloat-abi) are already injected by the
# toolchain file via CMAKE_C_FLAGS_INIT — do NOT repeat them here.
#
# Note: -MMD / -MP are omitted. CMake generates its own dependency files
# (in build/CMakeFiles/) using compiler-agnostic machinery; there is no need
# to ask GCC to produce .d files manually.
# ---------------------------------------------------------------------------
target_compile_options(lab2 PRIVATE
    -O0                  # no optimisation — easier to debug on hardware
    -g3                  # maximum DWARF debug information
    -ffreestanding       # no hosted C runtime assumed
    -Wall                # standard warning set
    -Wextra              # extended warnings
    ${EXTRA_CFLAGS}      # command-line / CI overrides (see EXTRA_CFLAGS above)
)

# ---------------------------------------------------------------------------
# Linker options (equivalent to:  LDFLAGS  in the Makefile)
#
# target_link_options is the target-scoped equivalent of the global
# add_link_options / set(CMAKE_EXE_LINKER_FLAGS ...) pattern.
# Using target_* commands keeps all settings local to this target.
# ---------------------------------------------------------------------------
target_link_options(lab2 PRIVATE
    -nostdlib                                        # no C runtime (no libc, no crt0)
    -T ${CMAKE_SOURCE_DIR}/linker/stm32f412zg.ld     # memory layout script
)

# ---------------------------------------------------------------------------
# Post-build: generate .bin and .hex  (equivalent to:  P1.8 objcopy rules)
#
# CMake has no built-in conversion step. add_custom_command with POST_BUILD
# hooks into the normal build so these files are always up to date.
#
# Generator expressions:
#   $<TARGET_FILE:lab2>      → absolute path to lab2.elf
#   $<TARGET_FILE_DIR:lab2>  → the directory containing lab2.elf (= build/)
# ---------------------------------------------------------------------------
add_custom_command(TARGET lab2 POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O binary
            $<TARGET_FILE:lab2>
            $<TARGET_FILE_DIR:lab2>/lab2.bin
    COMMAND ${CMAKE_OBJCOPY} -O ihex
            $<TARGET_FILE:lab2>
            $<TARGET_FILE_DIR:lab2>/lab2.hex
    COMMENT "Generating lab2.bin and lab2.hex"
)

# ---------------------------------------------------------------------------
# Utility targets  (equivalent to:  size  and  flash  in the Makefile)
#
# add_custom_target creates a target with no output file — always re-runs
# when requested, exactly like a .PHONY Make target.
# DEPENDS lab2 ensures the firmware is built before these targets run.
# ---------------------------------------------------------------------------
add_custom_target(size
    COMMAND ${CMAKE_SIZE_UTIL} $<TARGET_FILE:lab2>
    DEPENDS lab2
    COMMENT "Firmware size report"
)

add_custom_target(flash
    COMMAND bash ${CMAKE_SOURCE_DIR}/scripts/flash.sh $<TARGET_FILE:lab2>
    DEPENDS lab2
    COMMENT "Flashing firmware via ST-LINK"
)
