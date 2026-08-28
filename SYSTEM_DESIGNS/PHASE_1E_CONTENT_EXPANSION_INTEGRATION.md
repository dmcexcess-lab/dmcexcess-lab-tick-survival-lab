# Tick Survival Lab — Roadmap Phase 1E Content Expansion + Integration

Status: **IMPLEMENTED + CI VERIFIED — Candidate 001; human visual acceptance pending**

Described: **2026-08-27**

Approved: **2026-08-27 — 1E-1 through 1E-3 approved for code**

Verified executable: **`6ad923d172f5a5434f94a7fdcc15da640a60a240`**

Phase type: **cross-system content/integration phase; not a new runtime System 32**

## 1. Goal

Use the completed Phase-1 foundations to make ordinary generated places feel materially distinct, inhabited and worth scavenging before Phase 2 Crafting begins.

Core rule:

> **Content extends the system that already owns its truth. Integration does not create a second owner.**

Phase 1E produces a large visible/content increase in world richness without faking later mechanics. It is content/profile/catalog work across Systems 19, 20, 24, 30, 31, 04 and 07B, with System 29/27 consumed only where their existing truth contracts already permit it.

### Candidate-001 completion record

The approved 1E-1 through 1E-3 implementation is complete on executable head `6ad923d172f5a5434f94a7fdcc15da640a60a240`.

Delivered integration:

- `Phase1EOneStoryContentDresser` enriches the 18 baseline one-story System-19 profiles with deterministic program-appropriate accents, capped at two additions per building. The six protected historical reference archetypes remain outside the dresser. Dressed baseline output records content version 2 while the underlying structural profile definitions retain their established profile identity.
- Existing System-20 exterior generation remains the physical owner. Its ordinary generated `prop.deciduous_large` and `prop.traffic_light` semantics now consume the approved System-07B large visual geometry; the older `vegetation.deciduous_large` / `fixture.traffic_light` fixture aliases remain supported for protected renderer regressions.
- `LootItemCatalog` v3 exposes 97 physical item semantics. Location-aware container content was broadened, including distinct school/church/police/fire supplies, while the System-24 rule that loot exists before search is unchanged.
- Every shipped Phase-1E item receives positive System-13D physical weight and an intentional System-31 icon mapping. The current icon catalog therefore covers all 97 item semantics plus the three shell controls.
- `ItemFreshnessProfileCatalog` v2 explicitly covers 10 perishable semantics. Shelf-stable goods remain outside freshness state and no refrigeration truth is invented.
- Permanent `verify/phase1e-content-integration` was added. Together with the existing protected stack, all 19 required exact-head contexts are green on the verified executable.

Automated implementation is complete. The separate human visual/readability pass described in Section 11 is still pending and is not implied by CI.

## 2. Why 1E is not System 32

The architecture already has owners for every truth 1E needs:

- System 19 owns building programs, rooms, fixtures and deterministic interior dressing;
- System 20 owns local roads/parcels/access, yards, roadside/environmental dressing and profile selection;
- System 24 owns virgin world loot definitions, searchable-container capability and location-aware loot profiles;
- System 30 owns which item semantics are perishable and their freshness profiles;
- System 31 owns explicit semantic UI icon mappings;
- System 13D owns physical item weights;
- System 04 owns world-art selection;
- System 07 / 07A / 07B own prop presentation, orientation and large visual geometry;
- System 29 displays only real interaction offers from mechanic owners;
- System 27 owns physical light truth and emitter-derived glow.

Adding content through a new peer system would duplicate those owners. Phase 1E is therefore an integration plan with bounded implementation slices.

## 3. Candidate 001 implementation slices

### 1E-1 — World clutter + location identity

Goal: make generated locations immediately readable as different kinds of places before the player opens a menu.

Work remains in existing generation/art owners.

#### System 19 interior content

Expand reusable profile-driven room dressing and semantic variation without changing the frozen building grammar contract.

All currently callable 24 building archetypes receive an intentional content audit. Content should vary by program family rather than simply increasing prop count everywhere.

Target identity families:

- **residential / lodging:** kitchens, bathrooms, bedrooms, wardrobes, desks, laundry/storage, compact domestic clutter and believable empty space;
- **diner / food service:** customer tables/booths, counter/service zone, kitchen work run, storage and back-of-house supplies;
- **gas station / convenience / grocery:** customer shelving, cool storage, counter zone, stock/back-room context and forecourt-facing identity;
- **pharmacy / clinic:** medicine/storage/counter/office treatment-support vocabulary without implementing treatment actions;
- **hardware / workshop / warehouse:** tool, fastener, material, rack, workbench and industrial storage vocabulary;
- **office / school / civic:** desks, files, books, seating, supply/storage and service-area distinctions;
- **farm / barn:** tool, feed/storage-like, crate/barrel, shed/work and agricultural vocabulary;
- **police / fire / church:** profile-appropriate civic fixtures and storage without implementing AI, weapons or new service mechanics.

Rules:

- preserve every protected System-19 structural/circulation invariant;
- door cells and immediate approaches remain clear;
- service/work lanes remain usable;
- blocking-room density remains bounded by the existing grammar quality policy;
- empty space remains valid output;
- deterministic variation should change meaningful object selection/arrangement, not reroll until something fits;
- new building types are not required for Candidate 001; the payoff comes from richer use of the existing 24-profile library.

Implemented Candidate-001 detail: the shared Phase-1E dresser is deliberately bounded to **at most two added accents per baseline building**, and the six protected historical reference archetypes are not modified by it.

#### System 20 exterior / area content

Broaden profile-authorized outdoor dressing using existing area/environment owners:

- yards and property edges;
- shrubs/trees/rocks and rural natural variation;
- large trees through System 07B where the physical semantic/footprint supports them;
- traffic furniture at appropriate road/intersection contexts;
- dumpsters/trash receptacles, crates/barrels, signs, fences, utility-looking static furniture and other ordinary roadside/property objects where supported by real semantics;
- differentiated commercial, industrial, civic, suburban, urban and rural outdoor vocabulary.

Protected rules:

- never overwrite inherited roads, bridge decks, river/ocean water, reserved infrastructure, driveways, primary entry approaches or required circulation;
- natural ecology continues to use the established world-space seam where applicable;
- profile content is deterministic from existing request/site/world inputs;
- technical source/streaming boundaries never become visible content boundaries;
- no decorative object that looks physically significant should exist only as an unowned fake world sprite. Small non-interactive micro-detail may be baked into an owning prop's art, but standalone physical-looking objects should be real semantics/WHAT entities.

Candidate-001 implementation did not duplicate or rewrite System-20 outdoor morphology. The established outdoor/environment vocabulary remains authoritative and its protected exact-head regression stays green; 1E's material exterior integration is the deployment of 07B presentation onto real System-20-generated large-tree and traffic-light semantics.

#### 07B deployment

System 07B becomes ordinary content infrastructure rather than a showcase-only feature.

Candidate 001 places its approved large-tree and traffic-light/traffic-furniture visuals in suitable generated contexts and may add additional static large-object descriptors when the existing physical semantics justify them.

Visual span never modifies collision. Physical footprint changes, when genuinely needed, remain generator/WHERE content decisions and require the normal validation path rather than being inferred from art.

Implemented Candidate-001 binding uses canonical generated semantics `prop.deciduous_large` and `prop.traffic_light`; historical test aliases remain compatible presentation aliases only.

### 1E-2 — Mundane loot + perishable breadth

Goal: make scavenging outcomes reflect the kind of place being searched while expanding the ordinary survival vocabulary needed by later systems.

#### System 24 item taxonomy

Expand `LootItemCatalog` with practical physical package-unit semantics across existing families such as:

- pantry/shelf-stable food;
- fresh/perishable food;
- drinks;
- kitchen goods;
- first-aid/medical supplies;
- sanitation and cleaning;
- clothing/textiles;
- office/school supplies;
- hand tools;
- hardware/fasteners/materials;
- electrical/utility supplies;
- farming/outdoor supplies;
- automotive-adjacent inert supplies;
- industrial/workshop goods;
- contextual junk.

Exact item count is not an architectural requirement. Prefer a smaller set of useful, recognizable semantics with good location distribution over a large flat catalog of near-duplicates.

Each new item must have:

- a unique stable `item.*` semantic;
- readable label;
- explicit USABLE/JUNK classification under System 24's current taxonomy;
- intentional primary family/tags;
- positive System-13D physical weight;
- physical package-unit identity rather than a new generic stack/quantity abstraction.

Candidate 001 still does **not** add firearms/ammunition merely as content; combat owns that later.

Implemented Candidate-001 catalog version is v3 with **97 physical item semantics**.

#### Location-aware loot profiles

Broaden `LootContainerProfileCatalog` so containers feel tied to their actual building/program context.

Examples:

- home pantry/cabinet vs refrigerator vs bathroom vanity vs wardrobe;
- diner kitchen/counter/storage;
- grocery/convenience shelves vs cool storage;
- pharmacy shelf/medicine storage;
- hardware shelf/tool storage;
- office desk/file storage;
- warehouse rack/workshop storage;
- farm/barn storage;
- civic/school/service storage.

The same furniture semantic may legitimately receive different stock by building archetype/profile. Capability remains explicit.

System-24 rule is unchanged:

> **Loot exists before you search for it.**

Searching never rolls a reward into existence. Virgin contents remain deterministic persistent entities initialized through the existing source transaction.

Implemented Candidate-001 container catalog is v2 and includes explicit school, church, police and fire supply profiles in addition to broader retail/medical/hardware/industrial/farm/office stock.

#### System 30 freshness enrollment

Every newly added perishable semantic must receive an explicit System-30 freshness profile in the same implementation slice. Shelf-stable items receive no freshness record.

No fake refrigeration is allowed. Refrigerators/freezers remain ambient for freshness until Phase 3 supplies real powered appliance/storage truth.

Phase 1E does not implement eating, nutrition, sickness or treatment consequences; Phase 4 owns those later.

Implemented Candidate-001 freshness catalog is v2 with **10 explicit perishables**.

#### System 31 icon completeness

Every new `LootItemCatalog` semantic receives an intentional System-31 icon mapping in the same implementation slice.

Intentional glyph sharing is allowed. Falling through to the unknown icon for newly shipped Candidate-001 content is not.

Text labels, weight, utility/family and freshness remain visible truth beside icons.

Implemented Candidate-001 icon coverage explicitly maps all **97 current loot semantics**; with STATS / INVENTORY / MENU the catalog reports 100 known semantics.

### 1E-3 — Integration, readability + performance acceptance

Goal: make the richer content actually play well on the complete island and on phone/Safari.

This slice is tuning/integration, not a new mechanic owner.

Audit:

- generated interior/exterior density and navigability;
- visual distinction among representative location families;
- searchable-container frequency and loot-profile variety;
- highlight density from real System-29 offers;
- icon + label + freshness readability;
- large-tree/traffic-furniture layering and offscreen overhang behavior;
- System-27 emitter-derived glow around any real existing light emitters adjacent to the richer art;
- render/materialization cost from higher object counts;
- camera movement and technical streaming behavior on phone/Safari.

The final 1E human pass should answer: **does this place look and scavenge like what it is, without becoming cluttered, unreadable or slow?**

Automated Candidate-001 integration is complete. Density is bounded, protected performance/startup/streaming/rendering contracts remain green, and the dedicated 1E integration context is permanent. Human visual/readability acceptance remains separately pending.

## 4. Content-budget rules

More content must not mean filling every free tile.

Candidate 001 uses bounded authored density:

- preserve existing System-19 blocking-density and circulation validation;
- reserve door approaches, work lanes, frontage/access and road/bridge corridors first;
- use deterministic optional slots/pools for variation;
- allow intentional empty cells/rooms/yards;
- cap outdoor clutter near critical travel corridors;
- prefer one meaningful larger object over many repeated one-cell filler props where 07B supports it;
- do not use repeated decorations to hide weak generation geometry;
- no unbounded rerolls.

## 5. Lighting / glow boundary

Phase 1D's broader two-ring physical-light bloom is available to 1E art, but 1E may not turn visual fixtures into fake light sources.

Rules:

- System 27 remains the sole physical illumination owner;
- a fixture may have bright/emissive-looking pixels without creating light truth;
- glow appears only when the live presentation receives a real System-27 emitter;
- Phase 1E may reuse already-real emitters in current fixtures/test contexts;
- Phase 1E does not invent powered streetlights, neon, refrigerators, TVs or appliance state simply to make scenes prettier;
- Phase 3 Power later activates/deactivates powered fixtures through real state and then feeds System 27 downstream.

## 6. Interaction boundary

Phase 1E may expose more **existing** interactions by adding real capability under existing owners—for example, a newly classified searchable cabinet can publish the normal System-24 SEARCH offer.

It may not infer generic interaction from art or semantic names.

No new universal USE action, crafting interaction, appliance switch, food-consumption action, vehicle access or treatment action is part of Candidate 001 unless its owning later system is separately designed/approved.

System 29 remains presentation/composition only:

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

## 7. Deferred future behavior

The richer content should be deliberately future-compatible but mechanically inert where its owner does not exist yet.

Not implemented in 1E:

- Crafting recipes or material transformation — Phase 2;
- electrical/mechanical utility of tools beyond current truth — later owners;
- Power/Water/appliance operation or refrigeration — Phase 3;
- eating/drinking/nutrition/sickness/treatment effects — Phase 4;
- new Moodlet consequences — Phase 5;
- final skill gating/bonuses — Phase 6;
- working vehicles or vehicle loot/cargo logic — Phase 7;
- guns/ammunition/combat/NPC use — Phase 8;
- final art/shadow/UI overhaul — Phase 9.

Do not add placeholder state fields for those systems merely because a content item will eventually be consumed by them.

## 8. Determinism / persistence

Phase 1E content follows existing generation/persistence doctrine:

- same version + seed + request produces the same virgin content;
- generated building/area content is written once through existing materialization owners;
- System 24 virgin loot is deterministic and persistent after initialization;
- revisiting/streaming does not regenerate current WHAT contents;
- same-seed content-rule changes that alter deterministic virgin output require the appropriate owning profile/catalog version bump where current contracts require it;
- no content system receives per-tick ownership merely because more entities exist.

## 9. Performance boundary

Phase 1E increases static object and item counts while preserving the existing performance architecture.

Forbidden:

- recurring full-world prop/item scans;
- per-prop or per-item Nodes/timers/process loops;
- per-frame content selection/generation;
- foreground second-pass rediscovery;
- icon/freshness recomputation for every persistent item every frame;
- streaming-region size changes used to hide content-cost regressions.

Preferred:

- generation/materialization-time deterministic selection;
- existing bounded render-window queries;
- existing System-07B cached visual plans;
- explicit/cached art and icon catalogs;
- System-30 O(1) analytic freshness reads only when requested;
- System-29 tiny reachable-cell discovery;
- bulk/coalesced world-change paths already established by the performance gate.

## 10. Verification contract

Permanent exact-head context:

`verify/phase1e-content-integration`

The focused Phase-1E verification proves the integrated content contracts alongside the owning-system regressions:

1. **Catalog integrity** — every new loot semantic is unique, has valid classification/tags and a positive System-13D weight.
2. **Icon completeness** — every current/new loot semantic resolves intentionally through System 31; the unknown glyph is not normal shipped content.
3. **Freshness integrity** — every declared new perishable semantic has exactly one valid System-30 profile, and no profile references a nonexistent item semantic.
4. **Persistent loot rule** — expanded container profiles remain under the existing deterministic persistent System-24 initialization/search contract.
5. **Location differentiation** — representative residential, retail, civic, industrial and agricultural baseline buildings gain deterministic Phase-1E identity content; broader food-service/protected-reference truth remains covered by the owning System-19/24 regressions.
6. **Building validity** — expanded dressing preserves System-19 validation, rotation behavior, protected reference buildings and bounded content density.
7. **Area validity** — Candidate 001 does not replace System-20 morphology; the existing exact-head System-20 regression remains green and proves roads/water/access/ecology ownership is preserved.
8. **07B real use** — the approved large-tree and traffic-light visual geometry binds to ordinary generated `prop.*` semantics, not only synthetic fixture aliases.
9. **Interaction honesty** — only real mechanic capabilities generate System-29 offers/highlights; decorative additions do not become fake interactions.
10. **Lighting honesty** — content art cannot create System-27 illumination; emitter-derived lighting/glow regressions remain green.
11. **No future-mechanic fakery** — no Crafting/Power/nutrition/Skills/Vehicles/AI state is introduced as Phase-1E content metadata.
12. **Performance architecture** — no new `_process`/Timer/per-entity runtime-object or recurring world scan is added in the content integration paths.
13. **Canonical startup + Pages** remain green.

Verified executable `6ad923d172f5a5434f94a7fdcc15da640a60a240` passes all prior required contexts plus `verify/phase1e-content-integration`, for **19/19 required exact-head contexts green**.

## 11. Human acceptance gate

Automated CI can prove contracts and deterministic content signatures; it cannot prove that locations feel good.

Before Phase 1E is marked human-accepted, playtest the deployed complete island with emphasis on:

- recognizable location identity at a glance;
- sensible clutter density;
- clear walking/circulation;
- useful but not noisy interaction highlighting;
- item icon/freshness readability;
- tree/traffic-furniture scale and occlusion;
- lighting/glow readability at dark times;
- phone/Safari responsiveness.

Corrections that only tune approved content density/art/profiles may remain inside 1E without reopening the architecture unless they require a new truth owner or cross-system contract.

**Current status:** automated implementation/verification is complete; this separate human visual/readability acceptance is not yet recorded.

## 12. Protected neighbors

Candidate 001 preserves:

- 00D global geography/site/road/hydrology identity;
- 00F source ownership and 128x128 technical streaming contract;
- System-19 grammar/placement API and six protected reference buildings;
- System-20 profile/road/access/water/ecology ownership;
- WHAT/WHERE/WHEN boundaries;
- System-23 hidden-information/perception truth;
- System-24 deterministic persistent loot and search timing;
- System-27 physical light ownership;
- System-29 neutral reach/offer rule;
- System-30 analytic freshness architecture;
- System-31 presentation-only icon ownership;
- performance architecture and mobile/browser constraints.

## 13. Completion state

DESCRIBE was completed on 2026-08-27 and the user subsequently approved **1E-1, 1E-2 and 1E-3 for code**.

All three bounded slices are implemented and the verified executable head is `6ad923d172f5a5434f94a7fdcc15da640a60a240` with **19/19 required exact-head contexts green**, including Pages.

Phase 1E is therefore **IMPLEMENTED + CI VERIFIED**. Human visual/readability acceptance remains a separate optional follow-up and is not being inferred from automation.

The roadmap now advances to **Phase 2 Crafting — DESCRIBE next; implementation not yet authorized**.
