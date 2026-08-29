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
- System 00D `temperate.island.region` is v3 over the protected rural-v6 planning skeleton.
- Five connected site identities remain: one `rural.crossroads`, one `smalltown.center`, three `rural.scattered` hamlets.
- Central local-area seed derives from world seed + site identity rather than reusing the historical standalone critique seed.
- The playable island uses the compact island protected-cross/spacing configuration rather than the historical 640-cell regional stress-fixture cross.
- System 00F materializes settlement, hydrology and island-surface logical sources; technical streaming remains 128x128 with active radius 1.
- Natural ecology derives from shared world seed + absolute global cell so logical source boundaries do not restart environmental identity.
- Survivor spawn remains on inherited pavement beside the central crossroads rather than the diner entrance.

### Compact-island / legacy seam cleanup — REOPENED

The attempted planner repair `918f1dbd7b033fa179522a112b1507d9a2c63890` is **not an accepted executable**.

What happened:

1. CI isolated an alternate-seed System-00D failure: `island_base_site_overlap:area.smalltown.center.001`.
2. `918f1db...` replaced the historical 160-cell center-distance candidate rejection with exact 256x256 site-rectangle overlap rejection.
3. Automated exact-head CI went green, including System 00D and Pages.
4. Human play immediately reported the deployed game as completely broken.
5. The planner change was therefore reverted.

Current restored runtime executable:

`f6a06add3dfd212c0c29b343d24a8f7d28a89bca`

That commit restores `GlobalSettlementPlanner.gd` to the pre-regression implementation from `ba706f18017d4d72b950f18d3e988ce75592f0a6`. Its Pages build/deploy completed successfully.

Expected current verification state:

- the live game is back on the pre-regression planner;
- System 00D's strict `Legacy Crossroads Is Not Embedded In Island` alternate-seed seam is red again;
- that known red seam is intentionally reopened rather than hidden by a gameplay-breaking planner change;
- Crafting and unrelated gameplay systems were not reverted.

**Do not cite `918f1db...` as a completed cleanup head.**

Before another live planner change, reproduce the overlap in a focused planner fixture, define the intended settlement-layout invariants beyond simple non-overlap, verify the smallest deterministic repair, then human-play the island before closure.

---

## Current implemented stack

Roadmap **Phase 1 and Phase 2 are implementation-complete**.

Major implemented capabilities include:

- authoritative WHERE / WHAT / WHEN foundations;
- collision, movement, locomotion, stance, carrying and timed item transfer;
- complete-island global/local generation and technical streaming;
- System-19 building generation and System-20 local-area morphology;
- deterministic location dressing and world clutter;
- persistent searchable world loot;
- world time/daylight;
- spatial sound/hearing;
- physical lighting, visibility and shadows;
- Weather/atmosphere/lightning;
- perception / fog memory;
- real interaction affordance/reach highlights;
- analytic item freshness/spoilage with no per-item timers;
- semantic inventory/menu icons;
- large/multi-cell prop presentation geometry;
- System 32 Crafting / Material Transformation.

### Phase 1E content integration

Verified executable: `6ad923d172f5a5434f94a7fdcc15da640a60a240`.

Phase 1E broadened world dressing, location-aware loot, perishables and icon coverage while extending existing owners rather than creating duplicate truth.

### Phase 2 / System 32 Crafting

Canonical design: `SYSTEM_DESIGNS/32_CRAFTING_MATERIAL_TRANSFORMATION.md`.

Status: **IMPLEMENTED + CI VERIFIED — Candidate 001 / Roadmap Phase 2 complete**.

Verified executable: `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.

Exact-head context: `verify/system32-crafting`.

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

Crafting owns recipe-driven physical item transformation. It does not own Construction/Repair/Durability, Cooking/Nutrition, Power/Water, Skills/quality/XP, Vehicles, Combat/ammunition or AI.

---

## Important current rules

1. Generation creates virgin truth once; WHAT + typed mechanic stores own current reality afterward.
2. Technical streaming activation is not world existence.
3. Art/rendering is presentation, never physics/simulation authority.
4. Phone/Safari is first-class.
5. Sound is physical; hearing is an estimate.
6. Light is physical; vision is observer-specific.
7. Weather is simulation truth; Weather animation is presentation.
8. Fatigue is the stamina/endurance concept; there is no parallel stamina meter.
9. Interaction highlights explain already-valid actions; they never create action truth.
10. Expensive consumers wake only for domains/completed batches they actually depend on.
11. Food freshness is derived analytically from authoritative time/exposure; no item gets a spoilage timer.
12. UI icons visualize semantic truth but never define identity, utility, freshness or action legality.
13. Logical area/streaming boundaries must not reset world-space environmental identity.
14. Physical footprints answer where objects are; presentation geometry may be larger but never redefines physical truth.
15. Bright art does not create light. System-27 emitter truth remains the only source of physical-light presentation glow.
16. Content extends existing owners; integration never creates a second owner or placeholder future mechanics.
17. Validators fail closed. A legal-seed failure is a generation defect to repair, not a reason to weaken the validator.
18. **Generated-world behavior/layout changes require human play acceptance in addition to green CI.** The `918f1db...` regression proved automated checks alone are insufficient here.

---

## Performance architecture

Protected direction:

- event-driven/cache-oriented invalidation;
- no recurring whole-world scans;
- no per-cell/per-item Nodes or timers;
- no frame-driven simulation;
- bounded local queries and shared cached plans;
- persistence-backed streaming eviction remains evidence-driven future work only.

### Player-action responsiveness repair — awaiting human acceptance

The playable controller now resolves accepted player actions through a one-due-tick-batch-per-render-frame pump instead of blocking inside the input callback. Controls are busy-gated and stale buffered input is dropped, preventing long post-stall movement queues and overshoot.

The DEV flashlight now invalidates presentation for facing-only turns, ignores unrelated streaming mutations, and skips duplicate same-revision light-map uploads.

Automated acceptance includes parser/import, canonical demo/player shell, lighting/performance regressions, canonical startup and the permanent same-window input-backlog smoke. Human browser play remains the final acceptance gate for the reported spawn-step stall and feel.

---

## Relevant ownership boundaries

- 00D owns global geography, settlement/road/hydrology/infrastructure planning truth and cross-area world context.
- 00F owns materialization-source orchestration and technical activation, not world identity.
- 19 owns local building grammar/profile content and physical building plans.
- 20 owns bounded local roads/parcels/access/outdoor/environment content.
- 04 owns world art selection; 07/07A/07B own prop presentation/orientation/large visual geometry.
- 00A/00B remain authoritative for physical footprint, placement and stable entity identity.
- 09 owns hand assignment; 11 owns containment; 12 owns ordinary timed physical item transitions; 13D owns physical weight; 13E owns derived carried mass/carry ceilings.
- 24 owns virgin loot existence and keeps **loot exists before you search for it**.
- 25 interprets authoritative WHEN ticks as simulation time.
- 27 owns physical illumination and emitter truth.
- 29 owns neutral reach/offer composition but not mechanic capability.
- 30 owns freshness records/derivation, not refrigeration, cooking or nutrition.
- 31 owns icon presentation only.
- 32 owns recipe-driven physical item transformation, not later construction/repair/cooking/utilities/skills/vehicles/combat.
- Phase 3 owns Power/Water/Refrigeration; Phase 4 nutrition/health consequences; Phase 6 final Skills; Phase 7 Vehicles; Phase 8 AI/combat/outbreak.

---

## Current next lifecycle gate

**Resolve and human-accept the reopened compact-island/world-seam cleanup.**

Do not make another broad live planner change merely to turn System 00D green. Build the focused reproduction first and preserve the current playable layout while fixing the legal-seed defect.

After cleanup is accepted, the next gameplay lifecycle gate is:

**Roadmap Phase 3 — Power and Water: DESCRIBE.**

Do **not** implement Phase-3 runtime code until its bounded design is approved.
