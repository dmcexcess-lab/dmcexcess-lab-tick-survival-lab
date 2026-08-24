# Tick Survival Lab

> **Ultima-style turn-based mini Zomboid.**
>
> **Mini means reduced complexity, not reduced consequence or mood.**

Tick Survival Lab is an original Godot 4 top-down zombie survival simulation built around a logically continuous persistent open world, discrete variable-duration actions, systemic consequences, emergent bases and deliberately simplified-but-interconnected survival mechanics.

Live build:

https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/

## Current architecture

The canonical modular stack includes:

- **WHERE** — global integer-cell spatial model;
- **WHAT** — one authoritative persistent current world;
- **WHEN** — deterministic tick/action/pause kernel;
- **System 00D** — global world planning (geography, settlements, roads, hydrology/bridge intent, regional utilities);
- **System 19** — local building grammar;
- **System 20** — local area generation for crossroads, small-town, scattered rural, dry countryside and physical watercourse/bridges;
- **System 00F** — logical materialization + technical streaming activation;
- **System 23** — deterministic facing-based LOS, true unexplored fog, stale remembered-world knowledge and last-seen living-actor observations;
- modular collision, movement, actor state, inventory/equipment, doors, rendering, camera, HUD/player-shell and DEV critique systems.

The live project boots the canonical modular `CanonicalDemoMain.gd` composition stack.

## World model

The physical world is persistent and logically continuous, not a sequence of raid/extraction maps.

Global planning owns world-spanning coherence before local detail. Streaming partitions are technical only. Once virgin generated facts are materialized, WHAT and typed mechanic stores own subsequent current reality.

There is no required extraction-shooter loop. The survivor may roam, relocate, fortify existing places, build elsewhere, maintain multiple safe sites or remain nomadic.

## Time model

The simulation is turn-based through an authoritative variable-duration tick/action kernel.

While the player is choosing, simulation pauses. A committed action consumes world ticks; other scheduled actors/systems may act during those ticks. A separate hard application pause protects real-life interruption without treating it as a tactical mistake.

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
