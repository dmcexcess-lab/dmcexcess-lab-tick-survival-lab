# Tick Survival Lab — Cross-System Design Decisions

This is the durable log for **approved or clearly settled cross-cutting decisions** that affect more than one subsystem.

It is not a brainstorming file. Detailed mechanics belong in `SYSTEM_DESIGNS/`. Current work status belongs in `README_CONTEXT.md`. This log exists so later work can recover the reason behind a major direction instead of inferring it from implementation.

## How to use this file

For each durable cross-system decision record:

- date;
- decision;
- why it was chosen;
- what it supersedes, if anything;
- systems affected;
- unresolved follow-up questions.

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

- the desired game is closer to a persistent survival world than a sequence of disconnected maps;
- independently generated local maps create unacceptable risk of road/infrastructure seam errors;
- a continuous world supports persistent homes, vehicles, corpses, construction, households and outbreak history more naturally;
- extraction-shooter risk/reward can exist as expeditions away from safety without requiring instanced raid maps.

**Supersedes:** earlier static strategic-map -> generated raid -> extraction architecture as the long-term foundation.

**Affected systems:** world model, generation, persistence, streaming, travel, extraction, base, vehicles, population/outbreak simulation.

**Unresolved:** exact streaming/storage partition size and activation model.

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

## 2026-08-16 — Base is fundamentally a physical world location

**Decision:** A base/home is primarily an ordinary persistent physical location made safe/useful by the player. Higher-level base/community UI may summarize it later but should not replace physical storage, beds, workspaces, vehicles, power, water, construction, residents, etc.

**Affected systems:** world state, construction, inventory/storage, power, vehicles, survivors/community, base UI.

---

## 2026-08-16 — Invisible tactical grid retained

**Decision:** Keep an authoritative tactical grid for simplicity. Actors move cell-to-cell; props/fixtures use whole-cell footprints; directional objects carry N/E/S/W orientation. Grid lines need not be shown.

**Art rule:** Renderer may rotate suitable sprites by 90-degree increments or use authored directional variants where rotation is visually wrong. Generator/world data stores semantic object + orientation, not atlas-specific facing logic.

**Why:** Grid-based space substantially simplifies graphics, generation, collision, pathfinding, AI, persistence and deterministic tick movement without requiring the game to look like a board game.

**Affected systems:** spatial model, art catalog, renderers, movement, collision, generation, prefabs, AI, perception.

**Unresolved:** whether walls/doors/windows are represented as occupied cells or cell-edge structures. Resolve in Spatial Model design before implementation.

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
