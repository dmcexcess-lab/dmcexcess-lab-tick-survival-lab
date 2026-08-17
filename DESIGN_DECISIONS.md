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

---

## 2026-08-16 — WHAT owns one current persistent world truth

**Decision:** The canonical Persistent World / Entity State foundation stores **one authoritative current world**, not parallel “generated/original” and “modified/current” gameplay realities.

Generation may populate virgin terrain/entities through the same world contract used by later construction/destruction/gameplay. Once a fact exists, subsequent state is owned by the current persistent world. A future save layer may use deterministic baselines, mutation journals or region snapshots as storage optimizations, but gameplay systems never choose between competing world truths.

Durable entities use opaque stable string IDs independent of Godot Nodes, rendering, store ordering and tactical placement. An entity may remain persistent while unplaced, allowing future container-held items or coarse/distant actors to retain identity without inventing a fake tactical cell.

Foundation WHAT stores explicit semantic entity identity, semantic terrain and WHERE-based placement. It deliberately does **not** use a generic metadata dictionary; future health, inventory, door, vehicle, construction, infection and similar mechanics attach typed state keyed by the same stable entity IDs.

Cell/channel occupancy is a derived lookup index and does not decide collision legality. WHAT records overlap; later collision/construction/movement systems decide whether a requested state transition is legal.

**Why:** This keeps the open world causally persistent while preventing world state from becoming a second gameplay engine or a grab bag of every mechanic. It also makes generation, rendering and streaming independently replaceable.

**Affected systems:** generation, persistence/save storage, streaming, rendering, collision/pathfinding, construction, actors/population/outbreak, inventory, vehicles, health, doors, bases and all durable mechanics.

**Implementation:** `SYSTEM_DESIGNS/00B_PERSISTENT_WORLD_STATE.md` and `game/scripts/foundation/world/`.

---

## 2026-08-16 — WHEN owns one deterministic simulation clock

**Decision:** The canonical Tick / Action / Pause foundation uses one non-negative integer `world_tick` for all simulation scheduling. Render frame rate and wall-clock time never advance simulation implicitly, and WHEN does not decide how ticks map to calendar minutes/hours.

Actor actions and world-system events share one deterministic scheduled-event queue. Ordering is explicit: due tick, then narrow priority, then owner/source key, then insertion serial. Once tick T begins resolving, **all work due at T—including work scheduled for T by another T event—drains before player-decision auto-pause may engage.**

One actor may have one active action at a time, while many actors may have concurrent actions. Action phases are semantic timing checkpoints only; movement, damage, doors, healing, weather, AI and other physical meanings remain owned by their own systems.

The canonical interruption policies are COMMITTED, RESUMABLE and CANCELABLE. Hard application pause is a separate product/lifecycle mechanism that freezes all simulation advancement immediately and advances zero ticks, including during an in-progress action.

The timing kernel stores serializable action/event records rather than live actor Nodes/callback objects. Long-horizon or coarse distant events therefore use the same clock without requiring the corresponding world entity to remain materialized as a Godot object.

**Why:** This makes turn-based exposure deterministic and shared across the whole simulation while keeping the scheduler mechanic-agnostic, saveable, testable, and compatible with coarse distant population/outbreak simulation.

**Affected systems:** movement, AI, combat, health, inventory/search, doors, construction, weather, utilities, vehicles, crops, population/outbreak, save/load, input decision flow and app/Safari pause lifecycle.

**Implementation:** `SYSTEM_DESIGNS/00C_TICK_ACTION_PAUSE.md` and `game/scripts/foundation/time/`.

---

## 2026-08-16 — Collision uses type defaults plus sparse dynamic overrides

**Decision:** Hard movement collision is an explicit downstream physics system that consumes WHERE + WHAT but does not live inside either foundation. Normal collision behavior is registered once per semantic entity type; only dynamic per-entity exceptions consume persistent override state.

STRUCTURE, OBJECT and ACTOR placements must have either a type collision profile or an explicit per-entity override. Missing required classification returns **UNKNOWN/fail-closed** rather than silently treating the entity as passable. Missing terrain is also UNKNOWN so unmaterialized/uninitialized world space cannot be walked into as if it were empty.

LOOSE_ITEM and EFFECT placements do not require collision profiles by default. Terrain traversal capability is separate from hard occupancy collision and will be owned by Movement/Traversal.

**Why:**

- avoids one redundant collision record for every static wall/chair/tree/actor in a potentially huge persistent world;
- keeps physics explicit and independent from art;
- supports dynamic doors/corpses/special states through sparse stable-ID overrides;
- prevents generator/content omissions from becoming invisible passability bugs;
- gives movement, AI, pathfinding and construction one shared query contract.

**Affected systems:** movement, doors, AI/pathfinding, generator/content validation, construction, vehicles, death/corpses, persistence/save orchestration.

**Implementation:** `SYSTEM_DESIGNS/01_COLLISION_SPATIAL_QUERY.md` and `game/scripts/simulation/collision/`.

---

## 2026-08-16 — Death leaves persistent corpse consequences; corpses are not living actors

**Decision:** A dead person/infected should leave a persistent physical corpse/world consequence rather than remain an ordinary living `ACTOR` entry or disappear from the world.

The living Actor renderer therefore covers only living actors. Corpse representation, state, rendering and mechanics are a separate future domain.

Corpse state should preserve a durable relationship to the deceased identity and support age/decay over world time. The exact same-ID versus linked corpse-ID representation is intentionally deferred to the dedicated corpse design because current WHAT entity identity/type contracts should not be casually rewritten merely to support death.

**Gameplay consequence:** ignored bodies can become an environmental health problem. The intended simplified model is accumulated local contamination/filth pressure driven by corpse age/decay, number of bodies and later environmental modifiers such as enclosure/ventilation. Health may later interpret sustained exposure as sickness risk or related penalties.

This is **not** a detailed microbiology simulation and should not become a flat “corpse nearby = random disease roll.” The design target is meaningful cleanup/disposal decisions: moving bodies, cleaning, burial/burning/disposal and avoiding sleeping/living beside accumulating decay.

**Why:** Persistent corpses make death physically consequential, create emergent base-cleanup problems, and fit the mini-Zomboid rule by preserving the survival decision without unnecessary biological complexity.

**Affected systems:** death/combat, persistent world state, corpse state, WHEN, health/sickness, collision, inventory/search, rendering, base safety, streaming/coarse simulation, cleaning/disposal interactions.

**Current renderer consequence:** `SYSTEM_DESIGNS/08_PLAYER_LIVING_ACTOR_RENDERER.md` is living-ACTOR-only; corpse rendering belongs to the future Corpse / Decay / Contamination system.

---

## 2026-08-16 — Actor stats/status are modular peer domains; UI composes them

**Decision:** The requested survivor status set — **moodlets, HP, fatigue, hunger, thirst, sleep, carry weight, and skills/levels** — is not stored in one universal actor dictionary.

The approved architecture separates these responsibilities:

- Health / Injury owns HP and health/injury truth;
- Needs / Rest owns fatigue, hunger, thirst, and sleep pressure;
- Skills owns persistent skill levels/progression;
- Item Physical Properties owns real item weight;
- Carry / Encumbrance derives carried weight/capacity/consequence from actual physical possession plus item weight;
- Moodlets primarily derive readable semantic statuses from the owning domains.

**UI rule:** the future Stats/HUD layer is a reader/composer only. It should consume narrow module contracts/provider adapters so new actor-state domains can be added later without rewriting a monolithic character record or making UI own gameplay truth.

**Derived-truth rules:**

- moodlets should not duplicate HP/needs/carry values as another persistent state bag unless a future effect genuinely owns duration/source/history;
- carried weight should not be persisted as a second total that can drift from real physical items;
- fatigue and sleep remain distinct because they represent short-horizon exertion versus longer-horizon sleep pressure/debt.

**Why:** This preserves the user's desired simple character sheet while keeping the simulation replaceable and extensible. It also fixes the historical tendency for golden Tick `PlayerActor.gd` and First Fire survivor dictionaries to accumulate unrelated state in one owner.

**Affected systems:** health, needs, skills, item definitions/properties, inventory/hands/transfer, carry/encumbrance, movement capability, moodlets, character generation/backgrounds, Stats/HUD UI, save orchestration.

**Detailed umbrella:** `SYSTEM_DESIGNS/13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

**Implementation rule:** the umbrella approval does not authorize all children at once; each independently implementable child still requires its own bounded design/approval.
