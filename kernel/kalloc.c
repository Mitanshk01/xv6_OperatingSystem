// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
  struct run *next;
};

struct
{
  struct spinlock lock;
  struct run *freelist;
} kmem;

struct
{
  struct spinlock lock;
  int arr[PGROUNDUP(PHYSTOP) >> 12];
} pagex;

void initialize_page()
{
  initlock(&pagex.lock, "pagex");
  acquire(&pagex.lock);
  uint64 val = PGROUNDUP(PHYSTOP) >> 12;
  for (int i = 0; i < val; i++)
  {
    pagex.arr[i] = 0;
  }
  release(&pagex.lock);
}

int extract_page(void *pa)
{
  acquire(&pagex.lock);
  int res = pagex.arr[(uint64)pa >> 12];
  if (pagex.arr[(uint64)pa >> 12] >= 0)
  {
    release(&pagex.lock);
    return res;
  }
  else
  {
    panic("extract_page");
  }
}

void increment_page(void *pa)
{
  acquire(&pagex.lock);
  uint64 res = (uint64)pa >> 12;
  if (pagex.arr[res] >= 0)
  {
    pagex.arr[res] += 1;
    release(&pagex.lock);
  }
  else
  {
    panic("increment_page");
    return;
  }
}

void decrement_page(void *pa)
{
  acquire(&pagex.lock);
  uint64 res = (uint64)pa >> 12;
  if (pagex.arr[res] > 0)
  {
    pagex.arr[res] -= 1;
    release(&pagex.lock);
  }
  else
  {
    panic("decrement_page");
    return;
  }
}

void kinit()
{
  initialize_page();
  initlock(&kmem.lock, "kmem");
  freerange(end, (void *)PHYSTOP);
}

void freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char *)PGROUNDUP((uint64)pa_start);
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
  {
    increment_page(p);
    kfree(p);
  }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");
  acquire(&pagex.lock);
  if (pagex.arr[(uint64)pa >> 12] <= 0)
  {
    panic("decrement_page");
  }
  pagex.arr[(uint64)pa >> 12] = pagex.arr[(uint64)pa >> 12] - 1;
  if (pagex.arr[(uint64)pa >> 12] > 0)
  {
    release(&pagex.lock);
    return;
  }
  else
  {
    release(&pagex.lock);

    // Fill with junk to catch dangling refs.
    memset(pa, 1, PGSIZE);

    r = (struct run *)pa;

    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    release(&kmem.lock);
  }
  return;
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if (r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if (r)
  {
    memset((char *)r, 100, PGSIZE); // fill with junk
    increment_page((void *)r);
  }
  return (void *)r;
}
