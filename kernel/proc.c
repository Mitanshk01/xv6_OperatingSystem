#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "defs.h"
#include <stddef.h>

queue Create_Queue()
{
  queue qu;
  qu.front = 0;
  qu.rear = 0;
  qu.numitems = 0;
  return qu;
}

void enqueue(queue *qu, queue_element el)
{
  qu->arr[qu->rear] = el;
  qu->rear = (qu->rear + 1) % 64;
  qu->numitems++;
  // if (el->pid > 9)
    printf("%d %d %d\n", ticks, el->pid, el->mlfq_priority);
  return;
}

void dequeue(queue *qu)
{
  if (!qu->numitems)
    return;
  qu->numitems--;
  qu->front = (qu->front + 1) % 64;
}

int isempty(queue qu)
{
  return (qu.numitems == 0);
}

queue_element front(queue qu)
{
  return qu.arr[qu.front];
}

int max(int a, int b)
{
  return a > b ? a : b;
}

int min(int a, int b)
{
  return a < b ? a : b;
}

queue mlfq[5];

uint random(void)
{
  // Take from http://stackoverflow.com/questions/1167253/implementation-of-rand
  static unsigned int z1 = 12345, z2 = 12345, z3 = 12345, z4 = 12345;
  unsigned int b;
  b = ((z1 << 6) ^ z1) >> 13;
  z1 = ((z1 & 4294967294U) << 18) ^ b;
  b = ((z2 << 2) ^ z2) >> 27;
  z2 = ((z2 & 4294967288U) << 2) ^ b;
  b = ((z3 << 13) ^ z3) >> 21;
  z3 = ((z3 & 4294967280U) << 7) ^ b;
  b = ((z4 << 3) ^ z4) >> 12;
  z4 = ((z4 & 4294967168U) << 13) ^ b;

  return (z1 ^ z2 ^ z3 ^ z4) / 2;
}

int randomrange(int lo, int hi)
{
  int range = hi - lo + 1;
  return random() % (range) + lo;
}
struct cpu cpus[NCPU];

struct proc proc[NPROC];

struct proc *initproc;

int nextpid = 1;
struct spinlock pid_lock;

extern void forkret(void);
static void freeproc(struct proc *p);

extern char trampoline[]; // trampoline.S

uint64 sys_uptime(void); // NEW

// helps ensure that wakeups of wait()ing
// parents are not lost. helps obey the
// memory model when using p->parent.
// must be acquired before any p->lock.
struct spinlock wait_lock;

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
  }
}

// initialize the proc table.
void procinit(void)
{
  struct proc *p;

  initlock(&pid_lock, "nextpid");
  initlock(&wait_lock, "wait_lock");
  for (p = proc; p < &proc[NPROC]; p++)
  {
    initlock(&p->lock, "proc");
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
  }
}

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
  int id = r_tp();
  return id;
}

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
  int id = cpuid();
  struct cpu *c = &cpus[id];
  return c;
}

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
  push_off();
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
  pop_off();
  return p;
}

uint64
priority(struct proc *p)
{
  p->niceness = 5;
  if (p->run_time + p->sleep_time)
    p->niceness = (p->sleep_time * 10 / (p->run_time + p->sleep_time));
  uint64 DP = max(0, min(p->stat_priority - p->niceness + 5, 100));
  return DP;
}

int allocpid()
{
  int pid;

  acquire(&pid_lock);
  pid = nextpid;
  nextpid = nextpid + 1;
  release(&pid_lock);

  return pid;
}

void queue_swap(queue *q, int pid)
{
  for (int curr = q->front; curr != q->rear; curr = (curr + 1) % (NPROC + 1))
  {
    if (q->arr[curr]->pid == pid)
    {
      q->arr[curr] = q->arr[(curr + 1) % (NPROC + 1)];
    }
  }

  q->rear--;
  if (q->rear < 0)
    q->rear = NPROC;
  q->numitems--;
}

// Look in the process table for an UNUSED proc.
// If found, initialize state required to run in the kernel,
// and return with p->lock held.
// If there are no free procs, or a memory allocation fails, return 0.
static struct proc *
allocproc(void)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->state == UNUSED)
    {
      goto found;
    }
    else
    {
      release(&p->lock);
    }
  }
  return 0;

found:
  p->pid = allocpid();
  p->state = USED;

  p->init_time = ticks;
  // p->total_time_in = ticks;

  p->run_time = 0;
  p->end_time = 0;
  p->sleep_time = 0;
  p->runs_till_now = 0;
  p->tickets = 1;

  // Allocate a trapframe page.
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  if ((p->cpy_trapframe = (struct trapframe *)kalloc()) == 0)
  {
    release(&p->lock);
    return 0;
  }
  p->mlfq_priority = 0;
  p->queue_in_time = 0;
  p->runs_till_now = 0;
  for (int i = 0; i <= 4; i++)
    p->queue_run_time[i] = 0;
  p->queued = 0;

  p->quantums_left = 1;

  p->stat_priority = 60;
  p->niceness = 5;

  p->is_sigalarm = 0;
  p->clockval = 0;
  p->completed_clockval = 0;
  p->handler = 0;

  p->age_queue[0] = -10;
  p->age_queue[1] = 10;
  p->age_queue[2] = 20;
  p->age_queue[3] = 30;
  p->age_queue[4] = 40;

  p->wait_time = 0;

#ifdef MLFQ
  for (int i = 0; i <= 4; i++)
    mlfq[i] = Create_Queue();
#endif

  // An empty user page table.
  p->pagetable = proc_pagetable(p);

  if (p->pagetable == 0)
  {
    freeproc(p);
    release(&p->lock);
    return 0;
  }

  // Set up new context to start executing at forkret,
  // which returns to user space.
  memset(&p->context, 0, sizeof(p->context));
  p->context.ra = (uint64)forkret;
  p->context.sp = p->kstack + PGSIZE;

  return p;
}

int set_priority(int new_priority, int proc_pid)
{
  int old_priority = 0, found = 0;
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == proc_pid)
    {
      found = 1;
      old_priority = p->stat_priority;
      p->run_time = 0;
      p->stat_priority = new_priority;
      release(&p->lock);
      if (old_priority >= new_priority)
        break;
      yield();
      break;
    }
    release(&p->lock);
  }
  if (!found)
    printf("no process with pid : %d exists\n", proc_pid);
  return old_priority;
}

static void
freeproc(struct proc *p)
{
  //
  if (p)
  {
    if (p->trapframe)
      kfree((void *)p->trapframe);

    if (p->cpy_trapframe)
      kfree((void *)p->cpy_trapframe);
    p->trapframe = 0;
    if (p->pagetable)
      proc_freepagetable(p->pagetable, p->sz);
    p->pagetable = 0;
    p->sz = 0;
    p->pid = 0;
    p->parent = 0;
    p->name[0] = 0;
    p->chan = 0;
    p->killed = 0;
    p->xstate = 0;
    p->state = UNUSED;
  }
}

// Create a user page table for a given process, with no user memory,
// but with trampoline and trapframe pages.
pagetable_t
proc_pagetable(struct proc *p)
{
  pagetable_t pagetable;

  // An empty page table.
  pagetable = uvmcreate();
  if (pagetable == 0)
    return 0;

  // map the trampoline code (for system call return)
  // at the highest user virtual address.
  // only the supervisor uses it, on the way
  // to/from user space, so not PTE_U.
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
               (uint64)trampoline, PTE_R | PTE_X) < 0)
  {
    uvmfree(pagetable, 0);
    return 0;
  }

  // map the trapframe page just below the trampoline page, for
  // trampoline.S.
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
               (uint64)(p->trapframe), PTE_R | PTE_W) < 0)
  {
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    uvmfree(pagetable, 0);
    return 0;
  }

  return pagetable;
}

// Free a process's page table, and free the
// physical memory it refers to.
void proc_freepagetable(pagetable_t pagetable, uint64 sz)
{
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
  uvmfree(pagetable, sz);
}

// a user program that calls exec("/init")
// assembled from ../user/initcode.S
// od -t xC ../user/initcode
uchar initcode[] = {
    0x17, 0x05, 0x00, 0x00, 0x13, 0x05, 0x45, 0x02,
    0x97, 0x05, 0x00, 0x00, 0x93, 0x85, 0x35, 0x02,
    0x93, 0x08, 0x70, 0x00, 0x73, 0x00, 0x00, 0x00,
    0x93, 0x08, 0x20, 0x00, 0x73, 0x00, 0x00, 0x00,
    0xef, 0xf0, 0x9f, 0xff, 0x2f, 0x69, 0x6e, 0x69,
    0x74, 0x00, 0x00, 0x24, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x00, 0x00, 0x00};

// Set up first user process.
void userinit(void)
{
  struct proc *p;

  p = allocproc();
  initproc = p;

  // allocate one user page and copy initcode's instructions
  // and data into it.
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
  p->sz = PGSIZE;

  // prepare for the very first "return" from kernel to user.
  p->trapframe->epc = 0;     // user program counter
  p->trapframe->sp = PGSIZE; // user stack pointer

  safestrcpy(p->name, "initcode", sizeof(p->name));
  p->cwd = namei("/");

  p->state = RUNNABLE;

#ifdef MLFQ
  if (p && !p->queued)
  {
    enqueue(&mlfq[0], p);
    p->queue_in_time = ticks;
    p->queued = 1;
    p->mlfq_priority = 0;
    p->wait_time = 0;
  }
#endif
  release(&p->lock);
}

// Grow or shrink user memory by n bytes.
// Return 0 on success, -1 on failure.
int growproc(int n)
{
  uint64 sz;
  struct proc *p = myproc();

  sz = p->sz;
  if (n > 0)
  {
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    {
      return -1;
    }
  }
  else if (n < 0)
  {
    sz = uvmdealloc(p->pagetable, sz, sz + n);
  }
  p->sz = sz;
  return 0;
}

// Create a new process, copying the parent.
// Sets up child kernel stack to return as if from fork() system call.
int fork(void)
{
  int i, pid;
  struct proc *np;
  struct proc *p = myproc();

  // Allocate process.
  if ((np = allocproc()) == 0)
  {
    return -1;
  }

  // Copy user memory from parent to child.
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
  {
    freeproc(np);
    release(&np->lock);
    return -1;
  }
  np->sz = p->sz;

  // copy saved user registers.
  *(np->trapframe) = *(p->trapframe);

  // Cause fork to return 0 in the child.
  np->trapframe->a0 = 0;
  np->bitmask = p->bitmask;

  np->tickets = p->tickets;

  // increment reference counts on open file descriptors.
  for (i = 0; i < NOFILE; i++)
    if (p->ofile[i])
      np->ofile[i] = filedup(p->ofile[i]);
  np->cwd = idup(p->cwd);

  safestrcpy(np->name, p->name, sizeof(p->name));

  pid = np->pid;

  release(&np->lock);

  acquire(&wait_lock);
  np->parent = p;
  release(&wait_lock);

  acquire(&np->lock);
  np->state = RUNNABLE;
#ifdef MLFQ
  if (np && !np->queued && p->queued)
  {
    enqueue(&mlfq[0], np);
    np->queued = 1;
    np->queue_in_time = ticks;
    np->mlfq_priority = 0;
    np->wait_time = 0;
  }
#endif
  release(&np->lock);

  return pid;
}

// Pass p's abandoned children to init.
// Caller must hold wait_lock.
void reparent(struct proc *p)
{
  struct proc *pp;

  for (pp = proc; pp < &proc[NPROC]; pp++)
  {
    if (pp->parent == p)
    {
      pp->parent = initproc;
      wakeup(initproc);
    }
  }
}

// Exit the current process.  Does not return.
// An exited process remains in the zombie state
// until its parent calls wait().
void exit(int status)
{
  struct proc *p = myproc();

  if (p == initproc)
    panic("init exiting");

  // Close all open files.
  for (int fd = 0; fd < NOFILE; fd++)
  {
    if (p->ofile[fd])
    {
      struct file *f = p->ofile[fd];
      fileclose(f);
      p->ofile[fd] = 0;
    }
  }

  begin_op();
  iput(p->cwd);
  end_op();
  p->cwd = 0;

  acquire(&wait_lock);

  // Give any children to init.
  reparent(p);

  // Parent might be sleeping in wait().
  wakeup(p->parent);

  acquire(&p->lock);

  p->xstate = status;
  p->state = ZOMBIE;
  p->end_time = ticks;

  release(&wait_lock);

  // Jump into the scheduler, never to return.
  sched();
  panic("zombie exit");
}

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int wait(uint64 addr)
{
  struct proc *pp;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (pp = proc; pp < &proc[NPROC]; pp++)
    {
      if (pp->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&pp->lock);

        havekids = 1;
        if (pp->state == ZOMBIE)
        {
          // Found one.
          pid = pp->pid;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
                                   sizeof(pp->xstate)) < 0)
          {
            release(&pp->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(pp);
          release(&pp->lock);
          release(&wait_lock);
          return pid;
        }
        release(&pp->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

int waitx(uint64 addr, uint *rtime, uint *wtime)
{
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();

  acquire(&wait_lock);

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    for (np = proc; np < &proc[NPROC]; np++)
    {
      if (np->parent == p)
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
        {
          // Found one.
          pid = np->pid;
          *rtime = np->total_run_time;
          *wtime = np->end_time - np->init_time - np->total_run_time;
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
                                   sizeof(np->xstate)) < 0)
          {
            release(&np->lock);
            release(&wait_lock);
            return -1;
          }
          freeproc(np);
          release(&np->lock);
          release(&wait_lock);
          return pid;
        }
        release(&np->lock);
      }
    }

    // No point waiting if we don't have any children.
    if (!havekids || p->killed)
    {
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
  }
}

void lock_ptable()
{
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    acquire(&p->lock);
}

void release_ptable(struct proc *e)
{
  for (struct proc *p = proc; p < &proc[NPROC]; p++)
    if (p != e)
      release(&p->lock);
}

// Per-CPU process scheduler.
// Each CPU calls scheduler() after setting itself up.
// Scheduler never returns.  It loops, doing:
//  - choose a process to run.
//  - swtch to start running that process.
//  - eventually that process transfers control
//    via swtch back to the scheduler.

// switchkvm();
void scheduler(void)
{
  struct cpu *c = mycpu();
  c->proc = 0;
  for (;;)
  {
    intr_on();

#ifdef FCFS
    struct proc *temp_proc = NULL;
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    {
      // lock acquired
      acquire(&p->lock);
      if (p->state != RUNNABLE)
      {
        release(&p->lock);
        continue;
      }
      else
      {
        if (!temp_proc)
        {
          temp_proc = p;
          continue;
        }
        if (temp_proc->init_time > p->init_time)
        {
          // release the previous lock
          temp_proc = p;
          release(&temp_proc->lock);
          continue;
        }
      }
      // release the lock if proc is not choosen
      release(&p->lock);
    }
    if (temp_proc)
    {
      temp_proc->state = RUNNING;
      c->proc = temp_proc;
      swtch(&c->context, &temp_proc->context);
      c->proc = 0;
      release(&temp_proc->lock);
    }
#else
#ifdef RR
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE)
      {
        p->state = RUNNING;
        c->proc = p;
        swtch(&c->context, &p->context);
        c->proc = 0;
      }
      release(&p->lock);
    }
#else
#ifdef PBS
    int minimum_priority_tillnow = 105, dyn_priority = 0;
    struct proc *proc_min_priority = NULL;
    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state != RUNNABLE)
      {
        release(&p->lock);
        continue;
      }
      dyn_priority = priority(p);
      if (!proc_min_priority)
      {
        proc_min_priority = p;
        minimum_priority_tillnow = dyn_priority;
      }
      else if (dyn_priority == minimum_priority_tillnow)
      {

        if ((proc_min_priority->runs_till_now == p->runs_till_now && p->init_time >= proc_min_priority->init_time) || p->runs_till_now >= proc_min_priority->runs_till_now)
        {
          // If current process is not optimal then simply release the lock...
          release(&p->lock);
          continue;
        }
        // change the process with min_priority and update it by releasing previus lock
        release(&proc_min_priority->lock);
        proc_min_priority = p;
        minimum_priority_tillnow = dyn_priority;
      }
      else if (dyn_priority < minimum_priority_tillnow)
      {
        release(&proc_min_priority->lock);
        proc_min_priority = p;
        minimum_priority_tillnow = dyn_priority;
      }
      else
        release(&p->lock);
    }
    if (proc_min_priority)
    {
      proc_min_priority->state = RUNNING;
      proc_min_priority->run_time = 0;
      proc_min_priority->sleep_time = 0;
      proc_min_priority->runs_till_now++;
      c->proc = proc_min_priority;
      swtch(&c->context, &proc_min_priority->context);
      c->proc = 0;
      release(&proc_min_priority->lock);
    }
#else
#ifdef LBS
    uint64 count = 0;
    uint64 golden_ticket = 0;
    uint64 total_no_tickets = 0;

    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    {
      if (p->state == RUNNABLE)
      {
        acquire(&p->lock);
        total_no_tickets += p->tickets;
        release(&p->lock);
      }
    }

    if (total_no_tickets)
      golden_ticket = randomrange(1, total_no_tickets);

    for (struct proc *p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state != RUNNABLE)
      {
        release(&p->lock);
        continue;
      }

      if ((count + p->tickets) < golden_ticket)
      {
        count += p->tickets;
        release(&p->lock);
      }
      else
      {
        c->proc = p;
        p->state = RUNNING;
        swtch(&c->context, &p->context);
        c->proc = 0;
        release(&p->lock);
        break;
      }
    }
#else
#ifdef MLFQ
    // printf("Here\n");
    struct proc *proc_to_run = 0, *p = 0;
    // Reset priority for old processes /Aging/

    // Queue Process...
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p->state == RUNNABLE && !p->queued)
      {
        enqueue(&mlfq[p->mlfq_priority], p);
        p->queue_in_time = ticks;
        p->queued = 1;
        p->wait_time = 0;
      }
      release(&p->lock);
    }

    // This is correct...aging
    for (p = proc; p < &proc[NPROC]; p++)
    {
      acquire(&p->lock);
      if (p && p->state == RUNNABLE && p->mlfq_priority && ticks - p->queue_in_time >= p->age_queue[p->mlfq_priority])
      {
        if (p->queued)
        {
          queue_swap(&mlfq[p->mlfq_priority], p->pid);
          p->mlfq_priority--;
          enqueue(&mlfq[p->mlfq_priority], p);
          p->queue_in_time = ticks;
          p->wait_time = 0;
        }
      }
      release(&p->lock);
    }
    for (int level = 0; level < 5; level++)
    {
      while (mlfq[level].numitems)
      {
        p = front(mlfq[level]);
        dequeue(&mlfq[level]);
        //
        if (p)
        {
          acquire(&p->lock);
          p->queued = 0;
          if (p->state == RUNNABLE)
          {
            proc_to_run = p;
            break;
          }
          release(&p->lock);
        }
      }
      if (proc_to_run)
        break;
    }
    if (!proc_to_run)
      continue;
    proc_to_run->state = RUNNING;
    if (p->quantums_left <= 0)
      proc_to_run->quantums_left = 1 << proc_to_run->mlfq_priority;
    c->proc = proc_to_run;
    proc_to_run->runs_till_now++;
    swtch(&c->context, &proc_to_run->context);
    c->proc = 0;
    proc_to_run->queue_in_time = ticks;
    release(&proc_to_run->lock);
#endif
#endif
#endif
#endif
#endif
  }
}

void update_time()
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
#ifdef MLFQ
    if (p->queued)
      p->queue_run_time[p->mlfq_priority]++;
#endif
    if (p->state == RUNNING)
    {
      p->run_time++;
      p->total_run_time++;
#ifdef MLFQ
      p->quantums_left--;
      p->queue_run_time[p->mlfq_priority]++;
#endif
    }
    else if (p->state == SLEEPING)
      p->sleep_time++;
    else if (p->state == RUNNABLE)
    {
      p->wait_time++;
#ifdef MLFQ
      if (p && p->wait_time > p->age_queue[p->mlfq_priority] && p->queued && p->mlfq_priority)
      {
        queue_swap(&mlfq[p->mlfq_priority], p->pid);
        p->queued = 0;
        p->mlfq_priority--;
        enqueue(&mlfq[p->mlfq_priority], p);
        p->queued = 1;
        p->wait_time = 0;
        p->queue_in_time = ticks;
      }
#endif
    }
    release(&p->lock);
  }
}

// Switch to scheduler.  Must hold only p->lock
// and have changed proc->state. Saves and restores
// intena because intena is a property of this
// kernel thread, not this CPU. It should
// be proc->intena and proc->noff, but that would
// break in the few places where a lock is held but
// there's no process.
void sched(void)
{
  int intena;
  struct proc *p = myproc();

  if (!holding(&p->lock))
    panic("sched p->lock");
  if (mycpu()->noff != 1)
    panic("sched locks");
  if (p->state == RUNNING)
    panic("sched running");
  if (intr_get())
    panic("sched interruptible");

  intena = mycpu()->intena;
  swtch(&p->context, &mycpu()->context);
  mycpu()->intena = intena;
}

// Give up the CPU for one scheduling round.
void yield(void)
{
  struct proc *p = myproc();
  acquire(&p->lock);
  p->state = RUNNABLE;
  if (!p->queued)
  {
#ifdef MLFQ
    enqueue(&mlfq[p->mlfq_priority], p);
    p->wait_time = 0;
    p->queued = 1;
    p->queue_in_time = ticks;
#endif
  }
  sched();
  release(&p->lock);
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);

  if (first)
  {
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
}

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
  struct proc *p = myproc();

  // Must acquire p->lock in order to
  // change p->state and then call sched.
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
  release(lk);

  // Go to sleep.
  p->chan = chan;
  p->state = SLEEPING;

  sched();

  // Tidy up.
  p->chan = 0;

  // Reacquire original lock.
  release(&p->lock);
  acquire(lk);
}

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p && p->state == SLEEPING && p->chan == chan)
      {
        p->state = RUNNABLE;
#ifdef MLFQ
        if (!p->queued)
        {
          p->queued = 1;
          p->queue_in_time = ticks;
          enqueue(&mlfq[p->mlfq_priority], p);
          p->wait_time = 0;
        }
#endif
      }
      release(&p->lock);
    }
  }
}

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
  {
    acquire(&p->lock);
    if (p->pid == pid)
    {
      p->killed = 1;
      if (p->state == SLEEPING)
      {
        // Wake process from sleep().
        p->state = RUNNABLE;
#ifdef MLFQ
        if (!p->queued)
        {
          p->queued = 1;
          p->queue_in_time = ticks;
          enqueue(&mlfq[p->mlfq_priority], p);
        }
#endif
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
  }
  return -1;
}

void setkilled(struct proc *p)
{
  acquire(&p->lock);
  p->killed = 1;
  release(&p->lock);
}

int killed(struct proc *p)
{
  int k;
  acquire(&p->lock);
  k = p->killed;
  release(&p->lock);
  return k;
}

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
  struct proc *p = myproc();
  if (user_dst)
  {
    return copyout(p->pagetable, dst, src, len);
  }
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
  struct proc *p = myproc();
  if (user_src)
  {
    return copyin(p->pagetable, dst, src, len);
  }
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
  static char *states[] = {
      [UNUSED] "unused",
      [USED] "used",
      [SLEEPING] "sleep ",
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;
  printf("\n");

  for (p = proc; p < &proc[NPROC]; p++)
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
      state = states[p->state];
    else
      state = "???";
#ifdef RR
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
#else
#ifdef FCFS
    printf("%d %s %s", p->pid, state, p->name);
    printf("\n");
#else
#ifdef PBS
    printf("%d\t%d\t\t%s\t%d\t%d\t%d\n", p->pid, priority(p), state, p->total_run_time, ticks - p->init_time - p->total_run_time, p->runs_till_now);
#else
#ifdef LBS
    printf("%d %s %sc%d\n", p->pid, state, p->name, p->tickets);
#else
#ifdef MLFQ
    int wtime = ticks - p->init_time - p->total_run_time;
    printf("%d %d %s %d %d %d %d %d %d %d %d\n", p->pid, p->mlfq_priority, state, p->total_run_time, wtime, p->runs_till_now, p->queue_run_time[0], p->queue_run_time[1], p->queue_run_time[2], p->queue_run_time[3], p->queue_run_time[4]);
#endif
#endif
#endif
#endif
#endif
  }
}