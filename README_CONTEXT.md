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
- System 00D `temperate.island.region` v1 overlays deterministic LAND / SHORE / OCEAN on the proven rural-v6 settlement/road/hydrology skeleton.
- Five globally connected sites remain proven: one `rural.crossroads`, one `smalltown.center`, three `rural.scattered` hamlets.
- System 00F materializes non-overlapping settlement, river/watercourse and island-surface logical sources.
- Technical streaming is 128×128 with active radius 1 and follows the survivor. Technical regions are performance configuration, never world identity.
- Ocean/ordinary river water is non-traversable except explicit planned bridge deck.

---

## Current implemented stack

Foundation and gameplay through **System 30** are implemented, including persistent WHAT, deterministic WHEN, complete-island generation/streaming, inventory/transfer/carry, 24 building archetypes, ten local-area profiles, perception, persistent loot/search, world time/daylight, spatial sound, physical lighting, Weather, interaction affordance/reach, and item freshness/spoilage.

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

---

## Performance architecture / Weather gate — HUMAN ACCEPTED

The P0/P1/P2 performance architecture plus Weather P3/P3B/P3C/P3D is accepted by human playtest.

First P0/P1/P2 fully green executable: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.

Human-accepted Weather P3D executable: `6016fe5098804e3e6aba6c9f5f9658282036a697`.

Current protected result:

- continuous rain/fog is one persistent GPU atmosphere surface;
- no CPU continuous-rain/fog redraw loop;
- camera movement does zero Weather redraws and does not restart animation;
- shelter is cached low-resolution presentation data;
- physical Weather/wetness/light/hearing/vision truth is unchanged;
- predictive/amortized streaming remains measured follow-up only if future evidence justifies it.

The pre-1B human performance gate is closed.

---

## System 30 / Roadmap Phase 1B — COMPLETE

Canonical design:

`SYSTEM_DESIGNS/30_ITEM_FRESHNESS_SPOILAGE.md`

First fully green executable:

`39716f27b7f91b7007645ceae02dedc47601bf87`

Core rule:

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

Implemented result:

- explicit perishable semantic profiles only;
- sparse typed per-instance freshness state only for perishables;
- FRESH / AGING / STALE / SPOILED derived analytically;
- zero per-item `_process`, timer or scheduled spoilage event;
- cumulative exposure-provider seam with ambient as Candidate 001;
- virgin world perishables use logical scenario origin tick 0, so late technical materialization never creates magically fresh food;
- bounded deterministic initial-age variation;
- System 24 transactionally enrolls perishables and rolls freshness back with WHAT/containment/loot on failure;
- production loot probabilities and action timings are unchanged;
- inventory/container inspection shows coarse freshness labels;
- refrigerators do **not** fake cooling until Phase 3 provides real power/appliance truth;
- Phase 4 later owns eating/drinking/health consequences.

System-30 verification includes System-24 rollback, live canonical startup, System-25 time regression and read-only inspection integration. The executable completed all **16 required exact-head contexts** successfully.

---

## Active work — Roadmap Phase 1C

### System 31 Semantic UI Icons — DESCRIBE COMPLETE; awaiting APPROVE

Canonical draft:

`SYSTEM_DESIGNS/31_SEMANTIC_UI_ICONS.md`

Core rule:

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

Candidate 001 design:

- one dedicated low-resolution `ui_icon_atlas.svg`;
- 16×16 logical icon cells displayed at an exact 2× / 32×32 size;
- one shared Node-free `SemanticUiIconCatalog` with cached atlas-region textures;
- explicit mapping for all current 71 `LootItemCatalog` semantic types, with intentional glyph sharing allowed but no automatic family fallback;
- an explicit unknown glyph + diagnostic for future unmapped semantics while text remains usable;
- `STATS`, `INVENTORY`, and `MENU` become icon + text rather than icon-only;
- occupied hands, carried inventory, scavenging `CONTENTS`, and `YOUR PACK` rows use the same semantic item icons;
- current TAKE/STORE, movement and DEV controls remain text-only in Candidate 001;
- existing labels, stable IDs, weight, utility/family and System-30 freshness text remain real data beside the icon;
- no persistent state, save schema, simulation tick work, per-item Node/timer/process, or world scan;
- selected System-10 silhouettes may be visually repacked into the UI atlas with provenance, but System 31 has no runtime dependency on hand-equipment presentation.

Lifecycle:

**DESCRIBE COMPLETE -> awaiting APPROVE -> then IMPLEMENT -> VERIFY**

No System-31 runtime code or asset implementation is authorized by the draft alone.

---

## Phase 1 order

1A. Interaction affordance + reach — **COMPLETE**.

1B. Item freshness/spoilage — **COMPLETE; System 30**.

1C. Semantic inventory/menu icons — **DESCRIBE COMPLETE; System 31 draft awaiting approval**.

1D. Large/multi-cell object visual geometry.

1E. Content expansion/integration.

Then: Crafting -> Power + Water -> physical survival/health -> Moodlets -> Skills/interactions -> Vehicles -> AI/combat/outbreak -> final graphics/UI -> Beta.

---

## Relevant ownership boundaries

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
- `verify/performance-architecture`
- `verify/pages-deploy`

All **16 required contexts** are green on System-30 executable head `39716f27b7f91b7007645ceae02dedc47601bf87`.

System 31 is still design-only, so `verify/system31-semantic-ui-icons` does **not** join the required executable stack until implementation is approved and verified.