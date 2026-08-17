# Tick Survival Lab — 13 Actor Stats / Status Architecture

Status: **IMPLEMENTED via 13A–13F child contracts + dedicated CI**

## Goal
Provide a simple readable survivor status surface while keeping Health, Needs, Skills, Item Physical Properties, Carry, and Moodlets independently replaceable and extensible.

## Core rule
> **Actor condition is composed from typed peer domains keyed by stable WHAT actor ID. There is no universal ActorStats dictionary.**

The future Stats/HUD layer is a reader/composer. It never owns simulation truth.

## Implemented children
- **13A Health / Injury — IMPLEMENTED:** integer HP, broad typed injuries, treatment/stabilization, 100 HP recovered baseline; no corpse ownership.
- **13B Needs / Rest — IMPLEMENTED:** fatigue/hunger/thirst/sleep pressure 0..100; no hidden clock; recovered fatigue timing provider through 03.
- **13C Skills — IMPLEMENTED:** Combat/Scavenging/Survival/Medical/Technical/Social, level 0..10, persistent XP, recovered `20 + level * 15` progression.
- **13D Item Physical Properties — IMPLEMENTED:** explicit semantic item weight in integer grams; missing classification UNKNOWN.
- **13E Carry / Encumbrance — IMPLEMENTED:** persistent base capacity only; recovered 18 kg default; derived carried weight over real 09/11/13D truth; recovered encumbrance timing provider through 03.
- **13F Moodlets — IMPLEMENTED:** derived readable Health/Needs/Carry statuses; ordinary moodlets are not persisted.

Detailed contracts:
- `13A_ACTOR_HEALTH_INJURY.md`
- `13B_ACTOR_NEEDS_REST.md`
- `13C_ACTOR_SKILLS.md`
- `13D_ITEM_PHYSICAL_PROPERTIES.md`
- `13E_ACTOR_CARRY_ENCUMBRANCE.md`
- `13F_ACTOR_MOODLETS.md`

## Stable identity / persistence
Persistent actor-state children key records by stable WHAT survivor ID. They use deterministic schema-versioned snapshots, mutation-safe reads, explicit mutations, global revisions and per-actor versions where appropriate. 13D is explicit content/configuration; 13F is derived presentation state and therefore not redundantly serialized.

## Numeric representation
- Health: integer current/max HP.
- Needs: independent integer 0..100 pressure scales.
- Skills: discrete level + XP.
- Item weight/carry capacity: integer grams.
- Carry ratio: integer basis points, 10,000 = 100%.
- Moodlets: semantic ID/severity/priority, not duplicated numeric state.

## Time / composition
No System 13 owner advances itself from `_process()`. WHEN owns time/order, while future mechanic coordinators explicitly apply outcomes to their domain.

03 Actor Locomotion's existing provider seam is the only locomotion dependency: Needs and Carry supply read-only modifiers without Movement importing either domain.

Current combined recovered timing semantics are additive through 03's existing basis-point composition. At fatigue 100 and exactly 100% carry capacity, the separate providers contribute +6500 bp and +7500 bp respectively before 03 resolves the action duration.

## Forbidden architecture
Do not create a universal ActorStats object/dictionary; do not make Health/Needs/Skills mutually import each other; do not persist derived carried weight; do not let Moodlets mutate their source domains; do not put actor stats in Main/UI/render/reboot.

## Verification
Dedicated workflow: `.github/workflows/actor-stats.yml` — **Actor Stats Domains contract**.

Initial complete implementation candidate `78ed167678257749b093acd54e53e9f065cd8ce5` passed run `31992365565` with:
- source-boundary checks;
- Godot 4.7.1 import/parse;
- WHAT regression;
- Actor Locomotion regression;
- 09 Hand Equipment regression;
- 11 Inventory / Containment regression;
- 13A Health smoke;
- 13B Needs smoke;
- 13C Skills smoke;
- 13D Item Physical Properties smoke;
- 13E Carry smoke;
- 13F Moodlets smoke.

No production repair was required after the first complete candidate.

## Recovery basis
Golden Tick `PlayerActor.gd` provided 100 health, 18 kg carry capacity, fatigue ratio, encumbrance ratio, and the +65%/+75% timing-pressure coefficients. Same-owner First Fire provided the six broad skills, persistent XP, level cap 10, and threshold formula. System 13 recovers those useful semantics while rejecting the historical player god-object/survivor dictionary shapes.

## Future seams
The requested honest Stats/HUD inspector can now display real HP, needs, skills, carry totals/capacity, and moodlets by composing public reads. Future Combat/First Aid, Needs progression, item content catalogs, backgrounds, death/corpses, and transfer capacity policy remain separate systems.

## Approved decisions — 2026-08-16
1. Visible target: moodlets, HP, fatigue, hunger, thirst, sleep, carry weight, skills/levels.
2. 13A–13F are separate peer responsibilities.
3. Newest user instruction explicitly authorized implementing all six children together while preserving internal modularity.
4. Moodlets are primarily derived.
5. Current carry weight is derived from real possession + real weight.
6. Future UI is a reader/composer.
7. Child implementations remain independently replaceable even though they were delivered in one coordinated slice.
