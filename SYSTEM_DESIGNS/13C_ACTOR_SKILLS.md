# Tick Survival Lab — 13C Actor Skills

Status: **IMPLEMENTED — FOUR-SKILL CONTRACT + ACTION-BOUNDARY CONSUMERS**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Canonical catalog

The live survivor catalog is exactly four broad skills:

1. `awareness` — Awareness
2. `stealth` — Stealth
3. `mechanical` — Mechanical
4. `survival` — Survival

There are no live Combat, Scavenging, Medical, Technical or Social skill entries.

Mechanical owns practical machinery competence such as repair, deconstruction/reclamation and vehicle hot-wiring when those owning systems exist. Survival owns first aid, scavenging/foraging, fire-starting and primitive survival crafting. Awareness and Stealth remain separate perceptual/tactical competencies.

## Progression and persistence

- levels 0..10;
- persistent XP per skill;
- threshold `20 + current_level * 15`;
- one award may cross multiple levels deterministically;
- level 10 stores zero XP;
- schema-v2 snapshot is canonical.

Legacy schema-v1 migration is deterministic and atomic:

- legacy Technical becomes Mechanical;
- Survival takes the strongest accumulated progression among legacy Scavenging, Survival and Medical rather than summing three histories;
- Awareness and Stealth begin at 0/0;
- Combat and Social retire without dishonest remapping.

## Shared action check

`ActorSkillCheckService` is the canonical action-boundary competence service. Given actor, skill, authored difficulty and real WHEN action serial/context, it supplies:

- skill-adjusted duration;
- deterministic success chance/result;
- bounded effectiveness;
- bounded success/failure practice XP.

It owns no item, health, target, environment or action scheduling truth. Consumers must still validate their real physical prerequisites and owning domain state.

## Physical-action rule

> **A skill changes how well a valid physical action is performed. It never substitutes for a missing physical prerequisite.**

Where an action requires a tool/material, the real item must exist through canonical WHAT/containment truth. Examples include hammer+nails, wrench+bolts, screwdriver+wires and rag+alcohol.

## Current real consumers

- **System 32 Crafting** — Mechanical/Survival recipes use concrete physical materials, concrete tools, WHEN time and this shared skill check. The UI quotes the same service rather than duplicating skill math.
- **System 24 searchable-container scavenging** — Survival affects search duration/outcome XP while persistent container contents remain the existing physical loot truth; skill never rerolls or manufactures contents.
- **System 35 outdoor foraging** — Survival changes duration, success and bounded recovery yield for finite deterministic local stick/stone opportunities derived from real outdoor context.

First aid, generalized repair, deconstruction/reclamation, vehicle hot-wiring, fire-starting, and real Awareness/Stealth action consumers remain future bounded integrations. Do not fake them in the skill owner.

## Performance boundary

Skills are evaluated at explicit action/query boundaries. No frame-driven skill processing, per-actor skill timers or recurring whole-world skill scans are permitted.

## Verification

Owning coverage includes `ActorSkillsSmoke.gd`, System-32 crafting tests, System-24 loot/search tests, System-35 outdoor-forage smoke and canonical startup/playable-boot regressions.
