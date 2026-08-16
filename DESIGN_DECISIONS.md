# Tick Survival Lab — Cross-System Design Decisions

This is the durable log for **approved or clearly settled cross-cutting decisions** that affect more than one subsystem.

It is not a brainstorming file. Detailed mechanics belong in `SYSTEM_DESIGNS/`. Current work status belongs in `README_CONTEXT.md`. This log exists so later work can recover the reason behind a major direction instead of inferring it from implementation.

If a later discussion changes a decision, do not erase history. Add a newer entry that explicitly supersedes the old one.

---

## 2026-08-16 — Game identity

**Decision:** Use **“Ultima-style turn-based mini Zomboid”** as the primary design shorthand.

**Meaning:**

- Ultima-style: readable top-down tile-based world/exploration presentation;
- turn-based: authoritative variable-duration tick/actions with automatic pause at player decision points;
- mini Zomboid: interconnected persistent survival systems using deliberately simpler internal models.

**Design principle:** **Mini means reduced complexity, not reduced consequence or mood.**

**Affected systems:** all.

---

## 2026-08-16 — Persistent open world replaces separate-raid world as foundation

**Decision:** The long-term world is logically continuous and persistent. Streaming/storage partitions may exist internally, but separately generated raid maps are not the fundamental physical-world model.

**Why:**

- the desired game is a persistent survival world rather than a sequence of disconnected maps;
- independently generated local maps create unacceptable risk of road/infrastructure seam errors;
- a continuous world supports persistent homes, vehicles, corpses, construction, households and outbreak history naturally.

**Supersedes:** earlier static strategic-map -> generated raid -> extraction architecture as the long-term foundation.

**Affected systems:** world model, generation, persistence, streaming, travel, bases, vehicles, population/outbreak simulation.

**Unresolved:** exact streaming/storage partition size and activation model.

---

## 2026-08-16 — Extraction-shooter framing removed

**Decision:** Extraction-shooter structure is no longer part of the current game identity or required gameplay loop.

The player exists continuously in the open world. There is no required raid boundary, extraction zone, gear-in/gear-out transaction, staging screen, or forced return-to-base loop. The player may roam indefinitely, move home, establish multiple safe locations, abandon them, or live nomadically.

Returning to shelter with valuable supplies can still be an emergent survival decision, but it is not a separate extraction mechanic.

**Supersedes:** all remaining “extraction-style expedition risk/reward” language in the North Star/context and the old extraction/session design direction.

**Affected systems:** progression, inventory, travel, base, persistence, death, UI, world flow.

---

## 2026-08-16 — Global planning owns large-scale world coherence

**Decision:** Roads, utilities, parcels and other cross-region structures are planned in global world coordinates before local materialization. Local chunks/streaming regions do not independently invent incompatible road exits.

**Why:** Avoid boundary mismatches and make world geography causally coherent.

**Affected systems:** world planner, roads, utilities, parcels, local generation/materialization, persistence.

---

## 2026-08-16 — Outbreak is a causal persistent simulation goal

**Decision:** The long-term new-world process should support a pre-collapse population/household world and simulate outbreak spread/collapse causally rather than merely assigning a post-apocalypse zombie-density result.

**Performance interpretation:** Persistent causal state does not require second-by-second full-resolution simulation everywhere. Distant actors/populations may use coarse deterministic simulation while nearby actors use detailed tactical actions.

**Affected systems:** population, households, jobs/schedules, infection, emergency response, world time, streaming/simulation resolution, player stories.

---

## 2026-08-16 — Player story is embedded in the generated world

**Decision:** Character creation eventually selects/customizes a real person with a home, job/workplace, household/family, relationships, pets/vehicle/resources where applicable. Known people are persistent world actors, not merely scripted quest markers.

**Why:** Personal history should make the outbreak and persistent world emotionally meaningful and create emergent goals such as finding family.

**Affected systems:** population, character creation, player state, households, jobs, relationships, outbreak simulation, starting scenarios.

---

## 2026-08-16 — Bases are emergent physical constructions/secured places anywhere

**Decision:** There is no special base map or mandatory preselected base property. The player may build and secure a base anywhere in the persistent world where normal construction/occupancy rules allow it.

A starting home may be useful but is not mechanically privileged. Existing buildings may be fortified; open land may be developed; multiple safe sites can coexist; bases may be abandoned or moved.

Higher-level base/community UI may summarize physical facts later, but should not create a separate base reality.

**Affected systems:** construction, world state, inventory/storage, power, water, vehicles, survivors/community, farming, base UI.

---

## 2026-08-16 — Invisible tactical grid retained

**Decision:** Keep an authoritative tactical grid for simplicity. Actors move cell-to-cell; props/fixtures use whole-cell footprints; directional objects carry N/E/S/W orientation. Grid lines need not be shown.

**Art rule:** Renderer may rotate suitable sprites by 90-degree increments or use authored directional variants where rotation is visually wrong. Generator/world data stores semantic object + orientation, not atlas-specific facing logic.

**Why:** Grid-based space substantially simplifies graphics, generation, collision, pathfinding, AI, persistence and deterministic tick movement without requiring the game to look like a board game.

**Affected systems:** spatial model, art catalog, renderers, movement, collision, generation, construction, AI, perception.

**Follow-up resolved below:** wall/door/window representation and canonical cell scale were settled during WHERE implementation.

---

## 2026-08-16 — Real-life interruption safety is mandatory

**Decision:** The turn-based action model must include a hard application pause that freezes simulation immediately and safely when the user needs to stop playing. Real-life interruption must not be treated as a tactical error.

**Target implications:** explicit pause/menu path plus browser/mobile visibility/focus handling where technically reliable.

**Affected systems:** tick/action kernel, input, Safari/mobile lifecycle, application state.

---

## 2026-08-16 — Health follows the mini-Zomboid simplification rule

**Decision:** Health should preserve meaningful injury/treatment consequences without simulating unnecessary physiological detail. Current conceptual model centers on injury type/body region/severity and treatment/stabilization/healing rather than literal blood-flow simulation.

**Example severity concept:** low/minor, medium/serious, very/critical hurt, with treatment requirements and capability penalties driven by injury type/severity.

**Affected systems:** health/body, first aid, movement/action costs, combat, UI.

**Unresolved:** exact severity names, body-region granularity, worsening/healing/infection rules.

---

## 2026-08-16 — WHERE / WHAT / WHEN is the simulation-foundation decomposition

**Decision:** The lowest-level simulation architecture is organized around three narrowly owned truths rather than around the map generator:

- **WHERE — Spatial Model:** the global tactical-grid coordinate language, directions, footprints and structure/opening geometry;
- **WHAT — Persistent World / Entity State:** what terrain, structures, objects, actors, items and durable mutations exist at those coordinates;
- **WHEN — Tick / Action / Pause Kernel:** authoritative world ticks, action durations, scheduled execution, auto-pause and hard real-life pause.

Generation is a producer of initial WHAT using WHERE. Construction/destruction/gameplay mutate WHAT. Rendering reads WHAT through WHERE. Gameplay/action systems bridge WHERE/WHAT with WHEN; the scheduler does not learn mechanic-specific meanings.

**Why:** This keeps world generation replaceable, keeps persistent state independent of rendering/streaming, allows all gameplay to share one time model, and gives future systems such as health, AI, weather, vision, vehicles, construction and outbreak simulation stable extension seams.

**Affected systems:** all simulation/gameplay systems.

**Detailed design:** `SYSTEM_DESIGNS/00_FOUNDATION_WHERE_WHAT_WHEN.md`.

---

## 2026-08-16 — WHERE spatial representation locked for the first modular implementation

**Decision:** The canonical Spatial Model now uses:

- global integer `Vector2i` cells;
- N/E/S/W semantic facing;
- whole-cell arbitrary-mask footprints rotated around a stable anchor;
- a centralized planning scale of **1.0 meter per tactical cell**;
- **structure cells** rather than cell-edge walls;
- explicit HORIZONTAL/VERTICAL structure axis for walls/openings;
- layered spatial channel vocabulary without storing occupants in WHERE.

**Why:** This is the simplest model that preserves the intended Ultima-like readability, deterministic turn-based movement, rotated clutter/vehicle footprints, recovered-art compatibility, doorway geometry, construction, LOS and future persistent-world use. Edge-wall/sub-cell models add complexity without a currently identified gameplay or mood benefit.

**Supersedes/resolves:** the earlier unresolved wall-cell-vs-edge-wall and exact cell-scale questions.

**Affected systems:** WHAT placement/indexes, generator, construction, renderer, collision/pathfinding, perception/LOS, vehicles, streaming calculations and validation.

**Implementation:** `SYSTEM_DESIGNS/00A_SPATIAL_MODEL.md` and `game/scripts/foundation/spatial/`.
