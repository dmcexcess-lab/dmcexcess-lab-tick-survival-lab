# Tick Survival Lab — Settled Architecture Map

Status: **active ownership/context map**

Purpose: tell an AI engineer what is already settled so reasoning is spent on genuine problems rather than rediscovering architecture. This is not implementation history.

`CLOSED` = do not redesign without a concrete defect.  
`ESTABLISHED` = extend the existing owner/pattern.  
`OPEN` = release work remains, but existing authority boundaries still apply.

## Core authority chain

| Concern | Owner / rule | Status |
|---|---|---|
| WHERE | spatial geometry/language | CLOSED |
| WHAT | authoritative persistent world entities/current physical truth | CLOSED |
| WHEN | `TickKernel`; single deterministic clock/action scheduler | CLOSED |
| Global planning/coherence | System 00D | CLOSED |
| Local physical generation | System 20 | CLOSED |
| Building interiors/grammar | System 19 | CLOSED |
| Logical materialization/technical activation | System 00F; never morphology | CLOSED |
| Rendering | presentation only; never gameplay truth/physics | CLOSED |
| Input | emits intent; simulation owns consequences | CLOSED |
| UI | presentation/intent only; owns no gameplay truth | CLOSED |

Technical chunks/streaming boundaries never become logical geography or persistent identity. Generation creates virgin truth once; WHAT and typed mechanic stores own subsequent reality.

## Player/world systems

| System | Settled rule | Status |
|---|---|---|
| Combat/time | shared ticks, variable durations, commitment/interruption, simultaneous due-tick consequences | CLOSED foundation |
| Mob pressure | ordinary physical movement/contact produces bounded force propagation; no separate horde brain | CLOSED |
| Fear | canonical `CALM`/condition path; no parallel fear meter | CLOSED |
| Perception | existing bounded perception/LOS path; observer pose participates in freshness/invalidation | CLOSED |
| Lighting | physical-light truth remains gameplay input; presentation is simple tile tint, not bloom/shadow spectacle | CLOSED |
| Infected cohort | active production cohort remains bounded at 8 unless a later explicit design/performance decision changes it | CLOSED for current release |
| Inventory/equipment | existing persistent containment/hand owners | ESTABLISHED |
| Health/injury | existing health/injury owners | ESTABLISHED |
| Sustainment | `SurvivorSustainmentActionService` and condition owners | ESTABLISHED |
| Food/drink | selected carried item -> contextual EAT/DRINK through inventory | CLOSED interaction rule |
| Rest/sleep | clicked furniture/world object -> contextual REST/SLEEP | CLOSED interaction rule |
| Potable water | clicked powered potable fixture -> contextual DRINK | CLOSED interaction rule |
| Survival UI | no permanent generic EAT/DRINK/TAP/REST/SLEEP strip | CLOSED |
| Crafting/repair/deconstruction | extend existing item/tool/resource/action owners; no parallel crafting stack | ESTABLISHED |
| Vehicles | preserve existing transport identity/movement/storage/fuel/repair owners | ESTABLISHED |
| Utilities | existing power/water service truth; failures/repairs arise from world action | ESTABLISHED |
| Persistence | existing authoritative stores/snapshots -> checksum-verified versioned durable session; saved seed reconstructs runtime owners before in-place restore; primary/backup user storage; no duplicate gameplay truth | CLOSED — Phase 3 |

## Durable continuation ownership

- `DurableSessionStore` owns only conventional file-format/storage concerns: versioned envelope, checksum verification, primary/backup rotation and storage capability reporting.
- `EnvironmentalPressureGameMain` assembles/restores one session from the already-authoritative world, WHEN, streaming registry and mechanic-owner snapshots. It does not become a second gameplay state owner.
- `StartupMenu` owns truthful New Game/Continue presentation and launches Continue with a validated saved session.
- App focus/background hard pause is lifecycle state. A restored session clears the application hard-pause bit while preserving the saved WHEN queue and committed action truth.
- Streaming/materialization identity is restored from the existing registry plus WHAT; reopening or crossing regions must not regenerate already-materialized facts.

## World-generation boundaries

- Keep the existing generated map, roads, buildings, terrain, stable identities and streaming architecture.
- Do not restart/rewrite global world generation without a concrete release blocker.
- Parking/garage/carport enrichment is a later deterministic site-enrichment problem, not permission to regenerate buildings.
- Environmental stories are persistent arrangements of real existing objects/mechanics, not a new NPC/society simulation.

## Explicitly retired / forbidden parallel systems

- living survivor/raider/follower/social runtime for this release;
- settlement/colony management;
- freeform house/base construction engine;
- duplicate clock, inventory, health, position, condition or persistence truth;
- presentation-owned consequences;
- generic survival action strip;
- routine historical gameplay-suite gates or retired twelve-seed matrix.

## Performance contract

Phone/Safari is first-class. Turn-based systems do not wake because a render frame occurred. Bound recurring work to relevant actors/changed state; prefer cached/batched/coarse work where truth is preserved. Streaming may change representation/scheduling but not persistent causal truth.

See `PERFORMANCE_NORTH_STAR.md` only when the active slice contains a concrete performance issue or cost-sensitive new system.

## Extension rule

Before inventing a new owner, answer in order:

1. Is the concern already listed here? Use that owner/rule.
2. Does current source contain the established owner named by the active task? Extend it.
3. Is this a conventional engineering problem? Use the conventional solution consistent with the owners above.
4. Only then consider a new architecture decision.

A new architecture decision that changes this map must be justified by a concrete requirement/defect and documented here after implementation.
