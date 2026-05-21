# cmake/arm-none-eabi.cmake
# Cross-compilation toolchain file for arm-none-eabi (bare-metal Cortex-M).
#
# Usage:
#   cmake -B build -DCMAKE_TOOLCHAIN_FILE=cmake/arm-none-eabi.cmake
#
# CMake reads this file before processing CMakeLists.txt, so every variable
# set here is available globally — equivalent to the toolchain variables at
# the top of the Makefile (CC, OBJCOPY, CPU_FLAGS, etc.).

# ---------------------------------------------------------------------------
# Target system — tells CMake not to expect a host OS or C runtime.
# "Generic" is the conventional name for bare-metal targets.
# ---------------------------------------------------------------------------
set(CMAKE_SYSTEM_NAME      Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# ---------------------------------------------------------------------------
# Cross-compiler executables
# Equivalent to:  CC = arm-none-eabi-gcc  in the Makefile
# ---------------------------------------------------------------------------
set(CMAKE_C_COMPILER   arm-none-eabi-gcc)
set(CMAKE_ASM_COMPILER arm-none-eabi-gcc)

# Suppress the link-test that CMake runs when it first detects the compiler.
# The test would fail because there is no C runtime to satisfy _start.
# STATIC_LIBRARY skips the link phase of the test.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# ---------------------------------------------------------------------------
# CPU flags — applied to every compile and link step.
# Equivalent to:  CPU_FLAGS = -mcpu=cortex-m4 -mthumb -mfloat-abi=soft
# Placing them here (not in CMakeLists.txt) ensures they cannot be
# accidentally omitted from any target in the project.
# ---------------------------------------------------------------------------
set(CPU_FLAGS "-mcpu=cortex-m4 -mthumb -mfloat-abi=soft")
string(APPEND CMAKE_C_FLAGS_INIT   " ${CPU_FLAGS}")
string(APPEND CMAKE_ASM_FLAGS_INIT " ${CPU_FLAGS}")
string(APPEND CMAKE_EXE_LINKER_FLAGS_INIT " ${CPU_FLAGS}")

# ---------------------------------------------------------------------------
# Utility programs
# find_program raises a fatal error if the binary is not in PATH,
# giving a clear message instead of a cryptic linker failure.
# Equivalent to:  OBJCOPY = arm-none-eabi-objcopy
#                 SIZE    = arm-none-eabi-size
# ---------------------------------------------------------------------------
find_program(CMAKE_OBJCOPY  arm-none-eabi-objcopy REQUIRED)
find_program(CMAKE_SIZE_UTIL arm-none-eabi-size   REQUIRED)
