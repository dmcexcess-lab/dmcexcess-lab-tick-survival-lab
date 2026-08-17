# Tick Survival Lab — 13C Actor Skills

Status: **APPROVED — user explicitly approved all System 13 children for implementation on 2026-08-16**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own persistent survivor skill identity, level/rank, and XP progression as a standalone typed domain keyed by stable WHAT actor ID.

## Non-goals
13C does not own occupations/background generation, temporary effective-skill modifiers, combat resolution, action timing, item bonuses, UI, or a universal actor dictionary.

## Owner
`game/scripts/simulation/actors/skills/`:
- `ActorSkillCatalog.gd`
- `ActorSkillState.gd`

## Initial catalog
Recovery-backed canonical v1 skills, in deterministic display order:
1. `combat` — Combat
2. `scavenging` — Scavenging
3. `survival` — Survival
4. `medical` — Medical
5. `technical` — Technical
6. `social` — Social

The catalog is semantic and enumerable so a later seventh skill does not require fixed actor fields or hardcoded UI rows.

## Progression
Exact same-owner First Fire progression is reused:
- levels 0..10;
- persistent XP per skill;
- next-level threshold `20 + current_level * 15`;
- a large XP award may cross multiple levels deterministically;
- after crossing a threshold, only remainder XP carries forward;
- level 10 is capped and stores 0 XP.

Interpretive bands (presentation only): 0 untrained; 1–3 basic; 4–6 experienced; 7–9 expert; 10 mastery.

## Enrollment / state
Normal enrollment accepts existing `actor.survivor` WHAT entities. Missing record differs from enrolled all-zero skills.

Per actor:
- level per catalog skill;
- XP per catalog skill;
- per-actor version.

Public reads expose level, XP, next threshold, catalog IDs/display names, version/revision, copied actor data, and deterministic snapshot. Public mutations enroll/remove, set level+XP for setup, award positive XP, and load snapshot.

Background/player-story generation may set starting levels through public mutation but is not owned here.

## Effective-skill seam
13C owns base persistent skill only. Fatigue, injury, tools, equipment, traits, mood/panic, and environment remain mechanic-specific modifiers outside 13C.

## Persistence
Schema-versioned deterministic actor/skill ordering, atomic malformed-snapshot rejection, unknown-skill rejection, monotonic revision/per-actor version, no RNG.

## Dependencies
Allowed: read-only WHAT validation and 13C catalog.
Forbidden: WHEN, Health, Needs, Inventory/Hands/Carry, Combat/AI, character-creator UI, renderer/art, reboot.

## Failure cases
Reject missing/non-survivor enrollment, unknown skill, invalid level/XP, non-positive XP award, malformed snapshot. Same-value setup is a no-op. Awarding XP at level 10 is a successful capped no-op.

## Tests
Dedicated smoke covers all six IDs/order, enrollment, zero state, level/XP reads, exact threshold progression, multi-level gain, level-10 cap, setup validation, version/no-op behavior, copy safety, deterministic atomic snapshot restore, unknown-skill rejection, and WHAT regression compatibility.

## North-star fit
Six broad skills create meaningful survivor differentiation without a sprawling RPG tree and fit background-derived generated people.

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
