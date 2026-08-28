# Tick Survival Lab — System 32 Crafting / Material Transformation

Status: **DRAFT — awaiting approval**

Described: **2026-08-27**

Roadmap owner: **Phase 2 — Crafting**

## 1. Goal

Make the physical items collected during Phase 1 materially transformable without creating a menu-only resource economy or stealing ownership from inventory, world state, time, skills, construction, utilities, combat, health, or vehicles.

Core rule:

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

A recipe never consumes an icon, a UI stack, an abstract material counter, a hidden crafting wallet, or a search-time reward roll.

Candidate 001 establishes the reusable crafting substrate and a small honest material-reclamation / assembly recipe set. Later construction, repair, traps, utilities, vehicles, cooking, and other domains may consume this substrate where appropriate, but they do not become Crafting-owned merely because they involve tools or materials.

---

## 2. Why this is one System 32

Crafting has one cohesive reason to change: the rules for transforming possessed physical items through recipes over simulation time.

Candidate 001 therefore uses one System 32 owner with internal modules for:

- recipe definitions/catalog;
- explicit workstation capability classification;
- deterministic requirement/ingredient planning;
- read-only craftability queries;
- WHEN-backed craft actions and bounded commit/compensation;
- System-29 interaction offers for real workstations;
- player-facing crafting presentation.

These are not independent peer systems. Splitting each into 32A/32B/etc. would fragment one mechanic without buying meaningful replaceability.

System 32 does **not** absorb:

- System 11 containment;
- System 12 ordinary item transfer;
- System 13D physical weight;
- System 13E carry limits;
- System 24 virgin loot/search;
- System 29 neutral reach/highlight composition;
- System 30 freshness;
- System 31 icons;
- future Skills, Construction, Repair/Durability, Power/Water, Health/Nutrition, Vehicles, Combat, or AI.

---

## 3. Existing truths consumed

### WHAT

WHAT owns stable item/workstation entity identity and physical placement. Crafting creates/removes item entities only through `WorldMutationService` and never persists a parallel crafted-item record.

### System 09 — Hands

Hands remain the sole truth for items currently held. A consumed ingredient may be in a hand; System 32 coordinates the existing hand mutation service at final commit rather than inventing a crafting-held disposition.

### System 11 — Containment

System 11 remains the sole truth for personally contained ingredients/tools and the destination of ordinary crafted outputs.

Candidate 001 output destination is the crafting actor's enrolled root container. No hidden crafting-output buffer exists.

### System 12 — Item Transfer

System 12 remains the owner of ordinary pickup/drop/equip/container-to-container actions.

Crafting is not expressible as one ordinary transfer because one timed transformation can consume several items and create several new items. System 32 therefore coordinates its own bounded multi-item commit while preserving the same cross-domain discipline used by System 12: validate, spend WHEN time, revalidate, mutate through public owners, compensate bounded failures.

System 32 does not add a generic multi-item transaction service merely for architectural neatness.

### System 13D / 13E

Every craft input/tool/output semantic must have known positive physical weight under System 13D.

System 13E remains the carry owner. Crafting checks projected carried mass before scheduling and again at commit:

`projected = current carried mass - consumed input mass + output mass`

The craft is rejected when projected mass would exceed the actor's current hard possession ceiling. Missing carry/weight truth fails closed.

### System 24

System 24 remains virgin loot/search owner. Crafting may use item semantics originally introduced by the Phase-1 item catalog and may add crafted item semantics to the existing shared content vocabulary without making them spawn as virgin loot.

A crafted semantic does not enter a System-24 loot profile unless a separate content decision intentionally makes that object discoverable as virgin world loot.

### System 29

System 29 continues to own neutral `CONTACT_FORWARD` reach and player-facing offer/highlight composition.

System 32 may publish `crafting.use_workstation` / `CRAFT` for real explicitly classified workstations. System 29 never infers crafting from art or a semantic name, and the System-32 action still revalidates workstation truth itself.

### System 30

Candidate 001 deliberately excludes perishable ingredients and perishable outputs. This prevents Crafting from silently deleting/recreating freshness history before a recipe/freshness transfer policy is designed.

Cooking and food transformation remain later work. System 30 still owns freshness.

### System 31

Every shipped crafted output semantic receives an intentional System-31 icon mapping. Icons remain presentation only and never define recipe eligibility.

### WHEN

Every accepted craft is a positive-duration actor action using the existing TickKernel. Hard application pause advances zero crafting ticks.

---

## 4. Candidate 001 recipe model

`CraftingRecipe` is immutable-style configuration containing at minimum:

- `recipe_id: StringName`;
- readable `label`;
- positive `duration_ticks`;
- ordered consumed input requirements;
- ordered non-consumed tool requirements;
- optional required workstation capability;
- ordered output definitions.

Each consumed/tool/output requirement contains:

- exact semantic `item.*` type;
- positive physical entity count.

Candidate 001 uses **exact semantic requirements**, not broad automatic tag matching.

Reason: if a survivor owns several valuable objects that all share a future category/tag, the game must not silently choose which physical item to destroy. Flexible alternatives may be added later with explicit player selection; Candidate 001 keeps selection deterministic and inspectable.

There is no generic stack/quantity store. `count = 3` means three distinct stable item entities.

---

## 5. Recipe catalog rules

`CraftingRecipeCatalog` is configuration, not save state.

Registration fails closed when:

- recipe ID or label is invalid;
- duration is non-positive;
- an input/tool/output count is non-positive;
- an input/tool/output semantic is not `item.*`;
- an output lacks known positive System-13D weight;
- an output lacks intentional System-31 icon coverage;
- Candidate-001 input/output uses a System-30 perishable semantic;
- a workstation capability is malformed;
- the recipe ID duplicates an existing recipe.

The catalog exposes deterministic sorted recipe IDs and copy-safe reads.

Candidate 001 recipes are all known to the player. Recipe discovery/books/knowledge gates belong to later approved progression/skills work rather than being faked now.

---

## 6. Ingredient/tool candidate set

Crafting may consume/use only **personally possessed** item entities.

The bounded source set is derived from the existing actor possession graph:

- items in either hand;
- actor-root direct contents;
- nested contents of personally carried item-containers.

The implementation should reuse the existing System-13E personal-possession/carry traversal rather than scan all WHAT entities.

Candidate 001 never auto-pulls ingredients from:

- nearby floor items;
- a searched refrigerator/cabinet/rack;
- another survivor;
- a vehicle/corpse/future base store;
- any other reachable world object.

The player must physically TAKE an ingredient first through existing System 12 rules.

This keeps Crafting from becoming a second inventory/access system.

---

## 7. Deterministic physical selection

For each exact-semantic requirement, `CraftingPlanQuery` selects matching personally possessed stable item IDs in lexical stable-ID order.

The plan records the exact IDs intended for consumption/use.

Rules:

- the same current physical state produces the same plan;
- an item cannot satisfy two separate consumed requirements in the same plan;
- an item used as a consumed ingredient cannot simultaneously satisfy a non-consumed tool requirement;
- duplicate stable IDs are rejected;
- selected inputs/tools must still be valid `item.*` entities;
- missing required quantity returns an explicit shortage, not a partial recipe.

The UI may show human-readable counts, but the plan remains entity-specific.

---

## 8. Container/freshness safety boundary

Candidate 001 consumed ingredients must not be enrolled System-11 containers, even if currently empty.

Reason: deleting a container-capable item also requires lifecycle ownership for its container enrollment and future nested state. That is unnecessary for the first crafting slice and would make ingredient deletion broader than the recipe mechanic requires.

Candidate 001 also excludes all System-30 perishable semantics from consumed inputs and outputs.

These are deliberate bounded restrictions, not claims that bags or food can never be crafted later.

Non-consumed tools remain ordinary physical items and are never deleted by Candidate 001.

---

## 9. Tools

Tools are explicit physical requirements, not menu flags.

A required tool must be one of the actor's currently personally possessed stable item entities and must still exist/qualify at craft commit.

Candidate 001 tools are **not consumed and do not lose durability**, because no general durability/condition owner exists yet.

Examples of valid tool requirements may include existing real items such as:

- hammer;
- screwdriver;
- pliers;
- adjustable wrench;
- scissors;
- kitchen knife where physically appropriate.

No recipe grants hidden capability merely because an icon or text says “tool.”

Future durability/quality systems may attach through a narrow tool-use result seam without changing recipe identity or WHEN ownership.

---

## 10. Workstations

`CraftingWorkstationCatalog` explicitly maps a physical OBJECT semantic to one or more crafting capability IDs.

Candidate 001 begins conservatively with the already-existing heavy workbench semantic as a general workbench capability, e.g.:

`prop.workbench_heavy -> crafting.workbench.general`

Capability is not inferred from:

- semantic text containing “bench”;
- sprite/art appearance;
- building type;
- proximity alone.

A workstation-required recipe is craftable only when:

1. the actor is a placed survivor;
2. a currently placed OBJECT with the required explicit capability exists;
3. it intersects System-29 `CONTACT_FORWARD` reach;
4. the same workstation/reach truth remains valid at commit.

Hand recipes carry no workstation capability and may be performed anywhere the actor can normally begin an action.

Candidate 001 does not add powered workstations. Power-dependent machinery waits for Phase 3 or another future owning design.

---

## 11. Read-only craftability query

`CraftingPlanQuery` / equivalent read facade returns deterministic data sufficient for UI and action admission:

- recipe ID/label;
- READY / BLOCKED / UNKNOWN status;
- exact selected consumed item IDs;
- exact selected tool item IDs;
- required/current workstation entity ID when applicable;
- missing ingredient/tool/workstation reasons;
- input/output weight totals;
- projected carried mass / hard limit;
- duration ticks.

Query work spends zero WHEN ticks and mutates nothing.

It operates only over:

- the selected recipe;
- the actor's bounded personal possession set;
- the tiny System-29 reachable OBJECT set when a workstation is required.

It never scans the whole persistent world.

---

## 12. Craft action lifecycle

Semantic action type:

`crafting.craft_recipe`

Candidate 001 pattern:

> request -> validate exact plan -> schedule WHEN -> revalidate exact plan at final commit -> bounded physical transformation

Candidate 001 uses one final phase:

`crafting.commit`

Interruption policy:

`CANCELABLE`

Rules:

- request-time rejection spends zero ticks;
- accepted craft has explicit positive recipe duration;
- cancellation before final commit consumes nothing and creates nothing;
- hard application pause freezes progress exactly;
- commit-time stale failure spends elapsed action time but produces no result;
- no partial output exists before the final commit.

Longer future crafts may justify RESUMABLE/checkpoint behavior, but Candidate 001 does not invent partial-progress item state prematurely.

---

## 13. Commit-time revalidation

Before the first mutation at `crafting.commit`, System 32 revalidates:

- actor still exists as the expected survivor;
- actor root container still exists/enrolled;
- recipe/catalog version still resolves;
- every exact consumed item ID still exists with the expected semantic;
- every exact consumed item still has the expected personal disposition/version and is not an enrolled container;
- every exact tool ID still exists, has expected semantic, and remains personally possessed;
- workstation entity/capability/placement/reach still matches when required;
- no input/output semantic has become invalid under Candidate-001 freshness/content rules;
- every deterministic output ID is still unused;
- all output weights remain known/positive;
- current projected carried mass remains within the current System-13E hard limit.

Any failure aborts before mutation.

---

## 14. Output identity

Crafted outputs are new persistent WHAT item entities.

Output stable IDs derive deterministically from the authoritative WHEN action serial plus output ordinal, using a valid stable-ID encoding such as:

`craft:<actor-id>:<action-serial>:<ordinal>`

The exact encoding is implementation detail but must satisfy:

- deterministic replay from the same committed action;
- no dependence on dictionary iteration/frame timing;
- no collision with existing entity IDs;
- stable identity after creation;
- output order follows canonical recipe output order.

Outputs are created unplaced, then contained directly by the actor root through System 11.

No crafted-output inventory exists outside WHAT + System 11.

---

## 15. Bounded commit / compensation

A normal craft may touch several item entities, so one System-12 single-item transfer is insufficient. Candidate 001 still must not use an expensive full-world snapshot transaction.

Implementation uses a **bounded mutation journal** containing only the exact entities/domains touched by that recipe.

Preflight happens before mutation. Then, in deterministic order:

1. remove each selected consumed item from its existing hand or System-11 parent using the owning public mutation service;
2. remove that item entity from WHAT;
3. create each deterministic output WHAT entity;
4. contain each output directly in the actor root.

For every successful destructive step, the journal records enough prior truth to reverse that exact step.

If any later mutation fails:

- newly created outputs are removed/cleared;
- consumed entities are recreated with the same stable ID + semantic;
- their captured hand/container disposition is restored through the owning public service;
- a bounded compensated failure is reported.

If compensation itself fails, System 32 records a `critical_consistency_failure` diagnostic rather than pretending the craft succeeded.

The implementation may wrap successful WHAT changes in the existing world change-batch mechanism for downstream invalidation/coalescing, but batching is **not** treated as rollback or gameplay atomicity.

No recipe may have unbounded input/output cardinality. Candidate 001 uses a small fixed maximum so commit/compensation cost is bounded by recipe size, not world size.

---

## 16. Mass rule

Candidate 001 recipes should preserve plausible physical mass.

Exact equality is preferred for simple bundling/sorting/salvage recipes when practical. Small explicit mass loss is acceptable when the recipe represents discarded unusable material, but mass may not appear from nowhere without a physically represented input.

Recipe verification reports input/output gram totals so accidental large mass creation is visible in CI.

This is a content-quality rule, not a detailed conservation-of-matter simulator.

---

## 17. Candidate 001 recipe content

The first recipe set should be deliberately small and demonstrate the substrate rather than pretending later systems are already useful.

It must include at least:

1. **hand bundling/reclamation** using ordinary personally carried junk/materials;
2. **tool-required hand work** where the required real tool is not consumed;
3. **general-workbench reclamation/assembly** requiring the real nearby heavy workbench capability;
4. **one multi-stage chain** where an item crafted by System 32 becomes an ingredient or tool for another System-32 recipe.

Good Candidate-001 output families include standardized physical components such as:

- paper/cardboard bundle;
- metal scrap bundle;
- wire/electrical salvage bundle;
- repair/patch component kit;
- simple improvised crafting tool/tool kit.

Exact balanced recipes are content data and may be tuned during implementation, but every shipped output must be a real `item.*` semantic with real weight and explicit UI icon coverage.

Candidate 001 deliberately avoids producing fake “working” appliances, weapons, powered devices, treatments, meals, vehicle parts with behavior, or construction structures whose actual owning mechanics do not yet exist.

A crafted tool may be useful **inside Crafting itself** as a requirement for another recipe; this provides immediate real Phase-2 utility without inventing future combat/repair/utility behavior.

---

## 18. Interaction offer

System 32 provides a read-only `CraftingInteractionOfferProvider` for System 29.

For an explicitly classified workstation currently in the actor's `CONTACT_FORWARD` reach, it may publish:

- action ID: `crafting.use_workstation`;
- label: `CRAFT`;
- reach profile: `CONTACT_FORWARD`.

The provider mutates nothing and spends zero ticks.

System 29 applies its existing current-visibility rule before drawing the highlight. A hidden/remembered workbench cannot reveal current usability through Crafting.

A workstation may legitimately have multiple real offers from different systems later; System 29 keeps its existing deterministic target deduplication while preserving action identities.

---

## 19. Player-facing crafting UI

Candidate 001 adds one phone/Safari-first **CRAFT** modal integrated into the canonical player shell without making UI a mechanic owner.

The modal reads System-32 query results and may show:

- recipe icon/name;
- hand/workbench requirement;
- duration ticks/time label;
- required input counts + current availability;
- required tool(s);
- output(s);
- READY or explicit missing/blocked reason;
- a CRAFT button only for a currently request-valid recipe.

System-31 icons are presentation only. Text remains authoritative/readable beside icons.

Browsing the modal uses the existing System-16 hard-pause safety behavior and spends zero simulation ticks.

When the player commits a recipe:

1. the modal restores/releases only the hard pause it acquired itself;
2. System 32 requests the real timed action;
3. ordinary WHEN execution proceeds;
4. after completion/failure the game returns to the normal decision pause and the UI may refresh/reopen with the result.

If the application was already hard-paused before opening Crafting, the UI must not silently clear that pre-existing pause to make crafting run.

No per-frame recipe polling is required.

---

## 20. Skills / quality future seam

Phase 6 owns the final skill catalog and progression. Candidate 001 therefore implements **no Crafting skill**, no hidden Technical/Survival gate, no XP award, no quality roll, and no skill-dependent failure RNG.

System 32 should keep recipe timing/eligibility calculation behind a narrow query/policy seam so a future skill provider can modify:

- access;
- duration;
- output quality/variant where explicitly designed;
- tool/workstation requirements where physically justified.

The neutral seam must not create placeholder skill state in Phase 2.

---

## 21. Explicit non-goals

Candidate 001 does not implement:

- world construction / walls / barricades / base placement;
- repair or durability/condition loss;
- traps deployed into the world;
- cooking, nutrition, eating/drinking, food-sickness or freshness transfer;
- electrical power, water, fuel, powered tools or refrigeration;
- vehicle repair/modification;
- firearms/ammunition/weapons functionality;
- armor/clothing equipment behavior;
- medical treatment;
- skill XP/gates/quality;
- recipe discovery/books;
- AI crafting;
- auto-crafting queues;
- batch “craft 100” loops;
- abstract crafting resources/currency;
- generic stack quantities;
- automatic nearby-container/floor ingredient pulling;
- per-item durability/charges invented solely to make a recipe look richer.

These remain with their owning later phases/systems.

---

## 22. Determinism / persistence

System 32 adds no persistent “crafted item list.”

After a successful commit:

- consumed item entities no longer exist;
- output entities exist in WHAT with stable IDs;
- System 11 owns their current containment;
- System 13D owns weight classification;
- System 31 owns icon presentation;
- any later movement is ordinary System-12 behavior.

In-progress action timing/payload is already serializable WHEN truth. The action payload must contain only the deterministic recipe/selected-entity facts required to revalidate/commit after a future save restore; it must not contain live Node/callback references.

Recipe/catalog version changes do not retroactively rewrite already-created items.

---

## 23. Performance boundary

Candidate 001 must add zero recurring simulation work merely because crafting exists.

Forbidden:

- `_process()` / `_physics_process()` craftability scans;
- one Node/Timer/scheduled event per persistent item or recipe;
- whole-WHAT ingredient searches;
- whole-world snapshots for ordinary crafts;
- scanning all workstations in the world;
- per-frame UI recipe recomputation;
- background auto-crafting loops.

Preferred:

- static/cached recipe/workstation catalogs;
- actor-personal possession traversal only when a query/action/UI refresh requests it;
- tiny System-29 reachable-cell workstation discovery;
- request/commit-only action work;
- bounded mutation journal by recipe cardinality;
- event/revision-driven UI refresh.

Phone/Safari remains the performance floor.

---

## 24. Candidate 001 implementation slices

### 2A — Recipe + plan foundation

Implement:

- recipe/workstation records/catalogs;
- deterministic personally possessed ingredient/tool planning;
- exact-semantic selection;
- weight/carry/workstation/freshness fail-closed validation;
- focused read-only craftability query;
- initial small recipe/output content vocabulary with System-13D/31 integration.

No mutation UI shortcut is allowed in 2A.

### 2B — Timed physical transformation

Implement:

- `crafting.craft_recipe` WHEN action;
- request + final commit revalidation;
- deterministic action-derived output IDs;
- hand/containment ingredient removal through existing owners;
- WHAT deletion/creation + actor-root output containment;
- bounded mutation journal/compensation;
- carry-limit enforcement;
- cancellation/hard-pause behavior.

### 2C — Workstation + player integration

Implement:

- explicit heavy-workbench capability;
- System-29 `CRAFT` offer using shared `CONTACT_FORWARD`;
- phone-first CRAFT modal using real query/action results;
- deterministic UI refresh from relevant state changes;
- complete-island integration/playtest pass.

All three are parts of System 32 Candidate 001; they are slices, not independent systems.

---

## 25. Verification contract

Implementation adds permanent exact-head context:

`verify/system32-crafting`

Focused verification must prove at least:

1. recipe IDs/definitions are valid, unique, deterministic and positive-duration;
2. every output semantic has known positive weight + explicit icon coverage;
3. Candidate-001 recipes reject perishable input/output semantics;
4. personally possessed candidate discovery includes hands + nested actor inventory but no unrelated world inventory;
5. exact ingredient/tool selection is deterministic by stable ID;
6. entity counts mean real distinct entities, not a hidden stack abstraction;
7. required tools are real stable items and remain unconsumed;
8. hand crafting requires no workstation;
9. workbench crafting requires explicit workstation capability + shared `CONTACT_FORWARD` reach;
10. semantic/art names alone never create workstation capability;
11. request-time failure spends zero ticks;
12. accepted recipe spends its exact configured positive WHEN duration;
13. hard application pause freezes an in-progress craft exactly;
14. CANCELABLE interruption before commit consumes/creates nothing;
15. commit-time ingredient/tool/workstation/carry staleness fails after elapsed time with no output;
16. consumed input stable entities are actually removed from their owning dispositions/WHAT;
17. crafted outputs are genuinely new persistent WHAT item entities in the actor root container;
18. output IDs are deterministic from action identity/order;
19. projected hard carry ceiling is enforced at request and commit;
20. container-capable consumed inputs fail closed in Candidate 001;
21. injected mid-commit failure restores all touched input/output truth or emits explicit critical consistency failure if compensation is deliberately sabotaged;
22. recipe cardinality/commit work is bounded and no whole-world snapshot/scan is introduced;
23. System-29 CRAFT offer obeys existing visibility/highlight honesty;
24. no Skills/Power/Health/Vehicles/Combat/Durability placeholder state is introduced;
25. protected Systems 11/12/13D/13E/24/29/30/31, performance architecture, canonical startup and Pages remain green.

The exact implementation head must pass the current **19** required contexts plus `verify/system32-crafting`, for **20 required exact-head contexts**.

---

## 26. Human acceptance gate

Automated CI proves physical identity, timing, determinism, atomic/compensated behavior and ownership boundaries. It cannot prove that the recipe flow feels good.

Human playtest should verify:

- recipe list is readable on phone/Safari;
- missing requirements are obvious;
- selecting CRAFT never feels like a zero-time menu cheat;
- physical inputs disappear only after the timed action completes;
- outputs appear as ordinary inventory items;
- workbench requirement is readable in-world;
- recipe set feels useful enough to justify scavenging junk/materials without pretending later systems already exist;
- performance remains smooth while browsing/crafting.

Bounded recipe/timing/UI tuning after playtest does not reopen architecture unless it changes ownership, persistence, timing semantics or input/output physicality.

---

## 27. Protected neighbors

Candidate 001 must preserve:

- WHERE/WHAT/WHEN foundation contracts;
- System 09 hand ownership;
- System 11 direct/nested containment truth;
- System 12 ordinary single-item transition ownership and external-access behavior;
- System 13D weight truth;
- System 13E derived carry + hard ceiling;
- System 24 deterministic persistent virgin loot/search;
- System 29 neutral reach + offer/highlight rule;
- System 30 analytic freshness ownership;
- System 31 presentation-only icon ownership;
- System 16 hard-pause/modal safety;
- 00F streaming/materialization ownership;
- performance architecture / phone-Safari floor.

---

## 28. Approval gate

This document completes **DESCRIBE** for Roadmap Phase 2 / System 32 Candidate 001 only.

No System-32 runtime implementation is authorized by this document until the user approves it.

On approval, implementation proceeds in order:

1. **2A Recipe + plan foundation**;
2. **2B Timed physical transformation**;
3. **2C Workstation + player integration**;
4. exact-head verification across the resulting **20-context** stack;
5. documentation closeout only after the executable head is green.
