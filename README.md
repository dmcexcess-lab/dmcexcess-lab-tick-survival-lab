# Tick Survival Lab

> **Sprite-based zombie survival game.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Tick Survival Lab is an original Godot 4 top-down zombie survival game: **scavenge, fight, craft, survive**. Shared tick time, committed/interruptible actions, simultaneous consequences, mob force and fear define combat. The persistent world includes day/night, weather, vehicles, power and water; a base is an existing building you fortify.

**Release scope reset — 2026-09-25:** [ROADMAP.md](ROADMAP.md) defines the finite completion plan. Living survivor/society simulation and freeform construction are retired from the target scope; their runtime removal is still pending. Save/continue, realistic parking/vehicle placement, environmental stories and integrated balance remain release requirements. This documentation update is not an implementation claim.

Live build:

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/

## Current architecture

The canonical modular stack includes:

- **WHERE** — global integer-cell spatial model;
- **WHAT** — one authoritative persistent current world;
- **WHEN** — deterministic tick/action/pause kernel;
- **System 00D** — global world planning (geography, settlements, roads and regional utilities);
- **System 19** — local building grammar with 24 callable archetypes: six protected references plus an 18-profile one-story baseline library;
- **System 20** — local area generation with ten area profiles and seven environment palettes spanning current rural content plus reusable suburban, urban, commercial, industrial and civic baselines;
- **System 00F** — logical materialization + technical streaming activation;
- **System 23** — deterministic facing-based LOS, true unexplored fog, stale remembered-world knowledge and last-seen living-actor observations;
- modular collision, movement, actor state, inventory/equipment, doors, rendering, camera, HUD/player-shell and DEV critique systems.

The live project uses the canonical modular composition and generated island. See `README_CONTEXT.md` for the exact executable checkpoint and `ROADMAP.md` for planned scope changes.

## World model

The physical world is persistent and logically continuous, not a sequence of raid/extraction maps.

Global planning owns world-spanning coherence before local detail. Streaming partitions are technical only. Once virgin generated facts are materialized, WHAT and typed mechanic stores own subsequent current reality.

There is no required extraction-shooter loop. The survivor may roam, relocate, fortify existing places, maintain multiple safe sites or remain nomadic. Freeform construction is outside the release scope.

## Baseline building and area model

Current city-density content remains deliberately **one story**. Buildings become denser and more interesting through realistic rooms, useful adjacency, horizontal units and justified circulation—not fake upper floors.

The baseline building library includes suburban houses, townhomes, one-story multi-unit housing, a roadside motel, convenience/grocery/pharmacy/hardware/office commercial buildings, clinic/police/fire/school/church civic buildings, warehouse/workshop industrial buildings and a barn. Multi-unit homes and motel rooms can have independent exterior entrances while one designated primary door remains the higher-level placement anchor.

System 20 provides reusable `suburban.neighborhood`, `urban.mixed`, `commercial.corridor`, `industrial.district` and `civic.campus` morphologies in addition to the five existing rural/watercourse profiles. Baseline building selection is deterministic and parcel-fit aware, and occupied residential, farmstead, commercial, civic and industrial parcels receive real access to generated primary entrances.

Environment profiles are local palettes, not global geography authority. Woodland/coastal/marsh vocabulary does not allow a local generator to invent a forest, coast or marsh that global planning has not established.

## Time model

The simulation is turn-based through an authoritative variable-duration tick/action kernel.

While the player is choosing, world time pauses. An action consumes ticks under its commitment/interruption rules. Effects due at each tick must resolve coherently and overlapping activity must appear simultaneous. Tactical pauses occur at legitimate decision boundaries, not whenever the player wishes. A separate hard application pause freezes pending actions for real-life interruptions without cancellation or free tactical choices. Full combat acceptance is still open in the roadmap.

## Spatial model

Canonical space uses:

- global integer `Vector2i` cells;
- roughly 1 meter planning scale per tactical cell;
- N/E/S/W facing;
- whole-cell arbitrary footprints;
- structure cells with horizontal/vertical axis;
- semantic world data independent from renderer atlas assumptions.

Art is presentation, not physics.

## Perception model

System 23 uses three observer-knowledge states:

- `UNSEEN` — completely black visual world information;
- `REMEMBERED` — darkened stale last-observed environment;
- `VISIBLE` — current live world truth.

Hidden live mutations never update remembered visual truth. Future spatial-sound cues may appear over any visual state without revealing the terrain beneath them.

## Development process

Repository work follows the single canonical process in [`README_SOPS.md`](README_SOPS.md):

> **DESCRIBE -> APPROVE -> IMPLEMENT -> VERIFY**

The architecture targets replaceability, **not maximum file count**. A profile/candidate/revision does not automatically become a new peer system.

Important references:

- [`PROJECT_NORTH_STAR.md`](PROJECT_NORTH_STAR.md) — game identity and anti-drift rules;
- [`DESIGN_DECISIONS.md`](DESIGN_DECISIONS.md) — settled cross-system decisions/rationale;
- [`README_CONTEXT.md`](README_CONTEXT.md) — concise current state and next-path routing;
- [`README_SOPS.md`](README_SOPS.md) — canonical repository/design/implementation workflow;
- [`SYSTEM_DESIGNS/README.md`](SYSTEM_DESIGNS/README.md) — system status ledger;
- [`SYSTEM_DESIGNS/`](SYSTEM_DESIGNS/) — canonical current subsystem contracts;
- [`CHANGELOG.md`](CHANGELOG.md) — current implementation history plus archive links.

## Historical recovery

Git history is the recovery source for removed/deprecated architectures and detailed candidate drafts.

Golden mature visual/system archaeology commit:

`1763958f44eb7f855fd49944c00d1ffe608c0abe`

Historical `TacticalTiles.gd` blob:

`3d8a0a70ac983408bb48f58fc659dfb07e216ed3`

The active tree does not retain a frozen duplicate runtime merely for archaeology when Git already preserves it.

## Run locally

Open `game/project.godot` in Godot 4.7.1 and run the project.
