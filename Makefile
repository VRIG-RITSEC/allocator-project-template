# Makefile for Allocator Test Suite
# Usage:
#   make                  - Build with glibc allocator (default)
#   make ALLOCATOR=path   - Build with custom allocator
#   make tests            - Build test runner only
#   make bench            - Build benchmark runner only
#   make clean            - Clean build artifacts


CC       ?= gcc
CFLAGS   := -std=c17 -Wall -Wextra -Wpedantic -Werror
CFLAGS   += -fno-strict-aliasing
CFLAGS   += -D_GNU_SOURCE
CFLAGS   += -I./include
CFLAGS   += $(EXTRA_CFLAGS)

# Build modes
ifeq ($(MODE),debug)
    CFLAGS  += -O0 -g3 -fsanitize=address,undefined
    LDFLAGS += -fsanitize=address,undefined
else ifeq ($(MODE),release)
    CFLAGS  += -O2 -DNDEBUG
else ifeq ($(MODE),bench)
    CFLAGS  += -O3 -march=native -DNDEBUG
else
    # Default: optimized with debug info
    CFLAGS  += -O2 -g
endif

LDFLAGS  += -lm -lpthread

# Test sources
TEST_SRCS := src/tests/test_correctness.c \
             src/tests/test_stress.c \
             src/tests/test_edge.c \
             src/tests/test_fragmentation.c \
             src/tests/test_features.c \
             src/harness/main_tests.c

# Benchmark sources
BENCH_SRCS := src/benchmarks/bench_synthetic.c \
              src/harness/main_bench.c

# Default allocator (glibc wrapper)
DEFAULT_ALLOC := allocators/glibc/glibc_allocator.c

# Custom allocator (set via ALLOCATOR=path/to/allocator.c)
ALLOCATOR ?= $(DEFAULT_ALLOC)

BUILD_DIR := build
BIN_DIR   := bin

TEST_BIN  := $(BIN_DIR)/run_tests
BENCH_BIN := $(BIN_DIR)/run_bench

# Object files
TEST_OBJS  := $(patsubst %.c,$(BUILD_DIR)/%.o,$(TEST_SRCS))
BENCH_OBJS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(BENCH_SRCS))
ALLOC_OBJ  := $(BUILD_DIR)/allocator.o

.PHONY: all tests bench clean help run-tests run-bench

all: tests bench

tests: $(TEST_BIN)

bench: $(BENCH_BIN)

# Test binary
$(TEST_BIN): $(TEST_OBJS) $(ALLOC_OBJ) | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	@echo "Built test runner: $@"
	@echo "Allocator: $(ALLOCATOR)"

# Benchmark binary
$(BENCH_BIN): $(BENCH_OBJS) $(ALLOC_OBJ) | $(BIN_DIR)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	@echo "Built benchmark runner: $@"
	@echo "Allocator: $(ALLOCATOR)"

# Compile test sources
$(BUILD_DIR)/src/tests/%.o: src/tests/%.c | $(BUILD_DIR)/src/tests
	$(CC) $(CFLAGS) -c -o $@ $<

# Compile benchmark sources
$(BUILD_DIR)/src/benchmarks/%.o: src/benchmarks/%.c | $(BUILD_DIR)/src/benchmarks
	$(CC) $(CFLAGS) -c -o $@ $<

# Compile harness sources
$(BUILD_DIR)/src/harness/%.o: src/harness/%.c | $(BUILD_DIR)/src/harness
	$(CC) $(CFLAGS) -c -o $@ $<

# Compile allocator (custom or default)
$(ALLOC_OBJ): $(ALLOCATOR) | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c -o $@ $<

# Create directories
$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/src/tests:
	mkdir -p $@

$(BUILD_DIR)/src/benchmarks:
	mkdir -p $@

$(BUILD_DIR)/src/harness:
	mkdir -p $@

$(BIN_DIR):
	mkdir -p $@

run-tests: tests
	@echo ""
	@echo "Running tests..."
	@echo ""
	./$(TEST_BIN) $(ARGS)

run-bench: bench
	@echo ""
	@echo "Running benchmarks..."
	@echo ""
	./$(BENCH_BIN) $(ARGS)

run-quick: bench
	@echo ""
	@echo "Running quick benchmarks..."
	@echo ""
	./$(BENCH_BIN) --quick

debug:
	$(MAKE) MODE=debug all

release:
	$(MAKE) MODE=release all

bench-optimized:
	$(MAKE) MODE=bench bench

clean:
	rm -rf $(BUILD_DIR) $(BIN_DIR)

help:
	@echo "Allocator Test Suite - Build System"
	@echo ""
	@echo "Targets:"
	@echo "  all          Build tests and benchmarks (default)"
	@echo "  tests        Build test runner only"
	@echo "  bench        Build benchmark runner only"
	@echo "  run-tests    Build and run tests"
	@echo "  run-bench    Build and run benchmarks"
	@echo "  run-quick    Build and run quick benchmarks"
	@echo "  debug        Build with debug flags and sanitizers"
	@echo "  release      Build optimized release"
	@echo "  clean        Remove build artifacts"
	@echo ""
	@echo "Variables:"
	@echo "  ALLOCATOR=path  Path to custom allocator source"
	@echo "  MODE=debug      Build with -O0 -g3 -fsanitize"
	@echo "  MODE=release    Build with -O2 -DNDEBUG"
	@echo "  MODE=bench      Build with -O3 -march=native"
	@echo "  ARGS=...        Arguments to pass to runner"
	@echo ""
	@echo "Examples:"
	@echo "  make                                    # Build with glibc"
	@echo "  make ALLOCATOR=../myalloc/myalloc.c    # Build with custom allocator"
	@echo "  make run-tests ARGS='--correctness'    # Run only correctness tests"
	@echo "  make run-bench ARGS='--csv'            # Output benchmarks as CSV"
	@echo "  make debug run-tests                   # Run with AddressSanitizer"
