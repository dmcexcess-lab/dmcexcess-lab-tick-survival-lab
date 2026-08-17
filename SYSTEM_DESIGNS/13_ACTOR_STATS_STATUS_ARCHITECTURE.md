# Tick Survival Lab — 13 Actor Stats / Status Architecture

Status: **APPROVED UMBRELLA — all six child systems explicitly approved for implementation on 2026-08-16**

Approval basis: the user specified the desired visible set — moodlets, HP, fatigue, hunger, thirst, sleep, carry weight, and skills with levels — approved the modular peer-domain architecture, then explicitly approved **all of System 13** for implementation so work can proceed toward the canonical demo.

## Goal
Provide a simple readable survivor status surface while keeping Health, Needs, Skills, item weight, Carry, and Moodlets independently replaceable and extensible.

## Core rule
> **Actor condition is composed from typed peer domains keyed by stable WHAT actor ID. There is no universal ActorStats dictionary.**

The future Stats/HUD layer is a reader/composer. It never owns simulation truth.

## Child systems

### 13A Actor Health / Injury — APPROVED
Design: `13A_ACTOR_HEALTH_INJURY.md`.
Owns current/max HP plus injury type/body-region/severity/stabilization/treatment. V1 recovered HP baseline is 100. HP zero does not itself implement death/corpse transition.

### 13B Actor Needs / Rest — APPROVED
Design: `13B_ACTOR_NEEDS_REST.md`.
Owns 0..100 fatigue, hunger, thirst, and sleep-pressure values. Fatigue is short-horizon exertion; sleep pressure is longer-horizon debt. No hidden frame-time progression. A read-only provider uses golden Tick's fatigue action-duration pressure through 03.

### 13C Actor Skills — APPROVED
Design: `13C_ACTOR_SKILLS.md`.
Owns semantic skills, level, and XP. V1 uses recovered Combat, Scavenging, Survival, Medical, Technical, Social; levels 0..10; XP threshold `20 + level * 15`.

### 13D Item Physical Properties — APPROVED
Design: `13D_ITEM_PHYSICAL_PROPERTIES.md`.
Owns semantic item physical definition facts beginning with positive integer weight in grams. Missing weight classification is UNKNOWN rather than zero.

### 13E Actor Carry / Encumbrance — APPROVED
Design: `13E_ACTOR_CARRY_ENCUMBRANCE.md`.
Owns persistent base capacity only and derives current carried weight from real 09 Hands + 11 Containment + 13D weight. Recovered v1 base capacity is 18,000 g. Current weight is never persisted. A read-only provider uses golden Tick's encumbrance timing pressure through 03.

### 13F Actor Moodlets — APPROVED
Design: `13F_ACTOR_MOODLETS.md`.
Derives readable statuses from real Health/Needs/Carry state. Ordinary threshold moodlets are not persisted.

## Stable identity
Persistent actor-state children key records by stable WHAT actor ID, never Node identity, UI index, controlled-player role, or renderer variant.

## Numeric representation
- Health: integer current/max HP.
- Needs: independent integer 0..100 pressure scales.
- Skills: discrete level + XP.
- Item weight/carry capacity: integer grams.
- Carry ratio: integer basis points, 10,000 = 100%.
- Moodlets: semantic ID/severity/priority, not duplicated numeric state.

## Mutation / time rule
Persistent values change only through their owning domains. WHEN owns order/time but not meanings. No System 13 owner advances itself from `_process()`.

Future coordinators explicitly mutate state after real outcomes: damage -> Health, eating/drinking/rest -> Needs, completed activities -> Skills, item disposition -> automatically changes derived Carry.

## Composition seams
03 Actor Locomotion already provides a narrow modifier-provider contract. 13B Needs and 13E Carry may implement read-only providers through that seam without Movement importing their internals.

The later Stats Inspector may compose public reads/provider adapters, but does not become a simulation owner.

## Persistence pattern
Persistent children use stable IDs, deterministic snapshot/restore, mutation-safe reads, revision/version tracking where useful, and bounded semantic signals. 13D content catalog and 13F derived moodlets are not per-save duplicated state.

## Forbidden architecture
Do not create:
- one ActorStats.gd storing all domains;
- Health importing Needs internals;
- Needs importing Inventory internals;
- Carry mutating Hands/Inventory;
- Item Properties owning location;
- Moodlets mutating source domains;
- UI/render/reboot-owned stats;
- duplicate persisted carry totals.

## Recovery basis
Golden Tick `PlayerActor.gd` proves 100 health, 18 kg carry capacity, encumbrance/fatigue timing pressure. Same-owner First Fire proves 0..100 fatigue and six persistent skills with XP/level progression. System 13 recovers useful semantics while rejecting both historical god-object/dictionary ownership shapes.

## Tests
Each child has deterministic contract smoke coverage. A coordinated System 13 workflow may run the six child smokes plus protected regressions. Exact-final-SHA validation remains required before implementation is called complete.

## North-star fit
The player gets the meaningful status pressure of mini Zomboid without detailed physiology or a monolithic character record. New domains can be added later without rewriting existing owners.

## Approved decisions — 2026-08-16
1. Visible target: moodlets, HP, fatigue, hunger, thirst, sleep, carry weight, skills/levels.
2. 13A–13F are separate peer responsibilities.
3. All six child contracts are explicitly approved for implementation in one coordinated System 13 slice by newest user instruction.
4. Moodlets are primarily derived.
5. Current carry weight is derived from real possession + real weight.
6. Future UI is a reader/composer.
7. Child implementations must remain independently replaceable even though this prompt authorizes implementing them together.
