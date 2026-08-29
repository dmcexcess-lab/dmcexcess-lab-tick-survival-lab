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

## Current canonical playable world

The canonical DEV/playable composition is the **complete streamed island**.

- Global bounds: 1792x1792 tactical cells (`Rect2i(232,1232,1792,1792)`).
- System 00D `temperate.island.region` is **v3** and overlays deterministic LAND / SHORE / OCEAN on the protected rural-v6 planning skeleton.
- Five globally connected site identities remain: one `rural.crossroads`, one `smalltown.center`, and three `rural.scattered` hamlets.
- The central local-area seed is derived from world seed + site identity instead of reusing the historical standalone critique seed.
- The old 640-cell regional protected-cross half-span is not carried into the playable island; island v3 uses a compact 160-cell local protected cross.
- Island settlement spacing is compact enough to read as one continuous generated world rather than separated mini-maps.
- System 00F materializes non-overlapping settlement, river/watercourse and island-surface logical sources.
- Technical streaming is 128x128 with active radius 1 and follows the survivor. Technical regions are performance configuration, never world identity.
- Ocean/ordinary river water is non-traversable except explicit planned bridge deck.
- Natural ecology is derived from shared world seed + absolute global cell so logical source boundaries do not restart vegetation identity.
- The playable survivor starts on inherited pavement beside the central crossroads, not at the diner entrance.

### Compact-island / legacy seam cleanup — COMPLETE + CI VERIFIED

Verified executable: `918f1dbd7b033fa179522a112b1507d9a2c63890`.

Final defect fixed during cleanup: global geography snapping previously rejected settlement centers only when they were within a 160-cell center-distance threshold. Local area sites are 256x256, so grid-snapped centers could legally pass that heuristic while their actual site rectangles still overlapped. An alternate world seed exposed this as `island_base_site_overlap:area.smalltown.center.001`.

`GlobalSettlementPlanner` now rejects **actual positive-area 256x256 site-rectangle overlap** while preserving deterministic geography/hydrology selection. Edge-touch remains legal; true overlap advances to the next deterministic legal geography candidate. The validator was not weakened.

On exact head `918f1dbd7b033fa179522a112b1507d9a2c63890`:

- `global-world-planning` passed, including the formerly failing **legacy crossroads is not embedded in island** smoke;
- canonical demo startup passed;
- `local-area-generation`, `large-area-critique`, `streaming-materialization`, `canonical-player-shell`, System 32 Crafting and performance architecture passed;
- Pages build/deploy passed;
- exact-head Actions settled with **zero failed runs and zero in-progress runs**.

This closes the compact-island/world-seam cleanup. Do not reopen it without new evidence.

---

## Current implemented stack

Roadmap **Phase 1 and Phase 2 are implementation-complete**.

Implemented systems/capabilities include:

- authoritative WHERE / WHAT / WHEN foundations;
- collision, movement, actor locomotion, stance, carrying and timed item transfer;
- complete-island global/local generation and technical streaming;
- System-19 building generation and System-20 local-area morphology;
- broad deterministic location dressing and world clutter;
- persistent searchable world loot with the current physical item catalog;
- world time/daylight;
- spatial sound/hearing;
- physical lighting, visibility and shadows;
- Weather/atmosphere/lightning;
- perception / fog memory;
- real interaction affordance/reach highlights;
- analytic item freshness/spoilage with no per-item timers;
- semantic inventory/menu icons;
- large/multi-cell prop presentation geometry;
- **System 32 Crafting / Material Transformation**, including real persistent ingredient/tool/output entities, timed WHEN actions, workstations, compensation, interaction offers, and phone/Safari-first player UI.

### Phase 1E content integration

Verified executable: `6ad923d172f5a5434f94a7fdcc15da640a60a240`.

Phase 1E broadened world dressing, location-aware loot, perishables and icon coverage while extending existing owners rather than creating duplicate truth.

### Phase 2 / System 32 Crafting

Canonical design: `SYSTEM_DESIGNS/32_CRAFTING_MATERIAL_TRANSFORMATION.md`.

Status: **IMPLEMENTED + CI VERIFIED — Candidate 001 / Roadmap Phase 2 complete**.

Verified executable: `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`.

Exact-head context: `verify/system32-crafting`.

Core rule:

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

Implemented scope includes:

- deterministic exact-semantic recipes and workstation capabilities;
- ingredients/tools selected from real personal possession rather than a resource wallet or nearby auto-pull;
- real non-consumed tool requirements;
- positive-duration CANCELABLE `crafting.craft_recipe` WHEN actions;
- final-commit revalidation;
- real input entity removal and deterministic real output creation;
- actor-root containment and hard carry-limit enforcement;
- bounded compensation journal rather than whole-world snapshots;
- explicit heavy-workbench capability and System-29 `CRAFT` offer;
- phone/Safari-first Crafting panel and canonical-shell integration.

Crafting does **not** own Construction/Repair/Durability, Cooking/Nutrition, Power/Water, Skills/quality/XP, Vehicles, Combat/ammunition or AI.

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
10. Expensive consumers wake only for the domains/completed batches they actually depend on.
11. Food freshness is derived analytically from authoritative time/exposure; no item gets a spoilage timer.
12. UI icons visualize semantic truth but never define identity, utility, freshness or action legality.
13. Logical area/streaming boundaries must not reset world-space environmental identity.
14. Physical footprints answer where objects are; presentation geometry may be larger but never redefines physical truth.
15. Bright art does not create light. System-27 emitter truth remains the only source of physical-light presentation glow.
16. Content extends existing owners; integration never creates a second owner or placeholder future mechanics.
17. Generated settlement/local-area rectangles may touch but must never positively overlap.
18. Validators fail closed. A failing legal seed is a generation defect to repair, not a reason to weaken the validator.

---

## Performance architecture

The P0/P1/P2 performance architecture plus Weather presentation optimization is human-accepted on phone/Safari.

Protected direction:

- event-driven/cache-oriented invalidation;
- no recurring whole-world scans;
- no per-cell/per-item Nodes or timers;
- no frame-driven simulation;
- bounded local queries and shared cached plans;
- persistence-backed streaming eviction remains evidence-driven future work only.

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

**Roadmap Phase 3 — Power and Water: DESCRIBE.**

Do **not** implement Phase-3 runtime code until its bounded design is approved.

Phase-3 direction already established by the roadmap:

- Power: major source -> substation/local distribution -> vulnerable local service.
- Water: treatment/waterworks -> pump/local distribution -> local mains/hydrants/service.
- Powered lights/neon/TVs/pumps/appliances must consume real utility state and feed existing physical systems.
- Utility failures become persistent world consequences.
- System 30 refrigeration may activate only from real Phase-3 power/appliance truth.
- Existing wastewater planning may remain inert; standalone wastewater/sewer gameplay is not an active roadmap target.

The next response that advances gameplay should therefore **DESCRIBE Phase 3**, not silently start coding it.
