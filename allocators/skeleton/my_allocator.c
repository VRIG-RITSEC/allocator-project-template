#include "allocator.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <unistd.h>

/*
 * STUDENT_ALLOCATOR: A skeleton implementation.
 * Goal: Replace these with your own logic (e.g., Free List, Buddy, Slab).
 */

static int my_init(void) { return 0; }

static void my_teardown(void) {}

static void *my_malloc(size_t size) {
  if (size == 0)
    return NULL;
  size_t rounded_size = (size + 4095) & ~4095;
  void *ptr = mmap(NULL, rounded_size, PROT_READ | PROT_WRITE,
                   MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
  if (ptr == MAP_FAILED)
    return NULL;
  return ptr;
}

static void my_free(void *ptr) {
  // Naive implementation: leaking memory as we don't know the size
  (void)ptr;
}

static void *my_realloc(void *ptr, size_t size) {
  if (!ptr)
    return my_malloc(size);
  if (size == 0) {
    my_free(ptr);
    return NULL;
  }
  void *new_ptr = my_malloc(size);
  if (new_ptr) {
    memcpy(new_ptr, ptr, size); // Warning: possible overflow if size > old_size
    my_free(ptr);
  }
  return new_ptr;
}

static void *my_calloc(size_t nmemb, size_t size) {
  size_t total = nmemb * size;
  void *ptr = my_malloc(total);
  if (ptr)
    memset(ptr, 0, total);
  return ptr;
}

allocator_t allocator = {.malloc = my_malloc,
                         .free = my_free,
                         .realloc = my_realloc,
                         .calloc = my_calloc,
                         .init = my_init,
                         .teardown = my_teardown,
                         .name = "studentv1",
                         .author = "Student Name",
                         .version = "0.1.0",
                         .description = "My first custom allocator",
                         .memory_backend = "mmap",
                         .features = {.thread_safe = false,
                                      .per_thread_cache = false,
                                      .huge_page_support = false,
                                      .guard_pages = false,
                                      .guard_location = GUARD_NONE,
                                      .min_alignment = 8,
                                      .max_alignment = 4096}};

allocator_t *get_test_allocator(void) { return &allocator; }

allocator_t *get_bench_allocator(void) { return &allocator; }