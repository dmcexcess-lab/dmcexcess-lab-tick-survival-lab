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

### Compact-island / legacy seam cleanup — COMPLETE + HUMAN ACCEPTED

The broad planner repair `918f1dbd7b033fa179522a112b1507d9a2c63890` remains explicitly rejected. It replaced global settlement candidate screening with exact rectangle-overlap rejection, passed automated CI, and then produced a severe user-visible world regression. It was rolled back by `f6a06add3dfd212c0c29b343d24a8f7d28a89bca`.

The accepted repair is the later focused island-local adaptation:

`282864f242ba2a5c3df0519591e31990372c4aed` — `Repair island local-window overlap without moving world layout`

That repair leaves the global settlement planner/layout intact and, when an inherited island base-site window overlaps another accepted site, searches a bounded deterministic local shift that:

- retains the site's linked settlement center;
- stays inside island bounds/on land;
- remains clear of protected rivers;
- does not overlap already accepted sites;
- moves no farther than one site dimension;
- fails closed when no legal local adaptation exists.

Human play of the recovered current executable lineage has now been accepted to move forward. The black-screen regression that temporarily prevented reliable visual verification is also fixed. Therefore the world-generation cleanup gate is closed.

**Do not cite `918f1db...` as accepted cleanup. `282864f...` is the focused repair in the accepted lineage.**

Future generated-world layout changes still require human play acceptance in addition to green CI.

---

## Current implemented stack

Roadmap **Phase 1 and Phase 2 are implementation-complete**. Phase 3 is now described but not implemented.

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

### Phase 3 / System 33 Power + Water

Canonical draft: `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`.

Status: **DESCRIBED — explicit approval required before implementation**.

> **Planning says where utility topology exists. System 33 owns whether that topology currently provides service. Consumers query service; they never infer it from art, brightness or UI state.**

Candidate 001, if approved, is split into:

1. 33A utility-state foundation/materialization from existing 00D4/00D5 planning truth;
2. 33B causal three-tier power service + real fixed-light integration into System 27;
3. 33C causal potable-water service + rural wells + real pump-to-power dependency;
4. 33D powered refrigerator cold-storage availability for System 30.

It explicitly excludes Phase-4 thirst/health consequences, fake liquid inventory, random outages, detailed circuit/load/pressure simulation, and portable battery/fuel simulation.

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
20. Utility planning truth and runtime utility service truth are separate owners: 00D says where infrastructure exists; System 33, once approved/implemented, will own current service state.

---

## Performance architecture

Protected direction:

- event-driven/cache-oriented invalidation;
- no recurring whole-world scans;
- no per-cell/per-item Nodes or timers;
- no frame-driven simulation;
- bounded local queries and shared cached plans;
- persistence-backed streaming eviction remains evidence-driven future work only.

### Player-action responsiveness + black-screen recovery — HUMAN ACCEPTED

The canonical `PlayerActionController` resolves accepted actions through a one-due-tick-batch-per-render-frame pump. Input is accepted only at WHEN's real decision pause and stays locked until that pause returns; the old fixed 120 ms post-action cooldown is gone. Ambient/emitter/observer work remains coalesced once per accepted player action.

The follow-up executable `6e1298da36e9216139f404696275280fcb944033` introduced camera-cropped physical-light presentation and a revision-cached bounded System-23 LOS field. Although automated checks passed, human browser play reported a completely black game. That visibility optimization stack remains **rejected**.

Recovery executable `1f65bff312853a44858201b57d9df2e26ee64f80` restored the last human-good full 80x96 physical-light presentation path and prior stateless LOS query while preserving decision-pause input locking, one-batch-per-frame action resolution, coalesced settled updates, flashlight-facing fixes and runtime naming cleanup.

`PlayerInputResponsivenessSmoke.gd` now proves an actual usable visible field and non-black lighting rather than scene startup alone.

Exact-head verification for `1f65bff...` completed with 46 successful workflows, zero failing workflows, and successful Pages build/deploy. Human browser play now confirms the black screen is fixed and performance improved. This recovery/performance slice is accepted.

Obsolete runtime naming/compatibility residue remains removed. The still-temporary `DemoLightingSourceAdapter` remains honest and necessary for the portable DEV flashlight seam until real portable equipment/battery truth is deliberately designed. System 33 may replace fixed grid-powered fixture truth without pretending that portable equipment work is already complete.

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
- 27 owns physical illumination and emitter truth.
- 29 owns neutral reach/offer composition but not mechanic capability.
- 30 owns freshness records/derivation, not refrigeration, cooking or nutrition.
- 31 owns icon presentation only.
- 32 owns recipe-driven physical item transformation, not later construction/repair/cooking/utilities/skills/vehicles/combat.
- 33, once approved/implemented, owns persistent power/water runtime service state and real utility-consumer service queries; it does not take ownership from 27 or 30.
- Phase 4 owns nutrition/thirst/health consequences; Phase 6 final Skills; Phase 7 Vehicles; Phase 8 AI/combat/outbreak.

---

## Current next lifecycle gate

**System 33 / Roadmap Phase 3 — Power and Water: APPROVE.**

Design: `SYSTEM_DESIGNS/33_POWER_WATER_UTILITIES.md`.

No runtime Phase-3 code has been implemented by the DESCRIBE step.

On explicit approval, implementation begins with **33A Utility state foundation + plan materialization**, then proceeds through the bounded power, water and refrigeration vertical slices while preserving current human-accepted responsiveness/visibility behavior.
