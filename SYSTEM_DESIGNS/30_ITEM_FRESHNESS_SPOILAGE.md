# Tick Survival Lab — System 30 Item Freshness / Spoilage

Status: **DRAFT — Roadmap Phase 1B DESCRIBE complete; awaiting user approval before implementation**

Roadmap role: **Phase 1B — Item freshness / spoilage**.

Core rule:

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

This system adds persistent, per-instance freshness to explicitly perishable physical items while preserving the project's performance doctrine: no per-item `_process`, no scheduled spoilage event per apple, no world scan when time advances, and no fake refrigeration before real power/appliance state exists.

---

## 1. Goal

Add the smallest causal model that preserves the important survival decisions:

- fresh food is more valuable than old food;
- food can become stale/spoiled while the player is elsewhere;
- stockpiling perishables has time pressure;
- later refrigeration can slow aging without replacing item identity or rewriting this system;
- a distant refrigerator first streamed on day 5 must not receive magically day-5-new food merely because the physical item entities were materialized late.

Phase 1B makes freshness **real and readable**. It does not yet implement eating/drinking consequences; Phase 4 owns hunger/thirst/health effects.

---

## 2. Ownership

System 30 owns:

- explicit perishable semantic-type profiles;
- typed persistent freshness records keyed by stable `item.*` entity ID;
- deterministic virgin-item initial age;
- analytical freshness queries from authoritative WHEN ticks;
- monotonic effective spoilage exposure;
- a neutral storage-environment exposure seam;
- the Candidate 001 ambient environment implementation;
- enrollment/removal/reanchor mutation for freshness state;
- snapshot/restore of freshness records;
- read-only freshness descriptors consumed by inventory/container inspection.

System 30 does **not** own:

- WHAT item identity or placement;
- System 11 containment;
- System 09 hand assignment;
- System 12 item transfer timing/disposition;
- System 24 loot planning/current container contents;
- System 25 clock/calendar presentation;
- power, appliance state or refrigeration — Roadmap Phase 3;
- physical temperature/weather heat transfer;
- eating/drinking, nutrition, sickness or poisoning — Roadmap Phase 4;
- cooking — Roadmap Phase 6;
- crafting creation rules — Roadmap Phase 2;
- UI layout/art/icons — Phase 1C / Phase 9;
- generic durability/condition for non-food items;
- item quantity/stack semantics.

Freshness is a typed mechanic store, not another WHAT metadata dictionary.

---

## 3. Existing contracts reused

System 30 composes existing truth rather than replacing it:

- **WHAT:** stable physical `item.*` identity;
- **WHEN:** one authoritative integer `world_tick`;
- **System 25 `WorldTimeProfile`:** scenario tick-rate conversion for human-readable shelf-life content authoring;
- **System 11:** current containment when a future storage-environment resolver needs it;
- **System 12:** future exact transfer-completion seam for environment reanchoring;
- **System 24:** virgin loot creation and deterministic stable item IDs;
- **System 13D:** item physical properties remain separate; freshness is not weight/condition metadata.

System 30 never creates a second clock.

---

## 4. Perishable profile catalog

Only semantic item types with an explicit `ItemFreshnessProfile` are perishable.

No profile means **shelf-stable / not modeled as perishable** for this system. System 30 therefore creates no pointless persistent state for canned beans, tools, batteries, bandages, nails, junk, etc.

Candidate profile facts:

- `semantic_type: StringName`;
- `ambient_lifetime_ticks: int` — positive lifetime at ordinary ambient exposure;
- `virgin_initial_age_max_permille: int` — bounded deterministic age variation for pre-existing world stock;
- `profile_version: int`.

Human-facing content may be authored in hours/days and converted once through the injected `WorldTimeProfile` into integer ticks. Runtime aging remains integer/fixed-point and deterministic.

No floating wall-clock age is stored.

---

## 5. Readable freshness states

Candidate 001 uses one simple normalized progression:

- **FRESH:** effective age `< 60%` of ambient lifetime;
- **AGING:** `60% <= age < 85%`;
- **STALE:** `85% <= age < 100%`;
- **SPOILED:** effective age `>= 100%`.

The query also exposes integer `age_permille` / `remaining_permille` for mechanics and DEV inspection, but ordinary player UI should primarily show the coarse semantic state.

These states are **derived**, not separately scheduled mutations.

Crossing FRESH -> AGING or STALE -> SPOILED emits no timer event and writes no record merely because time passed.

Freshness never improves automatically. A colder environment can slow or stop future aging, but cannot make old food young again.

---

## 6. Performance architecture — cumulative exposure clocks

This is the central 1B architecture.

Use fixed-point **spoilage exposure units**:

- `EXPOSURE_SCALE = 1000`;
- ambient exposure advances by `1000` units per authoritative world tick;
- a profile's ambient lifetime is `ambient_lifetime_ticks * EXPOSURE_SCALE`.

A storage environment exposes a **monotonic cumulative exposure clock**, not a per-item timer.

Neutral seam concept:

- `environment_key_for_item(item_id) -> StringName`;
- `cumulative_exposure_units(environment_key, world_tick) -> int`.

Candidate 001 has exactly one live environment:

- key: `ambient`;
- cumulative exposure at tick `T`: `T * 1000`.

### Why cumulative clocks matter

Later Phase-3 refrigeration can own one context clock per real refrigerated storage context. If power is on, that context clock may advance slowly; if power fails, it may advance faster. The refrigerator/context reanchors its **one clock** when its rate changes.

It does **not** wake every milk carton inside it.

A regional blackout therefore must not produce a perishable-item update storm.

System 30 does not decide the future cold-rate numbers. Phase 3 supplies real power/appliance truth through this seam.

---

## 7. Per-instance freshness record

Only perishable physical items receive a record.

Candidate record fields:

- `item_id: String`;
- `effective_age_units_at_anchor: int`;
- `environment_key: StringName`;
- `environment_exposure_units_at_anchor: int`;
- `logical_origin_tick: int`;
- `profile_version: int`;
- `record_revision: int`.

The record does **not** duplicate:

- item semantic type;
- item location;
- container ID;
- current freshness label;
- current remaining lifetime.

Those are read/derived from their real owners.

### Query equation

At current authoritative tick `T`:

`current_age = age_at_anchor + max(0, environment_exposure(environment_key, T) - environment_exposure_at_anchor)`

The semantic state is then derived from `current_age / profile_lifetime`.

No loop over elapsed ticks occurs.

---

## 8. Logical origin time — materialization must not create fresh food

Virgin world loot is logically part of the scenario before the player streams its building.

Therefore:

> **Pre-existing virgin perishable loot uses scenario origin tick 0, not the tick when its technical source happens to materialize.**

Example:

- player spends five simulation days near the starting town;
- a distant grocery is first materialized on day 5;
- System 24 deterministically creates its stable virgin item entities at that time for technical reasons;
- System 30 enrolls those perishables with logical origin tick `0`;
- their current freshness is immediately derived as five days of appropriate exposure, not zero days.

This preserves one persistent logical world across streaming boundaries without pre-simulating every item.

Newly created gameplay items later use their **real creation tick** unless their owning creation mechanic deliberately supplies another causal age policy.

---

## 9. Deterministic initial-age variation

Pre-existing store/household food should not all cross freshness boundaries on the same world tick.

Each profile may permit a bounded `virgin_initial_age_max_permille`.

For virgin world loot:

- stable item ID + semantic profile + fixed salt determine initial age deterministically;
- the value is in `[0, profile_max]`;
- Candidate 001 proposal: normally cap virgin initial age at **20%** of shelf life.

The same world seed/item ID always yields the same starting age.

Newly created/crafted food defaults to zero initial age unless its creator explicitly provides a different future rule.

Random wall-clock RNG is forbidden.

---

## 10. Enrollment / mutation contract

Proposed owner: `ItemFreshnessMutationService`.

### `enroll_item(item_id, logical_origin_tick, initial_environment_key)`

Requires:

- real WHAT `item.*` entity;
- an explicit freshness profile for its semantic type;
- non-negative origin tick;
- origin tick not later than current authoritative tick;
- known valid environment key/exposure at the origin tick;
- no existing freshness record.

Enrollment computes deterministic virgin initial age only when the caller requests virgin/pre-existing initialization. Dynamically created items use zero initial age by default.

### `remove_item(item_id)`

Explicit cleanup primitive for deleted/consumed/destroyed items. WHAT deletion does not silently cascade another mechanic store.

### `reanchor_environment(item_id, new_environment_key, at_tick)`

Preserves current effective age exactly, then starts future exposure against the new context clock.

It must be monotonic: reanchoring cannot reduce age.

Candidate 001's live environment is always `ambient`, so ordinary transfers do not need to perform pointless freshness writes today. The public reanchor seam exists so Phase 3 can activate real refrigeration without redesigning the record.

If a future environment resolver reports a current context different from the record's anchored context without a proper reanchor, freshness query should fail closed with an explicit environment-context mismatch rather than silently calculate false age.

---

## 11. Future containment/refrigeration integration

Phase 1B does **not** fake cold storage.

A refrigerator/cold-storage prop remains an ordinary ambient container until Roadmap Phase 3 supplies real appliance + power truth.

When refrigeration becomes real:

1. the refrigeration owner exposes a cumulative exposure context;
2. System 12 / a narrow post-transfer storage-context coordinator reanchors an item when it actually moves between ambient and cold context;
3. moving an item-container whose descendants inherit storage context may reanchor only that **moved local subtree**, never scan all world items;
4. power/rate changes update the refrigerator/context clock once; they do not mutate each contained item;
5. System 30 continues using the same freshness query equation.

No System-30 import of the Power system is permitted.

---

## 12. System 24 virgin-loot integration

System 24 remains owner of what virgin loot exists and of the stable item IDs it creates.

Phase 1B adds a narrow perishable-enrollment seam during successful virgin item creation:

- System 24 creates the real WHAT item as today;
- if its semantic type has a System-30 freshness profile, the item is enrolled using logical origin tick `0` and the current Candidate-001 ambient context;
- System 24's rollback transaction must include freshness enrollment so an injected initialization failure cannot leave orphan freshness state or a perishable item missing required freshness state;
- non-perishable items do nothing in System 30.

This changes no loot probability merely because freshness exists.

System 24's rule remains:

> **Loot exists before you search for it.**

Freshness simply makes the existing physical item age.

---

## 13. Candidate 001 perishable content

Phase 1B should expand food content only enough to prove short/medium/long aging. Broad mundane-content expansion remains Phase 1E.

Proposed first set:

| Item | Ambient lifetime | Virgin initial-age cap |
|---|---:|---:|
| Milk Carton | 12 h | 20% |
| Raw Meat Package | 12 h | 20% |
| Fresh Berries | 24 h | 20% |
| Bread Loaf | 72 h | 20% |
| Apple (existing) | 120 h | 20% |
| Cheese Block | 168 h | 20% |

These are gameplay tuning values, not claims of laboratory food-safety accuracy.

Expected location use:

- milk/raw meat/cheese: household, diner/store and grocery cold-storage loot profiles;
- berries/apple: household/grocery produce-appropriate profiles;
- bread: household pantry/grocery profiles.

Until Phase 3, a refrigerator is only the location where the item was found; it does not yet slow spoilage.

Existing canned beans/soup, crackers, cereal, energy bars and ordinary sealed drinks remain non-perishable in Candidate 001 unless a later explicit profile says otherwise.

No opened-package state is invented.

---

## 14. Read/query contract

Proposed `ItemFreshnessQuery` statuses:

- `KNOWN` — perishable + enrolled + context/profile valid;
- `NOT_PERISHABLE` — no freshness profile; intentional shelf-stable result;
- `UNKNOWN` — missing item, missing required record, profile-version mismatch, stale environment context, or unavailable exposure truth;
- `INVALID` — non-item identity / malformed request.

A KNOWN result exposes copied values such as:

- item ID / semantic type;
- semantic freshness state;
- `age_permille`;
- `remaining_permille`;
- effective age units;
- profile lifetime units;
- environment key;
- logical origin tick.

Missing perishable state is never silently treated as FRESH.

---

## 15. Player-facing Phase 1B presentation

Freshness is shown through the existing inventory/container inspection surfaces, not a new modal subsystem.

Candidate text:

- `Apple — FRESH`
- `Bread Loaf — AGING`
- `Milk Carton — STALE`
- `Raw Meat Package — SPOILED`

Only perishable items receive a freshness suffix.

Player UI does not need exact percentages. DEV/test inspection may expose `age_permille` and environment key.

The existing turn-based decision pause means an open inventory/container panel does not need a per-frame freshness updater. It queries when opened/refreshed after actions/time advancement.

Phase 1C may later add semantic icons without changing freshness truth.

---

## 16. Signals / derived-state rule

System 30 signals only real record mutations, such as:

- item enrolled;
- environment reanchored;
- item freshness record removed;
- snapshot reset.

It does **not** emit a signal merely because world time crossed a FRESH/AGING/STALE/SPOILED threshold.

Threshold labels are derived on query.

A future mechanic that needs to know food state at an action boundary queries current truth at that boundary.

---

## 17. Snapshot / restore

Candidate snapshot schema: **v1**.

Snapshot contains:

- global freshness revision;
- freshness records sorted by stable item ID.

It does not serialize:

- derived current state labels;
- current world tick;
- duplicate item semantic type/location/container;
- environment provider internals owned by future Power/Refrigeration systems.

Load validates shape, IDs, non-negative monotonic exposure values, known record/profile versions and duplicate IDs before live mutation.

Cross-domain WHAT validation may be deferred to save orchestration, following the existing typed-store pattern.

---

## 18. Performance contract

### Per render frame

**Zero System-30 simulation work.**

### Per WHEN tick/action globally

**Zero perishable-item iteration.** Time advancing does not wake System 30.

### Per persistent item

No Node, timer, `_process`, scheduled WHEN event or signal subscription per item.

Only explicitly perishable items consume a small typed record.

### Query

One requested item costs constant-time profile/state lookup plus the current environment exposure calculation. Inventory/container UI queries only items it is actually displaying.

### Streaming/materialization

Work scales with **new perishable items in the source being initialized**, not elapsed world time and not total world items.

A day-20 item catches up with one subtraction; it does not replay twenty days.

### Future refrigeration

Power/rate change cost belongs to the affected environment context, not every contained perishable item. Item moves may reanchor only the moved item/local contained subtree when a real non-ambient context exists.

No full-world freshness scan is allowed for ordinary play.

---

## 19. Verification plan

A dedicated System-30 smoke/contract should prove at minimum:

1. explicit perishable profile registration and copy safety;
2. no freshness record/state for shelf-stable items;
3. deterministic virgin initial-age variation from stable item ID;
4. exact FRESH / AGING / STALE / SPOILED boundaries;
5. monotonic age from authoritative `world_tick`;
6. decision/hard pause produces zero freshness advancement because WHEN does not advance;
7. a virgin item physically materialized on a later day still ages from logical origin tick 0;
8. query performs no per-tick catch-up loop;
9. snapshot round-trip is deterministic;
10. missing required perishable record fails closed rather than appearing fresh;
11. fake test environment clocks can slow exposure without modifying item records each tick;
12. changing one environment clock rate requires no per-item mutation;
13. explicit environment reanchor preserves age exactly and never rejuvenates food;
14. stale environment-context mismatch fails closed;
15. System-24 injected rollback restores WHAT + System 11 + System 24 + System 30 together for newly enrolled perishables;
16. inventory and searched-container inspection expose coarse freshness labels;
17. protected System 11/12/13D/24/25 behavior remains green;
18. structural CI rejects `_process`, per-item timers and per-item scheduled spoilage events in System 30.

Permanent exact-head context proposal after implementation:

`verify/system30-item-freshness`

That would increase the required executable-head set from 15 to 16 contexts.

---

## 20. Expected implementation modules after approval

Proposed cohesive module set:

- `game/scripts/simulation/items/freshness/ItemFreshnessProfile.gd`
- `.../ItemFreshnessProfileCatalog.gd`
- `.../ItemFreshnessRecord.gd`
- `.../ItemFreshnessState.gd`
- `.../SpoilageEnvironmentProvider.gd`
- `.../AmbientSpoilageEnvironmentProvider.gd`
- `.../ItemFreshnessQuery.gd`
- `.../ItemFreshnessMutationService.gd`
- focused System-24 creation/rollback integration;
- existing inventory/container read-query integration;
- `game/scripts/ci/ItemFreshnessSmoke.gd`;
- `.github/workflows/item-freshness.yml`.

Do not split every arithmetic helper into another public module.

---

## 21. Protected neighboring modules during implementation

Implementation must not rewrite:

- WHERE / WHAT / WHEN foundations;
- System 11 containment graph;
- System 12 transition semantics/timing;
- System 13D weight truth;
- System 24 loot existence/search semantics;
- System 25 world-time interpretation;
- System 28 Weather;
- System 29 interaction reach;
- streaming identity/materialization rules.

Narrow additive wiring/read-query changes are allowed where explicitly required by the approved System-30 contract.

---

## 22. Approval candidates

If this draft is approved, the following become the Candidate 001 implementation contract:

1. System 30 is a peer typed item-condition domain, not WHAT metadata and not part of System 24.
2. Only explicit semantic freshness profiles are perishable.
3. FRESH / AGING / STALE / SPOILED are derived at 60% / 85% / 100% of profile lifetime.
4. Runtime aging is integer fixed-point analytical exposure from authoritative WHEN ticks.
5. No per-item tick loop, timer, Node or scheduled spoilage event exists.
6. Storage environments expose cumulative exposure clocks.
7. Candidate 001 implements ambient exposure only; refrigerators do **not** fake cooling before real Phase-3 power/appliance state.
8. Virgin world perishables use logical scenario origin tick 0 even when technically materialized later.
9. Virgin stock receives deterministic bounded initial-age variation, normally up to 20% of shelf life.
10. Freshness is monotonic; colder storage may slow future aging but never reverse it.
11. Missing required perishable state/profile/context truth fails closed rather than reading as fresh.
12. System 24 enrolls new virgin perishable item entities transactionally without changing the rule that loot exists before search.
13. Ordinary UI shows coarse freshness labels only; no continuous UI updater exists.
14. Phase 4 later consumes freshness for eating/drinking health/need consequences rather than System 30 owning nutrition/health.
15. Phase 3 later supplies real refrigeration through the environment seam without System 30 importing Power.

---

## 23. Lifecycle

Current lifecycle state:

**DESCRIBE — COMPLETE**

Next step:

**APPROVE — user approval required before code.**

Implementation is not authorized by this draft alone.
