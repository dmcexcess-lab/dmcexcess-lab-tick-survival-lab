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

Accepted focused repair:

`282864f242ba2a5c3df0519591e31990372c4aed` — `Repair island local-window overlap without moving world layout`

It leaves global settlement layout intact and adapts only an overlapping inherited island-local window while preserving settlement-center, island/land/river and accepted-site constraints. Human play accepted this recovered island lineage.

---

## Current implemented stack

Roadmap **Phase 1 and Phase 2 are complete**. Phase 3 / System 33 through Stage B physical power distribution is **implemented and exact-head automatically verified; final human acceptance is pending**.

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
- System 33 persistent power/water utility runtime, powered pump dependency, refrigeration service and truthful fixed/portable light integration;
- persistent powered non-bloom room lighting for generated interiors;
- Stage B physical electrical distribution with stable wire/support condition identity, analytic wear, event-driven damage/repair and downstream service consequences.

### Phase 2 / System 32 Crafting

Canonical design: `SYSTEM_DESIGNS/32_CRAFTING_MATERIAL_TRANSFORMATION.md`.

Status: **IMPLEMENTED + CI VERIFIED — Candidate 001 / Roadmap Phase 2 complete**.

Verified executable: `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

### Phase 3 / System 33 Power + Water

Canonical designs:

- `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`
- `SYSTEM_DESIGNS/33B_POWER_PHYSICAL_NETWORK_CONDITION.md`

Status: **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED — Candidate 001 + Stage B physical power network; HUMAN PLAYTEST PENDING**.

Current verified executable:

`7ddee8df0e638cbe14897d83632b62513d5fc574`

All 22 published exact-head contexts are green, including `verify/system33-power-water`, `verify/system33-lighting-truth`, `verify/system27-physical-lighting`, `verify/system25-world-time-light`, `verify/system00d-global-world`, `verify/system00f-streaming-materialization`, Systems 19/20/23/28/30/32, `verify/performance-architecture`, and successful Pages deployment.

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

Candidate 001 implements persistent three-tier power and potable-water state from 00D4/00D5 planning truth, powered pump dependency, rural wells where planned, persistent appliance state, powered refrigerator cold-storage availability for System 30, typed utility damage/disabled seams and event/revision-driven service caches.

### Stage B physical power-network behavior

Stage B extends the existing service runtime rather than creating parallel power truth.

- 00D4 physical feeder edges record deterministic `service_settlement_ids`, resolving downstream causality once during planning.
- physical wire spans receive stable `power.asset.span.*` condition IDs; support poles keep their real persistent WHAT IDs;
- `UtilityNetworkConditionStore` derives condition analytically from authoritative time/event anchors and is intended as the shared substrate for future utility-asset condition where appropriate;
- `UtilityPowerNetworkRuntime` maps physical assets to real System-33 services, exposes direct damage/repair seams and translates actual asset failure into existing System-33 link state;
- ordinary time advancement checks only the earliest predicted threshold in one sorted failure schedule; it never loops every line or every elapsed day;
- direct damage/repair reevaluates only services mapped to the changed asset;
- the physical-network regression proves a settlement-specific span can black out its mapped downstream service while a sibling service remains energized, then repair restores the affected service;
- failed/de-energized cables remain visible because rendering owns physical presentation, not energized truth;
- fake regional-ingress/substation transformer clusters were removed; final source/substation tactical facilities remain future facility-generation work;
- `PowerLinePresentationRenderer` now ignores unrelated world mutations via a cached endpoint-ID lookup.

Current mechanical repair requirements are a low-tier foundation seam only: Electrical 2 plus one material unit for a span or two for a support. Final player-facing repair action duration, tool/inventory consumption and skill balance remain Phase-6 work and must call the existing seam.

### Current truthful lighting behavior

The first visible System-33 lighting integration was human-rejected because it power-gated legacy demo coordinates and passed through an always-on fake player flashlight. That source boundary was replaced and the user subsequently reported the repaired source behavior looked good.

Current rules:

- fixed emitters originate from real persistent WHAT fixture entities at their real `WorldPlacement`;
- fixed emitters exist only while their System-33 appliance/service truth is powered and operational;
- the player has **no flashlight beam by default**;
- a player flashlight beam exists only when a real WHAT `item.tool.flashlight` is assigned to a real System-09 hand slot;
- portable battery depletion/toggle simulation remains deferred rather than faked;
- `DemoLightingSourceAdapter` is inert and emits zero gameplay lights;
- every generated System-19 room now materializes one invisible persistent `fixture.room_light` entity on a real room cell;
- room fixtures bind to the real power service for their cell and feed System 27 while powered;
- `light.room_ambient.candidate001` raises real physical/local luminance but has `presentation_glow_scale = 0.0`, so rooms brighten without a glowing lamp/bloom graphic;
- ordinary streetlights, lamps, neon and equipped flashlights retain visible glow behavior;
- `LOCAL PWR` uses canonical utility mutation and should remove/restore affected room emitters on its targeted branch.

**System 33 / Phase 3 remains human-playtest pending until Stage B plus indoor power on/off, water/pump and refrigeration behavior are accepted in browser play.**

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
15. Art never creates light. System-27 emitter/illumination truth drives light presentation.
16. Content extends existing owners; integration never creates a second owner or placeholder future mechanics.
17. Validators fail closed. A legal-seed failure is a generation defect to repair, not a reason to weaken the validator.
18. Generated-world layout/behavior changes require human play acceptance in addition to green CI.
19. Canonical startup smoke must prove a usable visible field and non-black physical-light presentation, not merely scene boot.
20. Utility planning truth and runtime service truth are separate owners: 00D says where infrastructure exists; System 33 owns current service state.
21. A powered fixed source must correspond to real persistent WHAT identity/placement; no demo coordinate may create canonical light.
22. Player-facing changes wake physical lighting only when a real moving/equipped light source changes.
23. A light may affect physical luminance without additive bloom; presentation glow is an explicit profile property and never the authority for illumination.
24. Physical utility condition is analytic from authoritative time/event anchors. No pole/wire gets a timer, recurring update or per-day catch-up loop.
25. A failed/de-energized cable remains physically present; presentation of infrastructure existence never becomes service authority.

---

## Performance architecture

Protected direction:

- event-driven/cache-oriented invalidation;
- no recurring whole-world scans;
- no per-cell/per-item/per-utility-component/per-room simulation Nodes or timers;
- no frame-driven simulation;
- bounded local queries and shared cached plans;
- analytic utility-asset condition with one minimal next-threshold schedule per network owner instead of per-asset time events;
- persistence-backed streaming eviction remains evidence-driven future work only.

### Player-action responsiveness + black-screen recovery — HUMAN ACCEPTED

The canonical `PlayerActionController` resolves accepted actions through a one-due-tick-batch-per-render-frame pump. Input is accepted only at WHEN's real decision pause and stays locked until that pause returns.

Executable `6e1298da36e9216139f404696275280fcb944033` introduced camera-cropped physical-light presentation and a revision-cached System-23 LOS field. Automated checks passed, but human browser play reported a completely black game. That optimization stack remains **rejected**.

Recovery executable `1f65bff312853a44858201b57d9df2e26ee64f80` restored the human-good full 80x96 physical-light presentation path and stateless LOS query while preserving input responsiveness. Human browser play accepted this recovery.

System-33 fixed/equipped/room lighting and Stage B physical distribution deliberately preserve that renderer/LOS/input lineage. No camera crop or LOS cache was reintroduced.

---

## Relevant ownership boundaries

- 00D owns global geography, settlement/road/hydrology/infrastructure planning truth and cross-area world context.
- 00D4/00D5 own planned electrical/potable-water topology, not current service availability. 00D4 also records deterministic downstream settlement mapping for physical feeder edges.
- 00F owns materialization-source orchestration and technical activation, not world identity.
- 19 owns local building grammar/profile content and room plans; room-light materialization derives persistent fixture identity from those existing room sets.
- 20 owns bounded local roads/parcels/access/outdoor/environment content.
- 04 owns world art selection; 07/07A/07B own prop presentation/orientation/large visual geometry.
- 00A/00B own physical placement/stable persistent entity truth.
- 09 owns hand assignment; 11 containment; 12 timed physical item transitions; 13D weight; 13E carry.
- 24 owns virgin loot existence.
- 25 interprets authoritative WHEN ticks as simulation time.
- 27 owns physical illumination/emitter math and presentation-light outputs; System 33 supplies truthful powered source availability.
- 29 owns neutral reach/offer composition but not mechanic capability.
- 30 owns freshness records/derivation; System 33 supplies cold-storage availability.
- 31 owns icon presentation only.
- 32 owns recipe-driven physical item transformation.
- 33 owns persistent power/water runtime state, appliance service truth, pump-power dependency, physical electrical-distribution condition/consequence mapping and utility-consumer service queries.
- Phase 4 owns nutrition/thirst/health consequences; Phase 6 Skills/final repair actions; Phase 7 Vehicles; Phase 8 AI/combat/outbreak.

---

## Current next lifecycle gate

**System 33 / Roadmap Phase 3 — HUMAN VERIFY Stage B physical power network plus current utility behavior.**

Executable: `7ddee8df0e638cbe14897d83632b62513d5fc574`.

Human retest should confirm:

1. generated house rooms are visibly brighter when their service is powered, without a glowing room-light graphic;
2. `LOCAL PWR` removes/restores the affected indoor illumination;
3. walls/doors continue to shape physical light normally and ordinary visible light sources still glow;
4. no phantom flashlight exists when none is equipped;
5. overhead wires/poles remain visually stable and support placement remains correct;
6. turning/movement remains responsive and the black-screen regression does not return;
7. ordinary world-time advancement does not develop recurring utility hitching;
8. water/pump/refrigeration DEV inspection still reflects canonical System-33 truth.

Do not advance Phase 3 / Stage B to HUMAN ACCEPTED merely because CI is green.
