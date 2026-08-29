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
- Central local-area seed derives from world seed + site identity rather than the historical standalone critique seed.
- System 00F materializes settlement, hydrology and island-surface logical sources; technical streaming remains 128x128 with active radius 1.
- Natural ecology derives from shared world seed + absolute global cell so logical source boundaries do not restart environmental identity.
- Survivor spawn remains on inherited pavement beside the central crossroads rather than the diner entrance.

### Compact-island / legacy seam cleanup — COMPLETE + HUMAN ACCEPTED

The broad planner repair `918f1dbd7b033fa179522a112b1507d9a2c63890` remains rejected. It passed automated CI but produced a severe user-visible world regression and was rolled back by `f6a06add3dfd212c0c29b343d24a8f7d28a89bca`.

The accepted focused repair is:

`282864f242ba2a5c3df0519591e31990372c4aed` — `Repair island local-window overlap without moving world layout`

It leaves global settlement layout intact and deterministically adapts only an overlapping inherited island-local window while preserving the linked settlement center, island/land/river constraints and accepted-site non-overlap.

Human play accepted the recovered island lineage. Future generated-world layout changes still require human play acceptance in addition to green CI.

---

## Current implemented stack

Roadmap **Phase 1 and Phase 2 are complete**. Phase 3 / System 33 Candidate 001 is now **implemented and automatically verified; human acceptance is pending**.

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
- System 32 Crafting / Material Transformation;
- System 33 persistent power/water utility runtime, powered pump dependency, refrigeration service and truthful fixed-light integration.

### Phase 2 / System 32 Crafting

Canonical design: `SYSTEM_DESIGNS/32_CRAFTING_MATERIAL_TRANSFORMATION.md`.

Status: **IMPLEMENTED + CI VERIFIED — Candidate 001 / Roadmap Phase 2 complete**.

Verified executable: `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

Crafting owns recipe-driven physical item transformation. It does not own Construction/Repair/Durability, Cooking/Nutrition, Power/Water, Skills/quality/XP, Vehicles, Combat/ammunition or AI.

### Phase 3 / System 33 Power + Water

Canonical design: `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`.

Status: **IMPLEMENTED + AUTOMATED VERIFIED — Candidate 001; HUMAN RETEST PENDING**.

Verified executable after truthful-lighting repair:

`ec7be83146d62055a5d2d4b1233eb7cc50cea630`

Exact-head contexts include `verify/system33-power-water`, `verify/system33-lighting-truth`, `verify/system27-physical-lighting`, `verify/performance-architecture`, and successful Pages deployment.

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

Candidate 001 implements:

1. persistent three-tier power runtime state materialized from existing 00D4 planning truth;
2. persistent potable-water runtime state from 00D5 planning truth, including electrically powered pump dependency and rural well service where planned;
3. persistent appliance/switch/service truth and powered refrigerator cold-storage integration for System 30;
4. real fixed-light integration into System 27 through actual WHAT fixture entities and their actual placements;
5. event/revision-driven service caches and typed damage/disabled mutation seams;
6. truthful DEV controls that mutate canonical utility state rather than a parallel demo model.

The first visible System-33 lighting integration was **human rejected** because it still power-gated legacy demo light coordinates and passed through an always-on fake player flashlight. That source boundary was replaced in `2267a7ea1b0fcd76fab90ddf23219c7e1ae70d43`, and stale regression contracts were aligned in verified executable `ec7be83146d62055a5d2d4b1233eb7cc50cea630`.

Current truthful lighting behavior:

- fixed emitters originate from real persistent WHAT fixture entities such as traffic/street lights, lamps and neon fixtures;
- emitter position/facing comes from the fixture's real `WorldPlacement`;
- fixed emitters are present only when the fixture's System-33 appliance/service truth is powered and operational;
- the player has **no flashlight beam by default**;
- a flashlight beam exists only when a real WHAT entity with semantic type `item.tool.flashlight` is assigned to a real hand slot;
- portable battery depletion/toggle simulation remains deferred rather than faked;
- the legacy `DemoLightingSourceAdapter` is inert and emits zero gameplay light sources.

**System 33 / Phase 3 is not human accepted until the repaired executable is browser-playtested.**

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
18. Generated-world behavior/layout changes require human play acceptance in addition to green CI.
19. A canonical startup smoke must prove a usable visible field and non-black physical-light presentation, not merely that the scene booted.
20. Utility planning truth and runtime service truth are separate owners: 00D says where infrastructure exists; System 33 owns current service state.
21. A visible powered fixture must be a real WHAT fixture at its real placement; no demo coordinate may create canonical light.
22. Player-facing changes wake physical lighting only when a real moving/equipped light source actually changes.

---

## Performance architecture

Protected direction:

- event-driven/cache-oriented invalidation;
- no recurring whole-world scans;
- no per-cell/per-item/per-utility-component Nodes or timers;
- no frame-driven simulation;
- bounded local queries and shared cached plans;
- persistence-backed streaming eviction remains evidence-driven future work only.

### Player-action responsiveness + black-screen recovery — HUMAN ACCEPTED

The canonical `PlayerActionController` resolves accepted actions through a one-due-tick-batch-per-render-frame pump. Input is accepted only at WHEN's real decision pause and stays locked until that pause returns.

Executable `6e1298da36e9216139f404696275280fcb944033` introduced camera-cropped physical-light presentation and a revision-cached bounded System-23 LOS field. Automated checks passed, but human browser play reported a completely black game. That visibility optimization stack remains **rejected**.

Recovery executable `1f65bff312853a44858201b57d9df2e26ee64f80` restored the human-good full 80x96 physical-light presentation path and prior stateless LOS query while preserving decision-pause input locking, one-batch-per-frame action resolution and coalesced settled updates. Human browser play accepted this recovery.

System-33 lighting truth work deliberately did **not** reintroduce the rejected camera crop or LOS cache. With no equipped flashlight, a facing-only turn now also proves the physical-light solver remains asleep.

---

## Relevant ownership boundaries

- 00D owns global geography, settlement/road/hydrology/infrastructure planning truth and cross-area world context.
- 00D4/00D5 own planned electrical/potable-water topology, not current service availability.
- 00F owns materialization-source orchestration and technical activation, not world identity.
- 19 owns local building grammar/profile content and physical building plans.
- 20 owns bounded local roads/parcels/access/outdoor/environment content.
- 04 owns world art selection; 07/07A/07B own prop presentation/orientation/large visual geometry.
- 00A/00B remain authoritative for physical footprint, placement and stable entity identity.
- 09 owns hand assignment; 11 owns containment; 12 owns ordinary timed physical item transitions; 13D owns physical weight; 13E owns derived carried mass/carry ceilings.
- 24 owns virgin loot existence and keeps **loot exists before you search for it**.
- 25 interprets authoritative WHEN ticks as simulation time.
- 27 owns physical illumination math and active emitter truth; System 33 supplies truthful fixed-powered/equipped source inputs at the seam.
- 29 owns neutral reach/offer composition but not mechanic capability.
- 30 owns freshness records/derivation; System 33 supplies cold-storage availability without taking freshness ownership.
- 31 owns icon presentation only.
- 32 owns recipe-driven physical item transformation.
- 33 owns persistent power/water runtime service state, appliance power truth, pump-power dependency and utility-consumer service queries.
- Phase 4 owns nutrition/thirst/health consequences; Phase 6 final Skills; Phase 7 Vehicles; Phase 8 AI/combat/outbreak.

---

## Current next lifecycle gate

**System 33 / Roadmap Phase 3 — HUMAN VERIFY repaired Candidate 001.**

Executable: `ec7be83146d62055a5d2d4b1233eb7cc50cea630`.

Human retest should confirm:

1. spawn has no phantom flashlight beam when no flashlight is actually equipped;
2. visible real fixed fixtures create light at their own world positions;
3. `LOCAL PWR` removes/restores those real fixed lights without affecting unrelated service;
4. normal turning/movement remains responsive and the black-screen regression does not return;
5. water/pump/refrigeration DEV inspection still reflects canonical System-33 truth.

Do not advance Phase 3 to HUMAN ACCEPTED merely because CI is green.
