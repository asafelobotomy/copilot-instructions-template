---
name: performance-profiling
description: Profile a slow function, endpoint, or query — identify hot paths, N+1 queries, and memory pressure, then apply targeted optimizations with before/after measurements
compatibility: ">=0.7.0"
---

# Performance Profiling

> Skill metadata: version "1.0"; license MIT; tags [performance, profiling, optimization, benchmarks, queries]; compatibility ">=0.7.0"; recommended tools [codebase, runCommands, editFiles].

Systematically identify and fix performance bottlenecks. Measure first, then optimize — never guess.

## When to use

- User reports slowness: "this endpoint is slow", "the query takes too long", "memory usage is high"
- A function or test suite is noticeably slower than expected
- Pre-release performance review

## When not to use

- No reproducible baseline exists — establish one first
- The bottleneck is infrastructure (network, disk I/O in production) rather than code

## Steps

### 1. Establish a baseline measurement

Before any changes, measure the current state:

| Target | Tool |
|--------|------|
| Python function | `cProfile`, `py-spy`, `timeit` |
| Node.js | `--prof`, `clinic.js`, `0x` |
| Rust | `cargo bench` (criterion), `flamegraph` |
| Go | `go test -bench`, `pprof` |
| SQL queries | `EXPLAIN ANALYZE`, query plan tools |
| HTTP endpoints | `wrk`, `hey`, `hyperfine`, `k6` |
| Browser | DevTools Performance tab, Lighthouse |

Record: median latency, p95/p99, memory peak, CPU time. This is the target to beat.

### 2. Profile — find the hot path

Run the profiler and generate a flame graph or call tree.

```bash
# Python
python -m cProfile -o profile.out my_script.py
python -m pstats profile.out

# Node.js
node --prof app.js && node --prof-process isolate-*.log

# Go
go test -cpuprofile cpu.prof -bench . && go tool pprof cpu.prof
```

Look for:
- Functions consuming >10% of total time
- Unexpected call frequency (called 1000× when 10× expected)
- Memory allocations in tight loops

### 3. Classify the bottleneck

| Class | Symptom | Common fix |
|-------|---------|-----------|
| **Algorithmic** | O(n²) loop, nested linear scan | Better data structure, sort + binary search |
| **N+1 query** | DB query inside a loop | Eager load / batch fetch / join |
| **Serialization** | JSON encode/decode in hot path | Cache, lazy deserialize, binary format |
| **Allocation pressure** | GC pauses, repeated heap allocs | Pool, preallocate, stack-allocate |
| **I/O blocking** | Thread waiting on DB/HTTP | Async, connection pooling, caching |
| **Cache miss** | Repeated expensive computation | Memoize, LRU cache, CDN |
| **Lock contention** | Threads blocked on mutex | Reduce critical section, lock-free structure |

### 4. Apply the minimum targeted fix

Change only the identified hot path. Do not refactor surrounding code.

Common high-ROI patterns:

```python
# N+1 → batch
# Before
for user in users:
    user.orders = db.query(Order).filter_by(user_id=user.id).all()

# After
orders_by_user = {o.user_id: o for o in db.query(Order).filter(Order.user_id.in_(ids)).all()}
```

```sql
-- Add missing index
CREATE INDEX CONCURRENTLY idx_orders_user_id ON orders (user_id);
```

### 5. Re-measure

Run the same benchmark from step 1. Compare:

- Median latency before → after
- p95/p99 before → after
- Memory before → after

If improvement is less than 20%, the fix did not address the true bottleneck. Re-profile.

### 6. Run regression tests

Ensure correctness was preserved. Performance is worthless if the output changed.

### 7. Document

Record the bottleneck, fix, and measurement results as a comment or ADR entry. Prevents re-introducing the same issue.

## Verify

- [ ] Baseline measurement recorded before any changes
- [ ] Profiler output shows the hot path that was targeted
- [ ] Re-measurement shows meaningful improvement (>20% on the measured metric)
- [ ] Test suite passes after optimization
- [ ] No premature optimization — only the profiled hot path was changed
