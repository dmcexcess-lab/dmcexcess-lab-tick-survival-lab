# Tick Survival Lab — 13C Actor Skills

Status: **IMPLEMENTED + CI**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own persistent survivor skill identity, level/rank, and XP progression as a standalone typed domain keyed by stable WHAT actor ID.

## Owner
- `game/scripts/simulation/actors/skills/ActorSkillCatalog.gd`
- `game/scripts/simulation/actors/skills/ActorSkillState.gd`
- smoke: `game/scripts/ci/ActorSkillsSmoke.gd`

## Canonical v1 catalog
1. `combat` — Combat
2. `scavenging` — Scavenging
3. `survival` — Survival
4. `medical` — Medical
5. `technical` — Technical
6. `social` — Social

The catalog is semantic and enumerable rather than six hardcoded actor fields.

## Progression
Recovered same-owner First Fire progression is canonical v1:
- levels 0..10;
- persistent XP per skill;
- threshold `20 + current_level * 15`;
- one award may cross multiple levels deterministically;
- threshold subtraction leaves remainder XP;
- level 10 stores zero XP.

13C owns base persistent skill only. Fatigue, injury, tools, equipment, traits, panic/mood, and environmental modifiers remain outside the skill state.

## Enrollment / mutation
Normal enrollment accepts existing `actor.survivor` WHAT entities and starts all six at level 0 / XP 0. Public setup may set normalized level+XP for generated backgrounds. Positive XP awards use the catalog progression policy. Unknown skills and invalid levels/XP are rejected. Same-value setup and XP awards at cap are no-ops.

## Persistence
Deterministic schema-v1 snapshot/restore with actor and catalog order, atomic malformed/unknown-skill rejection, global revision and per-actor version.

## Boundaries
Allowed: read-only WHAT validation + 13C catalog.
Forbidden: WHEN, Health, Needs, Inventory/Hands/Carry, Combat/AI, character-creator UI, renderer/art, reboot.

## Verification
`ActorSkillsSmoke.gd` covers all six IDs/order, zero enrollment, exact 20/35/50 progression, multi-level awards, level-10 cap, setup validation, unknown-skill rejection, no-op version behavior, copy-safe reads, deterministic snapshot restore, and atomic malformed rejection.

Initial complete System 13 candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed **Actor Stats Domains contract** run `31992365565` with no production repair.

## Approved decisions — 2026-08-16
1. Initial skills are Combat, Scavenging, Survival, Medical, Technical, Social.
2. Skills are catalog entries, not fixed actor fields.
3. Levels are 0..10 with persistent XP.
4. Threshold is exactly `20 + current_level * 15`.
5. Large awards may cross multiple levels.
6. Level 10 stores zero progression XP.
7. 13C owns base progression only; effective-skill modifiers remain outside.
8. Background/player-story setup uses public mutations.
9. UI later enumerates the catalog dynamically.
