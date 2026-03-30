---
name: performance-review
description: >-
  Analyze code, architecture, or systems for real performance costs — runtime
  complexity, memory allocation patterns, I/O bottlenecks, lock contention,
  cache behavior, and unnecessary abstraction overhead. Use when the user has
  a performance problem, asks "why is this slow?", "is this efficient?",
  "what's the complexity of this?", "will this scale?", "is this over-engineered?",
  "does this need to be this complex?", "what's the runtime cost?", "profiling
  this", "find the bottleneck", "it's too slow in production", "latency issues",
  "memory pressure", "CPU bound or I/O bound?", mentions "Big O", "profiler",
  "cache miss", "lock contention", "performance regression", or asks for a
  systems-level reality check on an architecture.
---

# Performance Review

Identify where code is actually slow, why it's slow, and what the minimum intervention is to fix it. Performance problems are almost always in one place — find that place before touching anything else.

> *"Premature optimization is the root of all evil."* — Donald Knuth
> *"But profile first."* — Everyone who has debugged production

**Skill workflow** — performance review often follows architecture review:
**`performance-review`** *(find the cost)* → [`triage-bug`](#) *(root-cause a specific regression)* → [`refactoring`](#) *(fix it)*

---

## Philosophy

Most performance problems are not where you think they are. The cardinal sin is optimizing without measuring. The second sin is over-engineering a system to handle load it will never see.

The correct order:
1. **Make it work** (correctness)
2. **Profile** (find the actual bottleneck — it's almost never where you guessed)
3. **Fix the bottleneck** (targeted, minimal intervention)
4. **Measure again** (verify the fix had the expected effect)

Intuition about performance is wrong more often than it is right. Measure everything.

---

## Complexity Analysis

Before profiling, reason about algorithmic complexity. A O(n²) algorithm in a hot path is always the first thing to fix — no amount of low-level optimization saves you from the wrong algorithm.

### Big O Reference

| Complexity | Name | Practical meaning |
|------------|------|-----------------|
| O(1) | Constant | Hash lookup, array index access |
| O(log n) | Logarithmic | Binary search, balanced tree lookup |
| O(n) | Linear | Single scan of n elements |
| O(n log n) | Linearithmic | Efficient sort (merge sort, heap sort) |
| O(n²) | Quadratic | Nested loops over the same collection |
| O(2ⁿ) | Exponential | Recursive algorithms without memoization |

### Signals of complexity problems
- Nested loops iterating over the same collection → O(n²) minimum
- Sorting inside a loop → O(n² log n)
- Linear search in a hot path on a large collection → replace with hash lookup
- Recursive algorithm with repeated subproblems → add memoization or convert to DP

---

## Memory Analysis

Memory problems compound: allocations are cheap individually, but GC pressure, heap fragmentation, and cache eviction are expensive at scale.

### Allocation patterns to question
- Creating objects inside tight loops that could be reused or pooled
- String concatenation in loops (creates O(n²) allocations in languages without string builders)
- Large collections held in memory when streaming is sufficient
- Unnecessary copies — does this operation need to materialize the full result?

### Memory layout
- Array of Structs vs Struct of Arrays: iteration patterns determine which is faster
- Cache line size is typically 64 bytes — objects accessed together should live together
- Virtual dispatch (polymorphism) adds indirection that can cause cache misses

---

## I/O and Network

I/O is orders of magnitude slower than computation. The rules:

1. **Batch over individual calls** — 1 query returning 100 rows beats 100 queries returning 1 row each
2. **Lazy loading is a trap** — N+1 query problems are the most common database performance failure
3. **Cache at the right level** — cache computed results, not raw data; cache at the boundary closest to the hot path
4. **Async where possible** — don't block threads waiting for I/O
5. **Connection pooling** — opening a new connection per request is expensive

### N+1 Query Pattern (most common database performance failure)
```python
# N+1 — 1 query to fetch orders + N queries to fetch each customer
orders = Order.find_all()
for order in orders:
    print(order.customer.name)  # triggers a query per order

# Fixed — 1 query with JOIN or eager loading
orders = Order.find_all_with_customers()
for order in orders:
    print(order.customer.name)  # no additional queries
```

---

## Concurrency and Locking

Concurrency bugs are the hardest to find and the most expensive in production.

### Lock contention signals
- Threads spending significant time waiting on locks
- A single lock protecting a disproportionately large critical section
- Lock granularity too coarse — can the lock be per-row instead of per-table?

### Questions to ask
- Is the lock necessary? Can this be made lock-free with atomic operations?
- Is the critical section as small as possible?
- Is there read-write asymmetry? (many readers, few writers → read-write lock is better than mutex)
- Are there hidden shared resources (global state, shared caches) that aren't obviously locked?

---

## Abstraction Cost

Every layer of abstraction has a cost. The question is whether the problem it solves justifies that cost.

### Questions for each abstraction layer
- What concrete operation does this ultimately perform?
- How many allocations does this create?
- What's the call depth from the user's request to the actual I/O?
- Can I trace the execution path without reading ten files?

### Signals of unnecessary abstraction overhead
- Frameworks doing reflection, serialization, or dynamic dispatch for operations that could be direct calls
- Middleware chains where most handlers are no-ops for the common path
- ORM generating inefficient SQL for simple queries — sometimes raw SQL is correct
- Event systems adding indirection where a direct function call is sufficient

---

## Process

### 1. Define "slow"
What is the actual problem? Specific numbers — latency percentiles (p50, p95, p99), throughput (req/s), memory (MB at peak), CPU (% under load). "Slow" without numbers is not a problem statement.

### 2. Profile — don't guess
Run the actual code under realistic load with a profiler attached. Find the real hot path. It is almost never where intuition points.

Tools by ecosystem:
- **Python**: `cProfile`, `py-spy`, `memory_profiler`
- **JavaScript/Node**: V8 CPU Profiler, `clinic.js`, `0x`
- **Java/JVM**: JProfiler, YourKit, async-profiler, JFR
- **Go**: `pprof`
- **Rust**: `perf`, `flamegraph`
- **Database**: `EXPLAIN ANALYZE` (Postgres), `EXPLAIN` (MySQL), query plan visualizers

### 3. Find the bottleneck
Focus on the top item in the profiler — it's almost always one thing responsible for the majority of the time. The 80/20 rule applies: 20% of the code causes 80% of the latency.

### 4. Evaluate the fix
For each bottleneck:
- Is this algorithmic? Fix the algorithm — no micro-optimization needed
- Is this I/O? Batch, cache, or async
- Is this allocation? Pool, reuse, or reduce
- Is this lock contention? Reduce critical section or reduce sharing
- Is this unnecessary work? Remove it entirely

### 5. Measure the fix
Apply the targeted change. Profile again. Verify the bottleneck moved or disappeared. Don't stop until the numbers change.

---

## Anti-patterns

- **Optimizing without measuring** — the bottleneck is almost never where you think it is
- **Micro-optimizing the wrong path** — 10% faster on 1% of execution time is noise
- **Premature abstraction for "future scale"** — design for the load you have, profile for the load you see
- **Cache everything** — caches add complexity, introduce invalidation problems, and hide bad queries; cache only after proving you need it
- **Rewriting for performance** — rewrites are high-risk; targeted fixes to the real bottleneck are almost always sufficient

---

## Scope

This skill handles: complexity analysis, memory analysis, I/O and query performance, concurrency and lock review, abstraction cost evaluation, profiling strategy.

This skill does **not** handle: architecture-level decisions (use Fowler via `@fowler`), identifying root cause of a specific regression (use `triage-bug`), refactoring the fix into place (use `refactoring`).

When done, return control to the user.
