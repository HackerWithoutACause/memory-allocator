void memory_initialize();

void* memory_allocate(size_t size);
void* memory_reallocate(void* prt, size_t new_size);

void memory_free(void* ptr);
void memory_copy(void* dst, void* src, size_t bytes);
