# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once before the next repository operation.

## Current checkpoint — SURVIVAL RELEASE PHASE 2 CANONICAL FEAR COMPLETE — 2026-09-25

Phase 1 remains complete. Phase 2A commitment windows, Phase 2B simultaneous melee consequences, Phase-2C causal movement/shove/death ordering, and the closed mob-force core remain protected.

The user approved the complete canonical fear contract on 2026-09-25 and this operation implemented it as one coherent system rather than another sequence of micro-slices.

Starting main for this operation: `7790741157aedf6a56926eb1ace89e9600b6051a`.

Functional/executable owning head: `82deda793337ea49b7cd47e52325e346bcbafec7`.

Focused production verifier head/run: `82deda793337ea49b7cd47e52325e346bcbafec7` / `36199423801` — **SUCCESS**.

Focused marker:

`PHASE2_FEAR_OK aggregate_cap=true explicit_effects=true escape_responsive=true injury=true pressure=true recovery=true`

Functional-head Pages run `36199423817` — **SUCCESS**.

Documentation head immediately before this final handoff write: `00b9560717232e3feb9286f7a0f2d7873ff87dcb`.

This `README_CONTEXT.md` commit is the final repository write for the operation. Identify its exact SHA from `main`; everything after it is read-only verification.

## Prompt-local verifier lifecycle

The previous crowd-pressure closure verifier pair was deleted before fear code work:

- `game/scripts/ci/Phase2CCrowdPressureClosureSmoke.gd`
- `.github/workflows/phase2c-crowd-pressure-closure.yml`

Fresh current pair:

- `game/scripts/ci/Phase2FearSmoke.gd`
- `.github/workflows/phase2-fear.yml`

The next code prompt must delete this pair before changing code and create a brand-new focused verifier/workflow for the next module.

## CANONICAL FEAR — COMPLETE

Fear uses the existing persistent `CALM` condition as its only authoritative state.

No second fear/panic meter exists.

### Same-timestamp fear pressure

New owner:

- `ActorFearPressureService.gd`

Observation/consequence systems no longer mutate Calm independently. They submit fear pressure to one current-timestamp owner.

Current production fear sources:

- visible infected threat from canonical Perception;
- sufficiently strong recognized `threat` Sound observations;
- bounded injury shock from canonical Health damage;
- resolved physical crowd pressure from Movement.

Pressure generated on one authoritative timestamp is aggregated before mutation.

The total Calm loss is capped at **20 points per tick**.

This prevents callback order or multiple simultaneous danger channels from producing arbitrary runaway fear.

The fear owner publishes one `fear_resolved` consequence after applying the capped aggregate.

## Fear tiers and explicit mechanical effects

Existing condition tier boundaries remain canonical.

Fear interpretation:

- Calm 45–100: **Composed** — no fear penalty.
- Calm 30–44: **Uneasy** — player-facing warning only.
- Calm 15–29: **Afraid** — +15% deliberate-action duration, +10% Fatigue gain, -5% hold/bracing resistance.
- Calm 0–14: **Terrified** — +30% deliberate-action duration, +20% Fatigue gain, -10% hold/bracing resistance.

The existing Moodlet path continues to present `Uneasy`, `Afraid`, and `Terrified`.

### What fear does NOT alter

Calm has been removed from the generic condition potency calculation.

Fear therefore no longer silently modifies:

- maximum Health;
- general movement speed;
- carry capacity;
- body-powered/melee damage;
- raw locomotion force;
- raw shove force.

Fear also never:

- chooses actions for the player;
- forces fleeing;
- drops equipment;
- rejects a valid command merely because the actor is afraid;
- creates random loss-of-control behavior.

## Player-agency / escape rule

Fear affects deliberate coordination-heavy execution rather than gross escape behavior.

Fear timing is currently wired into:

- melee strikes;
- aimed firearm discharge;
- firearm reload phases;
- first aid;
- crafting.

Escape/reactive actions retain normal timing:

- ordinary walk;
- run;
- shove;
- snap fire.

The focused verifier explicitly proves terrified locomotion duration remains unchanged while deliberate melee becomes slower, and that terrified shove retains its normal 6-tick duration.

## Fear and Fatigue

Fear increases Fatigue gain explicitly:

- Afraid: ×1.10;
- Terrified: ×1.20.

This flows through the existing canonical condition/exertion path.

Fear itself does not create Fatigue recovery penalties through a parallel subsystem.

## Fear and physical bracing

Only `physical.hold` resistance receives the explicit fear reduction:

- Afraid: ×0.95;
- Terrified: ×0.90.

Raw shove and locomotion force are unchanged.

This allows a frightened survivor to be somewhat easier to physically displace without creating a runaway loss of strength.

## Visible-threat fear

`ConditionPerceptionFearAdapter` now uses encounter-aware distance bands instead of a flat repeated per-zombie Calm mutation.

Current bands:

- far;
- near;
- close;
- contact.

Crossing into a worse band creates additional pressure.

Additional simultaneous visible infected contribute with diminishing weight rather than linearly charging the full amount for every body.

The same visible threat does **not** repeatedly charge fear merely because Perception refreshes.

Encounter memory resets only after a meaningful visible-threat-free interval: currently five in-game minutes.

## Heard-threat fear

`ConditionHeardFearAdapter` now submits bounded pressure instead of mutating Calm directly.

Only observations already recognized by Sound as category `threat` qualify.

Current perceived-strength thresholds:

- >= 0.65: modest fear pressure;
- >= 0.85: stronger fear pressure.

This adapter does not expose hidden exact source identity or location.

## Injury fear

`ConditionInjuryFearAdapter` now owns the Health-to-fear seam.

Damage creates a bounded shock pulse based on damage magnitude.

The old direct `ActorConditionService` injury-to-Calm mutation was removed, so injury now participates in the same same-tick fear aggregate as other danger.

## Crowd-pressure fear

Movement now exposes one resolved `physical_pressure_resolved` consequence summary for psychological consumers.

`ConditionPhysicalPressureFearAdapter` interprets the physical result without owning force:

- resisted body pressure creates modest fear;
- actual displacement creates stronger fear;
- pressure trapped/terminated against geometry creates the strongest current crowd-pressure fear impulse.

This does **not** reopen or alter the closed mob-force architecture. Fear consumes its result.

## Recovery / anti-spiral rule

Calm still recovers analytically toward neutral 60 as authoritative WHEN advances.

Current tuning:

- approximately +25 Calm points per in-game hour when below neutral;
- 0 Calm reaches neutral in roughly 2.4 in-game hours if no new fear pressure occurs.

Fear state itself never generates additional fear pressure.

This prevents a self-sustaining psychological feedback loop.

Decision pause advances no time, so it grants no free fear recovery.

## Focused verification

Fresh prompt-local production verifier:

- `game/scripts/ci/Phase2FearSmoke.gd`
- `.github/workflows/phase2-fear.yml`

Successful functional run:

- head: `82deda793337ea49b7cd47e52325e346bcbafec7`
- run: `36199423801`
- result: **SUCCESS**

Marker:

`PHASE2_FEAR_OK aggregate_cap=true explicit_effects=true escape_responsive=true injury=true pressure=true recovery=true`

The verifier boots the real production scene and proves:

1. three same-tick fear inputs aggregate before one Calm mutation;
2. the per-tick Calm-loss cap is exactly 20;
3. Calm no longer changes generic Health/speed/carry/melee-damage multipliers;
4. Terrified explicit multipliers are 13000 deliberate timing / 12000 Fatigue gain / 9000 hold resistance;
5. existing `Terrified` moodlet feedback remains visible;
6. ordinary movement timing is unchanged by terror;
7. deliberate melee timing increases under terror;
8. shove remains a responsive escape action;
9. first aid, crafting and firearm services are production-wired to the same fear timing query;
10. injury shock reaches the fear-pressure owner;
11. resolved body pressure reaches the fear-pressure owner;
12. visual threat bands and heard-threat classification are bounded as designed;
13. one in-game hour of recovery from 0 Calm reaches the intended roughly 25-point range.

## Focused repair history

The first verifier attempt exposed two test/tooling issues and one real production wiring mismatch:

- a malformed verifier line-continuation caused a parse failure;
- the verifier was given a watchdog/stage diagnostics so script failures terminate explicitly rather than hanging CI;
- script-chain verification then exposed that `System34GameMain` passed the new fear modifier to `SurvivorFirstAidActionService` while that service still had its old 10-argument constructor.

The first-aid constructor was repaired to accept/store the shared condition modifier query.

A dedicated prompt-local `--check-only` step now validates the fear-touched script chain before the runtime verifier.

The final functional run is green.

## Durable documentation updated

- `DESIGN_DECISIONS.md` records the approved fear/player-agency contract.
- `SYSTEM_DESIGNS/34_SURVIVOR_CONDITION_HEALTH_STAMINA_MOODLETS.md` records the implemented canonical fear owner, sources, tiers, explicit effects, recovery and focused evidence.
- `ROADMAP.md` marks canonical fear complete within Phase 2.
- `CHANGELOG_LATEST.md` records implementation and repair evidence.

## Current release direction

Core loop remains:

**scavenge -> fight -> craft -> survive**

on the persistent map with day/night, weather, power, water and vehicles.

A base remains an existing fortified house/building with supplies, generator and well.

Human survivor society, raiders and human followers remain outside release scope. Pets remain future bounded scope.

Phase-2 defining mechanics now include:

1. explicit interruptible -> committed action windows;
2. simultaneous same-tick melee consequences;
3. terminal death after already-earned same-tick spatial consequences;
4. causal `S_t -> transition -> S_t+1` ordering;
5. conditional origin release / destination arrival;
6. atomic movement chains and deterministic physical contests;
7. head-on edge conflicts;
8. shove as shared forced trajectory;
9. aggregate multi-body mob pressure with natural exhaustion and static termination;
10. canonical fear with bounded same-tick pressure, explicit action/exertion/bracing effects and analytic recovery.

**Mob-force core is complete. Canonical fear is complete.**

## NEXT OPERATION

Continue Phase 2 with the next remaining release blocker: **zombie callback/perception performance under ordinary combat load**.

Do not redesign mob force or fear.

Target the existing eight-infected production cohort first.

The next bounded operation should:

- delete this prompt's fear verifier/workflow before code changes;
- create a fresh performance-focused prompt-local verifier/workflow;
- measure actual per-decision/per-tick infected callback and perception work on the production scene;
- identify repeated Perception/visibility/path/acquisition work that is duplicated within one authoritative decision/timestamp;
- remove or cache only proven redundant work without changing perception truth or zombie intentions;
- preserve dumb/simple infected behavior and all current causal movement/combat/fear semantics;
- report before/after timings from the same focused route;
- avoid broad renderer/streaming optimization unless the evidence shows it is the actual blocker.

After callback/perception cost is bounded, Phase 2 can move to coherent overlapping consequence presentation and then crowded-fight/Safari acceptance.

## Protected behavior

Preserve:

- WHERE / WHAT / WHEN authority and one clock;
- `S_t -> transition -> S_t+1` causal ordering;
- Phase-2A commitment windows;
- Phase-2B simultaneous melee consequences;
- deferred terminal death after surviving current-tick spatial consequences;
- frozen physical state for current-tick contests;
- same-destination stat arbitration;
- release-chain/fixed-point occupancy semantics;
- head-on edge conflicts;
- shove-vs-move arbitration;
- closed aggregate multi-body mob-force system;
- ordinary locomotion contact pressure;
- canonical fear as CALM only;
- fear aggregation cap and encounter-aware observations;
- explicit Afraid/Terrified effects;
- responsive movement/run/shove/snap-fire escape timing;
- no forced flee/random panic control theft;
- existing player/infected Health, inventory, movement, perception, condition, skills and equipment;
- day/night, weather, utilities and vehicles;
- persistence/terrain/streaming;
- simple infected intention selection with no crowd choreography;
- no live survivor/raider/human-follower/social runtime;
- pets only as future bounded scope;
- input locked until legitimate decision pause;
- hard application pause;
- STATS / INVENTORY / CRAFT / MENU ownership;
- no player-facing ZOMBIES / ZOMBIES NEARBY indicator;
- LOADING behavior unless explicitly replaced later.

Historical gameplay suites and the retired twelve-seed matrix are not current gates.
