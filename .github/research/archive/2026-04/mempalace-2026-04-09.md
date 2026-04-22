# Research: MemPalace AI Memory System

> Date: 2026-04-09 | Agent: Researcher | Status: complete

## Summary

MemPalace is a local, open-source AI memory system published April 5, 2026 by developer Ben Sigman under an account named after actress Milla Jovovich. It reached 5,400+ GitHub stars in less than 24 hours due to celebrity attribution and aggressive headline claims. The core idea is genuine: apply the ancient method of loci mnemonic to AI memory by organising everything into wings (people/projects), rooms (topics), and drawers (verbatim storage). The 96.6% LongMemEval headline is technically real but misleading — it measures standard ChromaDB nearest-neighbour recall on labels, not an end-to-end QA score. The AAAK compression dialect is lossy, not lossless. Contradiction detection does not exist in the code. Authors acknowledged all of this in a public note on April 7, 2026 and committed to fixes. The genuinely useful pieces (one-command ingest pipeline, local temporal KG, low wake-up cost, MIT licence) survive the scrutiny.

---

## Sources

| URL | Relevance |
|-----|-----------|
| https://github.com/milla-jovovich/mempalace | Primary project repository and README |
| https://raw.githubusercontent.com/milla-jovovich/mempalace/main/mempalace/mcp_server.py | MCP server full source |
| https://raw.githubusercontent.com/milla-jovovich/mempalace/main/mempalace/knowledge_graph.py | Knowledge graph full source |
| https://raw.githubusercontent.com/milla-jovovich/mempalace/main/mempalace/layers.py | L0-L3 memory stack source |
| https://raw.githubusercontent.com/milla-jovovich/mempalace/main/hooks/mempal_save_hook.sh | Save hook source |
| https://raw.githubusercontent.com/milla-jovovich/mempalace/main/hooks/mempal_precompact_hook.sh | PreCompact hook source |
| https://github.com/milla-jovovich/mempalace/issues/27 | lhl's comprehensive claims-vs-code analysis |
| https://github.com/milla-jovovich/mempalace/issues/39 | Independent benchmark reproduction (gizmax) |
| https://github.com/milla-jovovich/mempalace/issues/74 | macOS ARM64 segfault report |
| https://github.com/milla-jovovich/mempalace/issues/100 | Unpinned ChromaDB dependency |
| https://github.com/milla-jovovich/mempalace/issues/110 | Shell injection in hook scripts |
| https://news.ycombinator.com/item?id=47672792 | Main HN thread (59 points, 12 comments) |
| https://news.ycombinator.com/item?id=47669671 | Earlier HN submission (21 points) |
| https://penfieldlabs.substack.com/p/milla-jovovich-just-released-an-ai | Penfield Labs deep methodology analysis |
| https://github.com/lhl/agentic-memory/blob/main/ANALYSIS-mempalace.md | lhl's agentic-memory survey analysis (NOT PROMOTED) |
| https://decrypt.co/363524/fifth-element-milla-jovovich-ai-tool-mempalace | Decrypt coverage of celebrity angle |
| https://www.mempalace.tech/story | Authors' full story |

---

## Findings

### 1. Project Context and Launch

MemPalace (v3.0.0) was created April 5, 2026 with 7 initial commits across 21 Python files plus 2 runtime dependencies (`chromadb`, `pyyaml`). Ben Sigman published the launch on X/Twitter, crediting actress Milla Jovovich as co-author. The account hosting the code is `github.com/milla-jovovich`. The launch tweet exceeded 1.5 million views and the repository accumulated 5,400+ stars in under 24 hours — a trajectory Penfield Labs (who track memory system benchmarks professionally) describe as "orders-of-magnitude different" from typical comparable projects, driven entirely by the celebrity attribution.

Within 48 hours, community review had identified serious claims gaps. The authors published a correction notice directly in the README on April 7, 2026 acknowledging every major criticism.

**Authors' own correction (April 7, 2026), verbatim:**
> "AAAK is a lossy abbreviation system (entity codes, sentence truncation). Independent benchmarks show AAAK mode scores 84.2% R@5 vs raw mode's 96.6% on LongMemEval — a 12.4 point regression. The honest framing is: AAAK is an experimental compression layer that trades fidelity for token density, and the 96.6% headline number is from RAW mode, not AAAK."

---

### 2. Palace Architecture Pattern

The spatial metaphor applies the classical Method of Loci to AI memory storage:

```
Wing (person or project)
  └── Room (named topic: "auth-migration", "ci-pipeline")
        ├── Hall (memory category: hall_facts, hall_events, hall_discoveries,
        │         hall_preferences, hall_advice)
        ├── Closet (summary pointing to verbatim content)
        └── Drawer (verbatim original file, never summarised)

Tunnel = same room name appearing in 2+ wings (cross-domain link)
Hall   = same hall type across all rooms in a wing (memory category corridor)
```

**What's implemented vs. what the README describes:**

| Concept | README description | Implementation reality |
|---------|-------------------|----------------------|
| Wings | Top-level grouping for people/projects | ChromaDB metadata field `wing` |
| Rooms | Named topics within a wing | ChromaDB metadata field `room` |
| Halls | Memory type corridors | ChromaDB metadata field `hall` (string label only, not structurally enforced in retrieval) |
| Closets | Compressed summaries pointing to drawers | In v3.0.0: plain-text summaries; AAAK-encoded closets described as "coming soon" |
| Drawers | Original verbatim files | ChromaDB documents in single collection `mempalace_drawers` |
| Tunnels | Cross-wing connections | Computed on-demand: rooms with same name appearing in 2+ wings |
| Palace graph | Navigable spatial structure | Recomputed each query by scanning ChromaDB metadata in 1000-item batches |

**Critical architectural note from lhl's analysis:**
> "The 'palace graph' (rooms, halls, tunnels) is NOT stored as a graph. It is computed on-demand by scanning ChromaDB metadata in 1000-item batches and building set intersections. Two rooms are connected if they share a wing (BFS traversal). A tunnel exists when the same room name appears in 2+ wings. Halls are just metadata labels, not structural entities."

The entire palace lives in **one ChromaDB collection** — no separate collection per wing, room, or type. Diary entries, mined project files, and conversation memories share the same vector space, distinguished only by metadata.

---

### 3. Memory Stack (L0–L3)

The 4-layer memory stack is one of MemPalace's genuine strengths:

| Layer | Content | Token budget | Trigger |
|-------|---------|-------------|---------|
| L0 | `~/.mempalace/identity.txt` (plain text written by user) | ~50–100 tokens | Always loaded |
| L1 | Top-15 drawers by `importance` score, grouped by room, 3200-char cap | ~500–800 tokens | Always loaded |
| L2 | Wing/room-scoped ChromaDB retrieval | ~200–500 tokens | On topic trigger |
| L3 | Full ChromaDB semantic search | Unbounded | Explicit query |

**L0 implementation:** Reads a plain text file from `~/.mempalace/identity.txt`. Cached in-instance after first read. Falls back to a placeholder if the file doesn't exist. Token estimate: `len(text) // 4`.

**L1 implementation:** Fetches all drawers from ChromaDB in 500-item batches (to avoid SQLite variable limit). Scores each drawer using the `importance`, `emotional_weight`, or `weight` metadata field (tries each in order, defaults to 3.0). Sorts by importance descending, takes top 15, groups by room, truncates each doc snippet at 200 chars, enforces a 3200-char overall cap.

**L2 implementation:** Constructs a ChromaDB `where` filter from wing/room args (uses `$and` for both). Returns up to `n_results` drawers. Pure metadata filtering — no semantic query.

**L3 implementation:** Delegates to `searcher.search_memories()` which runs `col.query(query_texts=[query], n_results=n_results, where=filter)`. Standard cosine-distance vector search.

**Wake-up cost discrepancy:** The README states "~170 tokens". The `cli.py` help string says "~600-900 tokens". Independent testing on a real palace (gizmax, issue #39) returned ~810 tokens, matching the cli.py estimate. The 170-token figure appears outdated or based on a minimal example palace.

---

### 4. MCP Server — 19 Tools

The MCP server uses a simple JSON-over-stdio protocol. 19 tools declared in a `TOOLS` dict with description, `input_schema`, and `handler` function reference.

**Tool inventory:**

| Category | Tool | Handler | Description |
|----------|------|---------|-------------|
| Palace (read) | `mempalace_status` | `tool_status()` | Total drawers, wing/room counts, PALACE_PROTOCOL, AAAK_SPEC embedded |
| Palace (read) | `mempalace_list_wings` | `tool_list_wings()` | All wings with drawer counts |
| Palace (read) | `mempalace_list_rooms` | `tool_list_rooms(wing)` | Rooms within a wing (or all) |
| Palace (read) | `mempalace_get_taxonomy` | `tool_get_taxonomy()` | Full wing → room → count tree |
| Palace (read) | `mempalace_search` | `tool_search(query, limit, wing, room)` | Semantic search with optional filters |
| Palace (read) | `mempalace_check_duplicate` | `tool_check_duplicate(content, threshold)` | Pre-insert similarity check (threshold 0.9) |
| Palace (read) | `mempalace_get_aaak_spec` | `tool_get_aaak_spec()` | Return AAAK dialect spec |
| Palace (write) | `mempalace_add_drawer` | `tool_add_drawer(wing, room, content, source_file, added_by)` | File verbatim content; idempotent via deterministic MD5 ID |
| Palace (write) | `mempalace_delete_drawer` | `tool_delete_drawer(drawer_id)` | Remove by ID |
| Knowledge Graph | `mempalace_kg_query` | `tool_kg_query(entity, as_of, direction)` | Entity relationships with time filtering |
| Knowledge Graph | `mempalace_kg_add` | `tool_kg_add(subject, predicate, object, valid_from, source_closet)` | Add relationship triple |
| Knowledge Graph | `mempalace_kg_invalidate` | `tool_kg_invalidate(subject, predicate, object, ended)` | Mark fact as ended |
| Knowledge Graph | `mempalace_kg_timeline` | `tool_kg_timeline(entity)` | Chronological entity story |
| Knowledge Graph | `mempalace_kg_stats` | `tool_kg_stats()` | Graph overview |
| Navigation | `mempalace_traverse` | `tool_traverse_graph(start_room, max_hops)` | Walk graph from a room |
| Navigation | `mempalace_find_tunnels` | `tool_find_tunnels(wing_a, wing_b)` | Find rooms bridging two wings |
| Navigation | `mempalace_graph_stats` | `tool_graph_stats()` | Graph connectivity overview |
| Agent Diary | `mempalace_diary_write` | `tool_diary_write(agent_name, entry, topic)` | Write timestamped diary entry |
| Agent Diary | `mempalace_diary_read` | `tool_diary_read(agent_name, last_n)` | Read recent diary entries |

**Key implementation patterns:**

1. **Bootstrap self-teaching via `mempalace_status`:** When the AI calls `mempalace_status` on wake-up, the response embeds the full `PALACE_PROTOCOL` (5 memory rules) and `AAAK_SPEC` (the dialect reference). The AI learns its memory protocol and the AAAK format in a single tool call with no manual configuration.

2. **Idempotent drawer insertion:** `tool_add_drawer` generates a deterministic ID as `drawer_{wing}_{room}_{md5(content)[:16]}`. It checks if this ID already exists before inserting, returning `reason: "already_exists"` as a no-op. This prevents duplicates across sessions.

3. **Global ChromaDB client cache:** `_client_cache` and `_collection_cache` are module-level globals, avoiding reconnection overhead per tool call.

4. **Graceful palace-not-found handling:** All tools return `{"error": "No palace found", "hint": "Run: mempalace init <dir> && mempalace mine <dir>"}` via `_no_palace()` if ChromaDB collection is unavailable.

5. **Diary as standard drawers with hall metadata:** Diary entries use `hall: "hall_diary"`, `type: "diary_entry"`, `room: "diary"` metadata fields in the shared `mempalace_drawers` collection. The diary wing is `wing_{agent_name}`. No separate storage layer.

**PALACE_PROTOCOL (embedded verbatim in status responses):**
> "1. ON WAKE-UP: Call mempalace_status to load palace overview + AAAK spec.
> 2. BEFORE RESPONDING about any person, project, or past event: call mempalace_kg_query or mempalace_search FIRST. Never guess — verify.
> 3. IF UNSURE about a fact: say 'let me check' and query the palace. Wrong is worse than slow.
> 4. AFTER EACH SESSION: call mempalace_diary_write to record what happened.
> 5. WHEN FACTS CHANGE: call mempalace_kg_invalidate on the old fact, mempalace_kg_add for the new one."

---

### 5. Knowledge Graph Implementation

SQLite-backed temporal entity-relationship graph. Two tables:

```sql
CREATE TABLE entities (
    id TEXT PRIMARY KEY,    -- slugified name: "max_obrien"
    name TEXT NOT NULL,     -- display name: "Max O'Brien"
    type TEXT DEFAULT 'unknown',
    properties TEXT DEFAULT '{}',
    created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE triples (
    id TEXT PRIMARY KEY,
    subject TEXT NOT NULL,  -- entity slug (FK to entities.id)
    predicate TEXT NOT NULL, -- lowercased, underscored: "works_on"
    object TEXT NOT NULL,   -- entity slug (FK to entities.id)
    valid_from TEXT,        -- ISO date string
    valid_to TEXT,          -- ISO date string; NULL = still true
    confidence REAL DEFAULT 1.0,
    source_closet TEXT,
    source_file TEXT,
    extracted_at TEXT DEFAULT CURRENT_TIMESTAMP
);
-- Indexes on subject, object, predicate, valid_from+valid_to
```

**Temporal validity query pattern:**
```sql
AND (t.valid_from IS NULL OR t.valid_from <= ?)
AND (t.valid_to IS NULL OR t.valid_to >= ?)
```
String comparison on ISO dates — simple and correct for YYYY-MM-DD format.

**Idempotency:** `add_triple()` checks for an existing triple with the same (subject, predicate, object) where `valid_to IS NULL` before inserting. Auto-creates subject and object entities via `INSERT OR IGNORE`.

**WAL mode:** `conn.execute("PRAGMA journal_mode=WAL")` on every connection — better concurrency for read-heavy workloads.

**What it does NOT have (vs. Zep/Graphiti):**
- No BFS retrieval or graph traversal for related entities
- No community detection
- No episodic vs. semantic split
- No LLM-based entity resolution — entity IDs are purely slug-based (`alice.lower().replace(" ", "_")`) so "Alice O'Brien" and "alice obrien" produce different IDs
- No contradiction detection (the README claim that does not exist in code)

---

### 6. AAAK Dialect

AAAK is a deterministic abbreviation scheme, not a compression codec. The pipeline:

1. **Entity detection:** known name→code mappings from `entity_registry.py` (e.g., `ALC=Alice, JOR=Jordan`), or auto-generate from first-3-chars of capitalised words
2. **Topic extraction:** word frequency + proper noun boosting, take top-3
3. **Key sentence selection:** decision-keyword scoring from a predefined list, truncated at **55 characters**
4. **Emotion detection:** keyword → abbreviated emotion code (`*warm*`, `*fierce*`, etc.)
5. **Structure:** pipe-separated fields with prefixes (`FAM:`, `PROJ:`, `⚠:`)

**Token count issue (authors' own correction):**
The original token counting used `len(text) // 3` — a rough heuristic. Real counts via an actual tokenizer show the English→AAAK example in the README uses MORE tokens in AAAK form (73 tokens) than in plain English (66 tokens) at small scale. AAAK overhead (codes, separators) costs more than it saves on short text.

**Benchmark impact:**
| Mode | LongMemEval R@5 | Delta |
|------|----------------|-------|
| Raw (ChromaDB verbatim) | 96.6% | baseline |
| Rooms mode | 89.4% | -7.2pp |
| AAAK mode | 84.2% | -12.4pp |

AAAK currently regresses quality at every measured scale. The authors' stated rationale is that AAAK should demonstrate compression benefit "in scenarios with many repeated entities at scale" — but this has not been demonstrated with real tokenizer measurements.

---

### 7. Hook Implementations

**Save Hook (`mempal_save_hook.sh`) — Claude Code "Stop" hook:**

Protocol: JSON on stdin → JSON on stdout. Input fields: `session_id`, `stop_hook_active`, `transcript_path`.

Logic:
1. If `stop_hook_active = true` → `echo "{}"` (let AI stop; prevents infinite loop)
2. Count user messages in JSONL transcript (excludes `<command-message>` system entries)
3. Compare against last-save checkpoint stored in `~/.mempalace/hook_state/{SESSION_ID}_last_save`
4. If messages since last save ≥ SAVE_INTERVAL (15): update checkpoint, optionally background-run `mempalace mine $MEMPAL_DIR`, emit block JSON
5. Otherwise: `echo "{}"` (let AI stop)

Block response:
```json
{
  "decision": "block",
  "reason": "AUTO-SAVE checkpoint. Save key topics, decisions, quotes, and code from this session to your memory system. Organize into appropriate categories. Use verbatim quotes where possible. Continue conversation after saving."
}
```

**PreCompact Hook (`mempal_precompact_hook.sh`) — Claude Code "PreCompact" hook:**

Always blocks. Optionally runs `mempalace mine $MEMPAL_DIR` **synchronously** before emitting the block response (ensuring memories persist before context window shrinks).

Block response reason: "COMPACTION IMMINENT. Save ALL topics, decisions, quotes, code, and important context from this session to your memory system. Be thorough — after compaction, detailed context will be lost."

**Security note (Issue #110):** The current code in the repository sanitises `SESSION_ID` via `tr -cd 'a-zA-Z0-9_-'` and passes `TRANSCRIPT_PATH` as an argument to the Python heredoc (`python3 - "$TRANSCRIPT_PATH" <<'PYEOF'`). This appears to address the original shell injection concern. `MEMPAL_DIR` is a static config variable, not user input.

---

### 8. Notable GitHub Issues

**Issue #27 — Claims vs. code analysis (lhl, April 7, 2026)**

Developer Leonard Lin (`@lhl`) filed a detailed table comparing README claims to code reality within hours of launch. Full analysis linked from issue: `https://github.com/lhl/agentic-memory/blob/main/ANALYSIS-mempalace.md`

Summary of findings:
- "Contradiction detection" → does not exist in code; only blocks identical open triples
- "30x lossless compression" → lossy abbreviation; 12.4pp benchmark regression
- "96.6% LongMemEval headline" → ChromaDB default embeddings on verbatim text; palace structure uninvolved
- "+34% palace boost" → standard metadata filtering, not novel
- "100% Haiku rerank" → not in public benchmark scripts
- "Closets as compressed summaries" → nomenclature mismatch; AAAK produces abbreviations not summaries
- "Hall types structurally enforced" → metadata strings only, not used in retrieval ranking

**Issue #39 — Independent benchmark reproduction (gizmax, April 7, 2026)**

Mac Studio M2 Ultra independent replication of all three benchmark modes. Key quotes:

> "The raw 96.6% reproduces exactly on independent hardware, in under 5 minutes, with zero modifications. That's a clean, reproducible result and credit where it's due."

> "The --mode raw runner builds a fresh chromadb.EphemeralClient() per question and never touches the palace, wings, or rooms code paths (longmemeval_bench.py:97, 209). So the headline 96.6% is effectively a benchmark of all-MiniLM-L6-v2 embeddings on this dataset rather than of the palace architecture itself."

> "To be clear about what this all means for our own use case: we still think there's a real product here, just not the one the README is selling. The combination of a one-command ChromaDB ingest pipeline for Claude Code, ChatGPT, and Slack exports, a working semantic search index over months or years of conversation history, fully local, MIT-licensed, no API key required, and a standalone temporal knowledge graph module (knowledge_graph.py) that could be used independently of the rest of the palace machinery, is genuinely useful."

**Issue #74 — macOS ARM64 segfault after ~8,400 drawers**

Null pointer dereference in `chromadb_rust_bindings.abi3.so` after mining two wings totalling ~8,400 drawers. Crash entirely within ChromaDB's Rust bindings. Suggests a size/scaling threshold in the ChromaDB vector store. Workaround: wipe palace and re-mine with smaller batches.

**Issue #100 — Unpinned ChromaDB dependency**

`mempalace 3.0.0` does not pin ChromaDB version. `pip install mempalace` can pull `chromadb 1.5.6` which causes segfaults on macOS ARM. Downgrading to `chromadb<1` (tested: 0.6.3) fixes the problem. Authors committed to pinning in their April 7 correction note.

**Issue #110 — Shell injection in hook scripts**

Original hooks interpolated JSON-derived values directly into shell strings. Fix: pass values as arguments to Python heredocs or subprocesses. Current code in the repo appears to implement the fix (SESSION_ID sanitised via `tr`, TRANSCRIPT_PATH passed as argument).

---

### 9. Community Reception

**Hacker News threads:**

| Thread | Points | Comments | Framing |
|--------|--------|----------|---------|
| "MemPalace, the highest-scoring AI memory system ever benchmarked" (rochoa) | 59 | 12 | Mixed; practical uses highlighted |
| "The highest-scoring AI memory system ever benchmarked" (latchkey) | 21 | 3 | Early submission before full scrutiny |
| "Milla Jovovich Built MemPalace – The Full Story" (ianrahman) | 7 | 6 | Celebrity angle |
| "Milla Jovovich's MemPalace Claims 100% on LoCoMo. Its Benchmarks.md Disagrees" (dial481) | 4 | 0 | Benchmarks criticism |
| "MemPalace – A Scam" (doppp) | 2 | 1 | Strongest negative framing |
| "MemPalace review: strong ChromaDB baseline, weak moat" (averrouz) | 1 | 0 | Balanced technical framing |

**Notable HN comment (rochoa thread):**
> "I think the benchmarker who ran independent tests in GitHub issue #39 summed it up best: 'we still think there's a real product here, just not the one the README is selling.'"

**Penfield Labs analysis (Substack, April 7, 2026):**

The most detailed community analysis. Key points:
- LoCoMo "100%" achieved via top-k=50 against a 19–32-session max candidate pool — retrieves every session, reducing to `cat *.txt | claude`
- LongMemEval "96.6%" is `recall_any@5` on label-set membership, not end-to-end QA accuracy (never generates answers, never invokes a judge)
- "100% Haiku hybrid" built by inspecting 3 wrong answers on dev set and patching specifically for them — BENCHMARKS.md calls this "teaching to the test" verbatim
- The project's own BENCHMARKS.md (5,000+ words) contradicts the launch post point-by-point
- Historical context: Zep vs Mem0 benchmark wars (Zep's "Lies, Damn Lies, and Statistics" post; Mem0 counter-response claiming Zep's real score is 58.44%; Letta's filesystem baseline paper)

**lhl's agentic-memory survey analysis:**

Status: NOT PROMOTED to the main comparison list due to "multiple outright false claims." Described as the only system in the survey with claims that "provably don't exist in their own code."

Genuine positives identified:
- Spatial metaphor is novel in the survey (no other system uses method of loci)
- Extremely low wake-up cost (~600-900 tokens, leaving >95% context free) — better than Claude Code MEMORY.md approach, OpenViking recursive L0 loads, ByteRover tiered context tree
- Zero-LLM write path (purely deterministic extraction — offline, no API cost)
- Agent diary system (per-agent wing + timestamped entries)
- Cross-wing tunnel concept (same room name = automatic cross-domain link)

---

### 10. Comparisons with Other Memory Systems

| Feature | MemPalace | Zep/Graphiti | Mem0 | Letta | Supermemory |
|---------|-----------|-------------|------|-------|-------------|
| Storage | ChromaDB + SQLite (local) | Neo4j (cloud) | Cloud | Cloud/Local | Cloud |
| Cost | Free | $25/mo+ | $19–249/mo | $20–200/mo | — |
| LongMemEval R@5 | 96.6% (raw, retrieval only) | ~85% (end-to-end QA) | ~85% (end-to-end QA) | — | ~99% (ASMR, cloud) |
| Temporal KG | Yes (SQLite) | Yes (Neo4j) | Yes | Yes | No |
| Privacy | Fully local | SOC 2, HIPAA | Cloud | Mixed | Cloud |
| LLM on write path | No | Yes | Yes | Yes | Yes |
| Wake-up cost | ~600-900 tokens | N/A | N/A | N/A | N/A |
| Contradiction detection | Not yet (claimed but not coded) | Yes | Yes | Yes | Unknown |

**Important benchmark comparability caveat (gizmax, issue #39):**
> "Most other memory systems (Mem0, Zep, Mastra, Supermemory, Hindsight, Letta) report end-to-end QA accuracy with an LLM judge rather than pure retrieval R@5, so apples-to-apples comparison with them isn't possible from this benchmark alone."

---

### 11. Genuine Strengths (Surviving Scrutiny)

1. **One-command ingest pipeline** — `mempalace mine <dir>` and `mempalace mine <dir> --mode convos` for Claude Code `.jsonl`, ChatGPT, Slack exports. No API key required.

2. **Local, offline, MIT-licensed** — everything on your machine. ChromaDB on your machine. Zero data egress.

3. **Temporal knowledge graph (SQLite)** — `knowledge_graph.py` can be used as a standalone module. Temporal validity, entity relationships, point-in-time queries. Free alternative to Zep's Graphiti (which requires Neo4j at $25/mo+).

4. **Low wake-up cost** — L0+L1 (~600-900 tokens in practice) is better than most alternatives. Leaves >95% context free.

5. **Deterministic write path** — No LLM required at any stage of ingestion. Fully offline, reproducible, no API costs on write.

6. **Agent diary system** — per-agent persistent memory in the shared ChromaDB collection. A free alternative to Letta's agent-managed memory ($20-200/mo).

7. **Self-teaching status response** — `mempalace_status` embeds PALACE_PROTOCOL and AAAK_SPEC so the AI learns its memory protocol and dialect on the first tool call without any manual configuration.

8. **Idempotent drawer insertion** — MD5-based deterministic IDs mean re-running ingest is safe.

---

## Recommendations

For use in this repository's hook and MCP system context:

1. **Use `knowledge_graph.py` as a standalone module** — it is well-implemented, MIT-licensed, and provides temporal entity-relationship tracking without the benchmarking controversy.

2. **Use raw mode only** — if evaluating MemPalace for conversation history search, use raw mode. AAAK and rooms mode both degrade retrieval quality meaningfully.

3. **Pin `chromadb<1`** — until the authors pin their dependency, use `chromadb>=0.6,<1` to avoid the M-series ARM64 segfault.

4. **The hook architecture is worth adopting** — the Stop/PreCompact hook pattern (count exchanges → periodic block → AI saves → pass through) is a clean design applicable to our own memory hooks.

5. **Disregard the LongMemEval headline benchmark** — the 96.6% measures `recall_any@5` on ChromaDB's default `all-MiniLM-L6-v2` embeddings. It is not a MemPalace result; it is a ChromaDB baseline result. The same score would be obtained by any system using the same embedding model on raw verbatim text.

6. **The palace metaphor has MCP relevance** — the `mempalace_status` bootstrap pattern (embedding protocol and dialect spec in the first tool call response) is an elegant design for MCP tools that need to teach the AI their conventions without a separate onboarding step.

---

## Gaps / Further Research Needed

- **AAAK at scale** — no published evidence yet of token savings with large entity vocabularies (hundreds of entities across thousands of documents). Claimed benefit undemonstrated.
- **`fact_checker.py`** — not publicly analysed; the authors say contradiction detection is "being wired in" but the timeline is unclear.
- **Haiku rerank pipeline** — not in public repo; "100% with Haiku rerank" is unverifiable from public code.
- **LoCoMo honest run** — no published result from MemPalace at top-k matching actual session counts.
- **ChromaDB 1.x compatibility** — unclear if/when authors will test and support the 1.x branch.
- **Entity resolution** — slug-based IDs will fail for name variants; no evidence of a resolution step.
