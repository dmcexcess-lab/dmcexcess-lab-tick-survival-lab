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

- Global bounds: 1792x1792 tactical cells (`Rect2i(232,1232,1792,1792)`).
- System 00D `temperate.island.region` v2 overlays deterministic LAND / SHORE / OCEAN on the proven rural-v6 planning skeleton.
- Five globally connected site identities remain: one `rural.crossroads`, one `smalltown.center`, three `rural.scattered` hamlets.
- System 00F materializes non-overlapping settlement, river/watercourse and island-surface logical sources.
- Technical streaming is 128x128 with active radius 1 and follows the survivor. Technical regions are performance configuration, never world identity.
- Ocean/ordinary river water is non-traversable except explicit planned bridge deck.
- The playable survivor starts on inherited pavement beside the central crossroads, not at the diner entrance.

### Legacy mini-map / ecology seam correction — VERIFIED + HUMAN ACCEPTED

Verified executable: `d33c69d6bd05f4c8fdbba62c6bd51bb16aad26ad`.

The live island no longer aliases the historical standalone 256x256 Rural Crossroads fixture. Island-only site seeds/spacing are distinct, and settlement + island-surface natural dressing share `NaturalEcologyField` from world seed + absolute global cell so logical source rectangles cannot restart vegetation identity.

The correction preserves non-overlapping source ownership, inherited roads/hydrology/bridges, System-19 building ownership, 128x128 streaming, WHAT/WHEN and the no-recurring-world-scan performance boundary.

The user visually playtested the deployed correction and reported that it looks good.

---

## Current implemented stack

Foundation and gameplay through **System 31**, plus **System 07B**, are implemented.

Current major capabilities include:

- authoritative WHERE / WHAT / WHEN foundations;
- collision, movement, actor locomotion, stance, carrying and timed item transfer;
- complete-island global/local generation and technical streaming;
- 24 System-19 building archetypes and ten System-20 local-area profiles;
- persistent searchable world loot;
- world time/daylight;
- spatial sound/hearing;
- physical lighting, visibility and shadows;
- Weather/atmosphere/lightning;
- perception / fog memory;
- real interaction affordance/reach highlights;
- analytic item freshness/spoilage;
- semantic inventory/menu icons;
- large/multi-cell prop visual geometry with actor-overhang layering;
- broader emitter-derived physical-light glow presentation.

Important current rules:

1. Generation creates virgin truth once; WHAT + typed mechanic stores own current reality afterward.
2. Technical streaming activation is not world existence.
3. Art/rendering is presentation, never physics/simulation authority.
4. Phone/Safari is first-class.
5. Sound is physical; hearing is an estimate.
6. Light is physical; vision is observer-specific.
7. Weather is simulation truth; Weather animation is presentation.
8. Fatigue is the stamina/endurance concept; there is no parallel stamina meter.
9. Interaction highlights explain already-valid actions; they never create action truth.
10. Expensive consumers wake only for the domains/completed batches they actually depend on.
11. Food freshness is derived analytically from authoritative time/exposure; no item gets a spoilage timer.
12. UI icons visualize semantic truth but never define identity, utility, freshness or action legality.
13. Logical area/streaming boundaries must not reset world-space environmental identity.
14. Physical footprints answer where objects are; presentation geometry may be larger but never redefines physical truth.
15. Bright art does not create light. System-27 emitter truth remains the only source of physical-light presentation glow.

---

## Performance architecture / Weather gate — HUMAN ACCEPTED

The P0/P1/P2 performance architecture plus Weather presentation optimization is human-accepted on phone/Safari.

First P0/P1/P2 fully green executable: `0398a2a49d84e6067f7610727aecacf4c05fe41f`.

Human-accepted Weather P3D executable: `6016fe5098804e3e6aba6c9f5f9658282036a697`.

Protected result includes event-driven/cache-oriented invalidation, no CPU continuous-rain/fog redraw loop, zero Weather redraws from camera movement, cached shelter presentation, and unchanged physical Weather/light/hearing/vision truth.

Predictive/amortized streaming remains evidence-driven follow-up only.

---

## Roadmap Phase 1A — COMPLETE

System 29 owns neutral reach + interaction-offer composition under:

> **A highlight explains an already-valid interaction. It never creates interaction truth.**

System 24 consumes shared `CONTACT_FORWARD` reach. System 23 current visibility gates player-facing highlights. Candidate discovery remains bounded to tiny reachable OBJECT occupancy sets.

---

## Roadmap Phase 1B / System 30 — COMPLETE

Canonical design: `SYSTEM_DESIGNS/30_ITEM_FRESHNESS_SPOILAGE.md`

Core rule:

> **Food ages because authoritative world time passes through its storage environment. No item gets a timer.**

Current implementation uses explicit perishable semantic profiles, sparse per-instance records, analytic FRESH/AGING/STALE/SPOILED derivation, logical scenario-origin aging for virgin world loot and an ambient exposure provider. Refrigeration remains inactive until real Phase-3 power/appliance truth exists. Eating/drinking/health consequences remain Phase 4.

---

## Roadmap Phase 1C / System 31 — COMPLETE

Canonical design: `SYSTEM_DESIGNS/31_SEMANTIC_UI_ICONS.md`

Core rule:

> **UI icons visualize existing semantic truth. They never define item identity, utility, freshness, or action legality.**

One shared Node-free/cached semantic icon catalog supplies the current item/shell UI vocabulary. Unknown future semantics fail visibly with an unknown glyph while text remains usable. No icon identity is stored in gameplay state.

---

## Roadmap Phase 1D / System 07B — COMPLETE + CI VERIFIED

Canonical design: `SYSTEM_DESIGNS/07B_LARGE_MULTI_CELL_VISUAL_GEOMETRY.md`

Verified executable/workflow head: `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`.

Core rule:

> **Physical footprint answers where the object is. Visual geometry answers how that object is drawn. Neither may silently redefine the other.**

Implemented result:

- Node-free visual descriptors with authored span + pivot;
- one cached stable-entity visual plan shared by base and foreground passes;
- exact legacy 1x1 fallback for unmapped props;
- System-07A orientation remains authoritative presentation facing;
- z20 base -> z30 actors -> z35 optional canopy/overhang -> z40 physical lighting;
- bounded two-cell visual-overhang discovery halo with visual-AABB culling;
- dedicated large-tree and traffic-light base/foreground assets;
- no collision/reach/LOS/WHEN/save/streaming truth changes;
- no per-object Nodes/timers/process loops or whole-world scans;
- broader two-ring System-27 presentation bloom derived only from real emitter truth.

All **18 required exact-head contexts** are green on the verified head, including `verify/system07b-large-visual-geometry`, `verify/performance-architecture`, and `verify/pages-deploy`.

Human visual acceptance for the new 07B art/glow is not separately recorded yet.

---

## Active work — Roadmap Phase 1E

### Content Expansion + Integration — DESCRIBED, AWAITING APPROVAL

Canonical draft: `SYSTEM_DESIGNS/PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`.

Core rule:

> **Content extends the system that already owns its truth. Integration does not create a second owner.**

Phase 1E is explicitly **not System 32**. It is a bounded integration phase across existing owners.

Candidate implementation order:

1. **1E-1 World clutter + location identity** — enrich existing System-19 building-profile dressing and System-20 exterior/environment content; deploy 07B large trees/traffic furniture through ordinary generated contexts while preserving access/circulation/roads/water.
2. **1E-2 Mundane loot + perishable breadth** — expand System-24 item/container content; every added item gets System-13D weight + explicit System-31 icon, and every added perishable gets System-30 freshness.
3. **1E-3 Integration/readability/performance acceptance** — tune generated identity, real System-29 highlight density, icon/freshness readability, 07B layering/glow and phone/Safari performance.

No Crafting, Power/Refrigeration, nutrition/Health, Skills, Vehicles, combat or AI behavior may be faked inside 1E.

The next lifecycle gate is **APPROVE**. No 1E runtime/content implementation is authorized yet.

---

## Relevant ownership boundaries

- 00D owns global geography, settlement/road/hydrology/infrastructure truth and cross-area world context.
- 00F owns materialization-source orchestration and technical activation, not world identity.
- 19 owns local building grammar/profile content and physical building plans.
- 20 owns bounded local roads/parcels/access/outdoor/environment content.
- 04 owns world art selection; 07/07A/07B own prop presentation/orientation/large visual geometry.
- 00A/00B remain authoritative for physical footprint, placement and stable entity identity.
- 11 owns containment; 12 owns timed physical item transitions; 13D owns physical weight.
- 24 owns what virgin loot exists and keeps **loot exists before you search for it**.
- 25 interprets authoritative WHEN ticks as simulation time.
- 27 owns physical illumination and emitter truth.
- 29 owns neutral reach/offer presentation but not mechanic capability.
- 30 owns freshness records/derivation, not refrigeration or nutrition.
- 31 owns icon presentation only.
- Phase 2 owns Crafting; Phase 3 Power/Water/Refrigeration; Phase 4 nutrition/health consequences; Phase 6 final Skills; Phase 7 Vehicles; Phase 8 AI/combat/outbreak.

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
- `verify/system07b-large-visual-geometry`
- `verify/performance-architecture`
- `verify/pages-deploy`

All **18 required contexts** are green on current verified executable/workflow head `d5e33b43fb732835b4a996ae4bec3a562cfa75f3`.

If Phase 1E is approved and implemented, its proposed dedicated `verify/phase1e-content-integration` context becomes an additional required context for that implementation.
