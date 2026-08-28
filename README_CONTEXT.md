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

Foundation and gameplay through **System 31**, plus **System 07B** and **Roadmap Phase 1E Content Expansion + Integration**, are implemented.

Current major capabilities include:

- authoritative WHERE / WHAT / WHEN foundations;
- collision, movement, actor locomotion, stance, carrying and timed item transfer;
- complete-island global/local generation and technical streaming;
- 24 System-19 building archetypes and ten System-20 local-area profiles;
- deterministic Phase-1E location dressing across the 18 baseline one-story building profiles, capped at two added accents per building while the six protected reference buildings remain untouched;
- persistent searchable world loot with a 97-semantic physical item catalog and broader location-aware residential/retail/medical/hardware/industrial/farm/office/civic stock;
- world time/daylight;
- spatial sound/hearing;
- physical lighting, visibility and shadows;
- Weather/atmosphere/lightning;
- perception / fog memory;
- real interaction affordance/reach highlights;
- analytic item freshness/spoilage with 10 explicit perishable semantics;
- semantic inventory/menu icons with explicit mappings for all 97 current loot semantics plus the three shell controls;
- large/multi-cell prop visual geometry with actor-overhang layering, now bound to the real generated large-tree and traffic-light prop semantics;
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
16. Phase-1E content extends existing owners; content integration never creates a second owner or placeholder Phase-2+ mechanics.

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

## Roadmap Phase 1E — COMPLETE + CI VERIFIED

Canonical design: `SYSTEM_DESIGNS/PHASE_1E_CONTENT_EXPANSION_INTEGRATION.md`.

Verified executable head: `6ad923d172f5a5434f94a7fdcc15da640a60a240`.

Core rule:

> **Content extends the system that already owns its truth. Integration does not create a second owner.**

Implemented result:

1. **1E-1 World clutter + location identity** — the 18 baseline one-story System-19 profiles receive deterministic program-appropriate accent dressing through one shared generation helper, capped at two added accents per building. Protected historical trailer/farmhouse/compact-laundry/gas-station/diner archetypes remain outside the new dresser. Existing System-20 outdoor generation remains authoritative; its already-generated `prop.deciduous_large` and `prop.traffic_light` semantics now consume the approved 07B large-object presentation in ordinary world content, while historical 07B fixture aliases remain compatible.
2. **1E-2 Mundane loot + perishable breadth** — System-24 item truth expands to 97 physical semantics with positive System-13D weights, broader location-aware container profiles including school/church/police/fire stock, 10 explicit System-30 perishables, and intentional System-31 icon coverage for all 97 item semantics.
3. **1E-3 Integration/readability/performance gate** — added permanent `verify/phase1e-content-integration`, bounded building accents to prevent clutter creep, preserved existing System-20/24/29/30/31/07B/performance contracts, and kept future Crafting/Power/nutrition/Skills/Vehicles/AI behavior absent rather than faked.

All **19 required exact-head contexts** are green on `6ad923d172f5a5434f94a7fdcc15da640a60a240`, including the new `verify/phase1e-content-integration` and `verify/pages-deploy`.

Automated Phase-1E implementation is complete. A separate human visual/readability playtest of the richer content is still useful and is **not** being claimed by CI.

---

## Active work — Roadmap Phase 2 / System 32

### Crafting / Material Transformation — DESCRIBED, AWAITING APPROVAL

Canonical design: `SYSTEM_DESIGNS/32_CRAFTING_MATERIAL_TRANSFORMATION.md`.

Core rule:

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

Candidate 001 is one System-32 owner with three bounded implementation slices:

1. **2A Recipe + plan foundation** — exact-semantic recipes, explicit workstation capabilities, deterministic ingredient/tool selection from real personal possession, known weight/icon/carry validation, and a small material-reclamation/assembly vocabulary.
2. **2B Timed physical transformation** — one positive-duration CANCELABLE `crafting.craft_recipe` WHEN action, final commit revalidation, real input entity removal, deterministic real output creation, actor-root containment, hard carry-limit enforcement and a bounded mutation/compensation journal.
3. **2C Workstation + player integration** — explicit heavy-workbench capability, shared System-29 `CONTACT_FORWARD` CRAFT offer, phone/Safari-first CRAFT modal and complete-island integration/playtest.

Important Candidate-001 restrictions:

- ingredients/tools must already be personally possessed; no magic nearby floor/container auto-pull;
- physical counts are stable entity counts, never a stack/resource wallet;
- tools are real non-consumed requirements; no fake durability exists yet;
- consumed ingredients cannot be enrolled item-containers and cannot be perishable in Candidate 001;
- outputs are ordinary new persistent WHAT `item.*` entities contained by the actor root;
- no Construction/Repair/Durability, Cooking/Nutrition, Power/Water, Skills/quality/XP, Vehicles, Combat/ammunition or AI behavior is absorbed into Crafting.

If implemented, `verify/system32-crafting` becomes a twentieth permanent exact-head context.

The next lifecycle gate is **APPROVE or revise System 32 Candidate 001**. No Phase-2 runtime implementation is authorized yet.

---

## Relevant ownership boundaries

- 00D owns global geography, settlement/road/hydrology/infrastructure truth and cross-area world context.
- 00F owns materialization-source orchestration and technical activation, not world identity.
- 19 owns local building grammar/profile content and physical building plans.
- 20 owns bounded local roads/parcels/access/outdoor/environment content.
- 04 owns world art selection; 07/07A/07B own prop presentation/orientation/large visual geometry.
- 00A/00B remain authoritative for physical footprint, placement and stable entity identity.
- 09 owns hand assignment; 11 owns containment; 12 owns ordinary timed physical item transitions; 13D owns physical weight; 13E owns derived carried mass/carry ceilings.
- 24 owns what virgin loot exists and keeps **loot exists before you search for it**.
- 25 interprets authoritative WHEN ticks as simulation time.
- 27 owns physical illumination and emitter truth.
- 29 owns neutral reach/offer presentation but not mechanic capability.
- 30 owns freshness records/derivation, not refrigeration, cooking or nutrition.
- 31 owns icon presentation only.
- 32 is the proposed Phase-2 owner of recipe-driven physical item transformation; it does not own later construction/repair/cooking/utilities/skills/vehicles/combat.
- Phase 3 owns Power/Water/Refrigeration; Phase 4 nutrition/health consequences; Phase 6 final Skills; Phase 7 Vehicles; Phase 8 AI/combat/outbreak.

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
- `verify/phase1e-content-integration`
- `verify/performance-architecture`
- `verify/pages-deploy`

All **19 current required contexts** are green on verified executable head `6ad923d172f5a5434f94a7fdcc15da640a60a240`.

System-32 implementation would add proposed `verify/system32-crafting` as required context 20; the design-only Phase-2 work does not change the executable stack.