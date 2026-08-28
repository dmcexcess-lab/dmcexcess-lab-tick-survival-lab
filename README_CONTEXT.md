# Tick Survival Lab — Current Context

> Read `PROJECT_NORTH_STAR.md`, `PERFORMANCE_NORTH_STAR.md`, `ROADMAP.md`, `README_SOPS.md`, `SYSTEM_DESIGNS/README.md`, current `main`, and the relevant system design before repository changes.

## Game

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**
>
> **The low-resolution 2D presentation and turn-based simulation are deliberate performance advantages. Spend that budget on simulation depth, persistence, world scale and responsiveness — not avoidable work.**

Repository: `dmcexcess-lab/dmcexcess-lab-tick-survival-lab`

Live build: `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`

Golden archaeology commit: `1763958f44eb7f855fd49944c00d1ffe608c0abe`.

---

## Current playable world

The canonical DEV/playable composition is the **complete streamed island**.

- Global bounds: 1792×1792 tactical cells (`Rect2i(232,1232,1792,1792)`).
- System 00D `temperate.island.region` v2 overlays deterministic LAND / SHORE / OCEAN on the proven rural-v6 world-planning skeleton while using island-specific compact settlement spacing and derived local site seeds.
- Five globally connected site identities remain: one `rural.crossroads`, one `smalltown.center`, three `rural.scattered` hamlets.
- System 00F materializes non-overlapping settlement, river/watercourse and island-surface logical sources.
- Technical streaming is 128×128 with active radius 1 and follows the survivor. Technical regions are performance configuration, never world identity.
- Ocean/ordinary river water is non-traversable except explicit planned bridge deck.
- The playable survivor starts on inherited pavement beside the central crossroads, not at the diner entrance.

### Legacy mini-map / green-belt correction — VERIFIED 2026-08-27

Verified executable: `d33c69d6bd05f4c8fdbba62c6bd51bb16aad26ad`.

The reported visual defect had multiple real causes rather than being only a spawn problem:

1. The island's central 256×256 `rural.crossroads` site occupied the exact old critique bounds and reused world seed `20001`, which made it regenerate the old standalone critique map inside the larger island.
2. Island settlement spacing inherited much larger regional-v6 distances, leaving an oversized countryside band between 256×256 settlement rectangles.
3. Settlement natural dressing evaluated patch/family noise from `cell - request.bounds.position`, restarting the environmental noise phase at every logical area rectangle and making the ownership boundary visible.
4. Earlier island-surface palette/dressing behavior further emphasized the rectangle instead of making the land read as one continuous place.

Current corrected result:

- `temperate.island.region` is v2 and explicitly forbids raw world-seed reuse for the central site;
- the central site keeps its stable world identity/location but receives a derived local seed, so its generated System-20 signature is no longer the old standalone Rural Crossroads fixture;
- island-only settlement spacing is compact, while protected `temperate.rural.region` v6 behavior is unchanged;
- island interior and settlement sites use the same rural/lush environmental vocabulary;
- `AreaGenerationRequest` exposes an optional `inherited_ecology_seed` used only when upstream world context requires cross-area environmental continuity;
- globally projected island settlements receive the System-00D world seed for natural ecology while retaining their own site seed for roads, parcels, buildings and other local morphology;
- `NaturalEcologyField` evaluates natural density/family/semantic from **world seed + absolute global cell**;
- `IslandSurfaceAreaGenerator` v3 and globally projected settlement dressing share that field, so tree/shrub/rock patch noise does not restart at the 256×256 source boundary;
- standalone System-20 fixtures without an inherited ecology seed retain their historical local behavior;
- inherited regional road surface and centerline remain continuous outside settlement sources;
- no source overlap, streaming-geometry change, WHAT/WHEN change or recurring per-frame/per-tick world scan was added.

`IslandLegacySeamSmoke.gd` now proves both identity and boundary continuity. In particular, a natural-ecology probe must produce the exact same sorted `(cell, semantic)` set whether the same land is generated as one rectangle or split into two adjacent logical rectangles.

All **17 required exact-head contexts** passed on `d33c69d6bd05f4c8fdbba62c6bd51bb16aad26ad`, including global world, local area, streaming/materialization, performance architecture and Pages deployment.

This is automated deterministic verification. The user subsequently visually playtested the deployed island and reported that it **looks good**.

---

## Current implemented stack

Foundation and gameplay through **System 31** are implemented, including persistent WHAT, deterministic WHEN, complete-island generation/streaming, inventory/transfer/carry, 24 building archetypes, ten local-area profiles, perception, persistent loot/search, world time/daylight, spatial sound, physical lighting, Weather, interaction affordance/reach, item freshness/spoilage, and semantic inventory/menu icons.

Important current rules:

1. Generation creates virgin truth once; WHAT + typed mechanic stores own current reality afterward.
2. Technical streaming activation is not world existence.
3. Art/rendering is presentation, never physics/simulation authority.
4. Phone/Safari is first-class.
5. Sound is physical; hearing is an estimate.
6. Light is physical; vision is observer-specific.
7. Weather is simulation truth; weather animation is presentation.
8. Fatigue is the stamina/endurance concept; there is no parallel stamina meter.
9. Interaction highlights explain already-valid actions; they never create action truth.
10. Expensive consumers wake only for the domains/completed batches they actually depend on.
11. Food freshness is derived analytically from authoritative time/exposure; no item gets a spoilage timer.
12. UI icons may visualize semantic truth but must never define item identity, utility, freshness, or action legality.
13. Logical area/streaming boundaries must not reset world-space environmental identity.
14. Physical footprints answer where objects are; presentation geometry may be larger but may never silently redefine physical truth.

---

## Performance architecture / Weather gate — HUMAN ACCEPTED

The P0/P1/P2 performance architecture plus Weather P3/P3B/P3C/P3D is accepted by human playtest.

First P0/P1/P2 fully green executable: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.

Human-accepted Weather P3D executable: `6016fe5098804e3e6aba6c9f5f9658282036a697`.

Protected result:

- continuous rain/fog is one persistent GPU atmosphere surface;
- no CPU continuous-rain/fog redraw loop;
- camera movement does zero Weather redraws and does not restart animation;
- shelter is cached low-resolution presentation data;
- physical Weather/wetness/light/hearing/vision truth is unchanged;
- predictive/amortized streaming remains measured follow-up only if future evidence justifies it.

The pre-1B human performance gate is closed.

---

## System 30 / Roadmap Phase 1B — COMPLETE

Canonical design: `SYSTEM_DESIGNS/30_ITEM_FRESHNESS_SPOILAGE.md`

First fully green executable: `39716f27b7f91b7007645ceae02dedc47601bf87`.

Core rule:

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

Implemented result:

- explicit perishable semantic profiles only;
- sparse typed per-instance freshness state only for perishables;
- FRESH / AGING / STALE / SPOILED derived analytically;
- zero per-item `_process`, timer or scheduled spoilage event;
- cumulative exposure-provider seam with ambient as Candidate 001;
- virgin world perishables use logical scenario origin tick 0;
- bounded deterministic initial-age variation;
- System 24 transactionally enrolls perishables and rolls freshness back with WHAT/containment/loot on failure;
- production loot probabilities and action timings are unchanged;
- inventory/container inspection shows coarse freshness labels;
- refrigerators do not fake cooling until Phase 3 provides real power/appliance truth;
- Phase 4 later owns eating/drinking/health consequences.

---

## System 31 / Roadmap Phase 1C — COMPLETE

Canonical design: `SYSTEM_DESIGNS/31_SEMANTIC_UI_ICONS.md`

First verified executable: `dc83ad10b7469a629fb2ac5d86c77d386b69434d`.

Core rule:

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

Implemented result:

- one dedicated low-resolution `ui_icon_atlas.svg`;
- 16×16 logical icon cells displayed at exact 2× / 32×32 size;
- one shared Node-free `SemanticUiIconCatalog` with cached atlas-region textures;
- explicit mapping for all current 71 `LootItemCatalog` semantic types plus three shell controls;
- explicit unknown glyph + diagnostic for future unmapped semantics while text remains usable;
- `STATS`, `INVENTORY`, and `MENU` are icon + text;
- occupied hands, carried inventory, scavenging `CONTENTS`, and `YOUR PACK` rows use the same semantic item icons;
- existing labels, stable IDs, weight, utility/family and System-30 freshness text remain real data beside the icon;
- zero persistent state, save-schema change, simulation-tick work, per-item Node/timer/process, or world scan.

---

## Active work — Roadmap Phase 1D / System 07B

### Large / multi-cell object visual geometry — DESCRIBED, AWAITING APPROVAL

Canonical draft: `SYSTEM_DESIGNS/07B_LARGE_MULTI_CELL_VISUAL_GEOMETRY.md`.

Core rule:

> **Physical footprint answers where the object is. Visual geometry answers how that object is drawn. Neither may silently redefine the other.**

Candidate 001 design:

- System 07B extends existing System 07 rather than creating a new top-level renderer/gameplay system;
- Node-free descriptors define whole-cell visual span plus an anchor-attached fractional pivot;
- System 07A continues to own orientation;
- physical footprint/anchor remain WHAT/WHERE truth and are never inferred from artwork;
- one shared stable-entity visual plan feeds a z=20 base/body pass and optional z=35 foreground/overhang pass above actors but below physical lighting;
- a small catalog-derived discovery halo prevents offscreen-anchor canopy/arm pop-in without any whole-world scan;
- existing unmapped props retain the exact historical 1×1 visual fallback;
- first implementation proofs are a 2×2-or-larger large tree and larger traffic/stop-light art;
- no save schema, WHEN work, collision/reach/LOS change, per-entity Node, generic Y-sort rewrite, vehicle implementation or content-expansion sweep is authorized by this design.

The next lifecycle gate is **APPROVE**. No Phase-1D runtime implementation is authorized until approval.

---

## Phase 1 order

1A. Interaction affordance + reach — **COMPLETE**.

1B. Item freshness/spoilage — **COMPLETE; System 30**.

1C. Semantic inventory/menu icons — **COMPLETE; System 31 implemented + CI verified**.

1D. Large/multi-cell object visual geometry — **DESCRIBED; System 07B awaiting approval**.

1E. Content expansion/integration.

Then: Crafting -> Power + Water -> physical survival/health -> Moodlets -> Skills/interactions -> Vehicles -> AI/combat/outbreak -> final graphics/UI -> Beta.

---

## Relevant ownership boundaries

- System 00D owns global geography, settlement/road/hydrology/infrastructure truth and cross-area world context.
- System 00F owns materialization-source orchestration and technical activation, not world identity.
- System 20 owns bounded local physical generation and may consume optional upstream environmental context without taking global ownership.
- System 07 owns prop/fixture/vegetation presentation; System 07A owns prop-art orientation; draft System 07B owns only authored visual span/pivot/overhang after approval.
- Systems 00A/00B remain authoritative for physical footprint, placement and stable entity identity.
- System 11 owns containment.
- System 12 owns timed physical item transitions.
- System 13D owns semantic physical weight.
- System 24 owns what virgin loot exists and keeps the rule **loot exists before you search for it**.
- System 25 interprets authoritative WHEN ticks as simulation time.
- System 30 owns freshness records/derivation but does not replace those domains.
- System 31 is presentation-only and resolves icons from existing semantic keys after mechanic queries; simulation owners do not store or read icon identity.
- Phase 3 Power/Refrigeration later provides real cold-storage exposure; System 30 must not import/fake Power.
- Phase 4 later interprets freshness for nutrition/sickness/health consequences.

---

## Required executable-head contexts currently

- `verify/system00d-global-world`
- `verify/system00f-streaming-materialization`
- `verify/system19-local-building`
- `verify/system20-local-area`
- `verify/system21-camera-view`
- `verify/system22-area-critique`
- `verify/system23-perception`
- `verify/system24-loot`
- `verify/system25-world-time-light`
- `verify/system26-spatial-sound`
- `verify/system27-physical-lighting`
- `verify/system28-weather`
- `verify/system29-interaction-affordance`
- `verify/system30-item-freshness`
- `verify/system31-semantic-ui-icons`
- `verify/performance-architecture`
- `verify/pages-deploy`

All **17 required contexts** are green on the current verified playable-island executable `d33c69d6bd05f4c8fdbba62c6bd51bb16aad26ad`.

If System 07B is approved and implemented, its dedicated verification context becomes an additional required executable-head context for that implementation.
