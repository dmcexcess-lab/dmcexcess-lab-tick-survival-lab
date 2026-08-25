# Tick Survival Lab — System 30 Item Freshness / Spoilage

Status: **IMPLEMENTED + CI VERIFIED — Roadmap Phase 1B Candidate 001**

First fully green executable head: `39716f27b7f91b7007645ceae02dedc47601bf87`

Permanent exact-head context: `verify/system30-item-freshness`

Roadmap role: **Phase 1B — Item freshness / spoilage**.

Core rule:

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

---

## 1. Implemented result

System 30 adds persistent per-instance freshness for explicitly perishable physical items while preserving the project's event-driven performance doctrine.

Candidate 001 implements:

- explicit semantic freshness profiles;
- sparse typed freshness records keyed by stable `item.*` entity ID;
- deterministic bounded virgin-stock starting age;
- analytic freshness queries from authoritative WHEN ticks;
- cumulative storage-exposure contexts;
- ambient exposure as the only live storage context;
- FRESH / AGING / STALE / SPOILED derived labels;
- System-24 transactional virgin-loot enrollment and rollback;
- read-only inventory/container freshness labels;
- snapshot/restore of freshness state;
- a neutral reanchor seam for future real refrigeration.

It does **not** implement food consumption, nutrition, sickness, cooking, refrigeration, appliance power, generic item condition, or quantity/stack semantics.

---

## 2. Ownership

System 30 owns:

- which semantic item types are perishable;
- perishable profile lifetimes and profile versions;
- sparse per-instance freshness records;
- deterministic virgin initial age;
- current freshness derivation;
- storage-exposure context IDs/anchors;
- freshness record enrollment/removal/reanchor;
- freshness snapshot/restore;
- copied read descriptors for UI/consumers.

System 30 does not own:

- WHAT identity/placement;
- System 11 containment;
- System 09 hand assignment;
- System 12 transfer timing/disposition;
- System 13D weight;
- System 24 loot probability/current contents;
- System 25 time ownership;
- Weather or physical temperature;
- Phase-3 Power/Refrigeration;
- Phase-4 eating/drinking/health consequences;
- Phase-6 cooking;
- UI art/icon vocabulary.

Freshness remains a typed mechanic domain rather than WHAT metadata.

---

## 3. Candidate 001 profiles

Only semantic types with an `ItemFreshnessProfile` are perishable. No profile means shelf-stable for System 30 and therefore no persistent freshness record.

The implemented Candidate-001 set is:

- `item.food.apple`
- `item.food.bread_loaf`
- `item.food.milk_carton`
- `item.food.raw_chicken`
- `item.food.deli_meat`
- `item.food.fresh_salad`

Existing canned/shelf-stable items remain non-perishable unless a later explicit profile says otherwise.

Profile authoring uses `WorldTimeProfile` to convert human-scale shelf-life tuning into authoritative integer simulation ticks. Virgin stock may begin with deterministic age variation up to the profile's configured cap; Candidate 001 uses a maximum of 20%.

---

## 4. Readable states

Freshness state is derived from effective age relative to profile ambient lifetime:

- **FRESH:** `< 60%`
- **AGING:** `>= 60%` and `< 85%`
- **STALE:** `>= 85%` and `< 100%`
- **SPOILED:** `>= 100%`

The query also exposes integer age/remaining information for mechanics and DEV verification. Ordinary UI uses the coarse semantic label.

Crossing a threshold creates no timer event and performs no record mutation.

Freshness never improves automatically.

---

## 5. Cumulative exposure architecture

Candidate 001 has one live provider:

- context ID: `ambient`
- cumulative exposure at authoritative tick `T`: `T` ambient exposure ticks.

Per-item records store saved effective age plus an exposure-context anchor. Current age is calculated in O(1):

`current_age = saved_age + max(0, exposure_now - exposure_anchor)`

No elapsed-tick replay occurs.

The provider abstraction is deliberately neutral. Phase 3 may later supply a real refrigerated context whose cumulative exposure advances more slowly according to real power/appliance truth. A power-state change updates that context's clock rather than waking every contained item.

System 30 does not import Power.

---

## 6. Logical origin and streaming

Virgin world loot is logically present from scenario origin even when its technical source materializes later.

Therefore:

> **System-24 virgin perishables enroll with logical origin tick 0.**

A grocery first streamed on day 5 therefore does not generate day-5-new milk. Its stable item IDs are materialized at that time, but System 30 analytically catches their age up from scenario origin in one calculation.

Future gameplay-created food should use its real creation tick unless its owning creation mechanic explicitly supplies another causal origin policy.

---

## 7. System-24 transaction integration

`LootSourceInitializer` accepts an optional `ItemFreshnessMutationService` dependency.

For each created virgin loot item:

1. System 24 creates the real WHAT item exactly as before.
2. If the semantic type is perishable, System 30 enrolls it at logical origin tick 0.
3. System 11 containment is committed through the existing path.
4. System 24 commits its source provenance/current-content state.

System-24 source initialization snapshots WHAT, containment, loot state **and freshness state**. Any injected failure restores all four domains, so no orphan freshness record or half-created perishable survives rollback.

Production loot probability tables and search/TAKE/STORE timing are unchanged.

System 24's rule remains:

> **Loot exists before you search for it.**

---

## 8. Query contract

`ItemFreshnessQuery` returns one of:

- `KNOWN` — perishable, enrolled, profile/context valid;
- `SHELF_STABLE` — no freshness profile and intentionally no freshness record;
- `UNKNOWN` — missing item/required state/provider truth or query not ready;
- `INVALID` — malformed/non-item identity or contradictory state/profile data.

A known result includes copied values such as:

- item ID / semantic type;
- freshness stage;
- age ticks / profile lifetime ticks;
- age permille;
- exposure context ID;
- logical origin tick;
- record version.

Missing required perishable state never silently reads as FRESH.

`query(item_id)` reads the live authoritative TickKernel world tick. `query_at_tick(item_id, tick)` exists for deterministic headless verification and bounded simulation consumers that already possess an authoritative tick value.

---

## 9. Player-facing integration

The existing inventory and searchable-container inspection queries accept an optional freshness query.

Perishable rows receive a coarse suffix such as:

- `Apple — FRESH`
- `Bread Loaf — AGING`
- `Milk Carton — STALE`
- `Raw Chicken — SPOILED`

Shelf-stable items receive no freshness suffix.

UI remains read-only and performs no continuous freshness update. Opening/refreshing the relevant inspection surface simply asks for current truth.

Phase 1C may add semantic icons without changing freshness ownership.

---

## 10. Snapshot / mutation contract

`ItemFreshnessState` is sparse and versioned. Records are serialized deterministically by stable item ID.

`ItemFreshnessMutationService` owns:

- virgin enrollment;
- explicit record removal;
- environment reanchor;
- transaction-facing snapshot/restore helpers.

Time passing alone never calls the mutation service.

Reanchor preserves effective age and changes only the future exposure context/anchor. It cannot reduce age.

---

## 11. Performance contract

### Per render frame

**Zero System-30 simulation work.**

### Per WHEN advance

**Zero perishable-item iteration.**

### Per persistent item

No Node, timer, `_process`, `_physics_process`, scheduled spoilage event, or per-item time subscription.

Only explicitly perishable items consume freshness state.

### Query

Constant-time profile/state/provider lookup for the requested item. Inventory/container readers query only rows they are actually building.

### Streaming/materialization

Work scales with newly materialized perishables in the source, never with elapsed world time or total world-item count.

---

## 12. Verification

`game/scripts/ci/ItemFreshnessSmoke.gd` proves:

- six Candidate-001 perishables are registered;
- shelf-stable items receive no freshness record;
- deterministic virgin starting age is bounded;
- FRESH / AGING / STALE / SPOILED thresholds are exact;
- query/time passage performs zero freshness mutation;
- late technical materialization uses logical origin tick 0;
- freshness snapshot round-trip is deterministic;
- System 24 creates and enrolls a deterministic perishable transactionally;
- searchable-container inspection exposes freshness;
- actor-inventory inspection exposes freshness after transfer;
- injected containment failure restores WHAT, containment, loot and freshness exactly;
- no orphan freshness record survives rollback.

`.github/workflows/item-freshness.yml` additionally runs:

- Godot import/parse;
- System-30 smoke;
- System-24 loot regression;
- System-25 world-time regression;
- canonical live-demo startup;
- structural no-loop/no-cross-domain-import checks.

Executable `39716f27b7f91b7007645ceae02dedc47601bf87` completed all **16 required exact-head contexts** successfully, including `verify/system30-item-freshness` and `verify/pages-deploy`.

---

## 13. Protected future seams

Phase 3 may add real refrigeration only by providing real storage-environment exposure truth and invoking the existing reanchor seam at causal storage-context changes.

Phase 4 may query freshness when food/drink is consumed; System 30 still does not own nutrition, sickness or Health.

Phase 6 may add cooking/food transformation through real item creation/transition rules rather than mutating freshness labels directly.

No future system should introduce per-item spoilage timers merely for convenience.

---

## 14. Lifecycle

**DESCRIBE — COMPLETE**  
**APPROVE — COMPLETE**  
**IMPLEMENT — COMPLETE**  
**VERIFY — COMPLETE**

Roadmap Phase 1B is complete. The next bounded target is **Phase 1C — Semantic inventory/menu icons**, beginning at DESCRIBE; its implementation is not pre-authorized by completion of System 30.
