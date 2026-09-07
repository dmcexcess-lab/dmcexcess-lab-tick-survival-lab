# System 38 — First Infected / Population-Backed Hydration

Status: **FIRST REAL INFECTED HYDRATED + PERCEPTION / INTENTION / WHEN BEHAVIOR CLOSED IN PRODUCTION**

## 1. Core rule

> **An infected is a real human resident in an infected state, not a disconnected zombie fixture.**

The island population planner already owns how many residents exist in each settlement and household. System 38 does not create an extra population. It deterministically projects individual identities from already-counted household resident slots only when an individual must enter active simulation.

Infection is an overlay on the shared human actor identity. The hydrated actor remains semantic `actor.survivor` so canonical Health, equipment, inventory, locomotion, condition, carry, skills, collision, perception, sound and WHEN action systems remain reusable.

## 2. Existing population truth reused

`IslandWorldPlanner` already runs `IslandPopulationPlanner` while generating the global world plan and retains:

- `population_settlements`;
- `resident_population`;
- `infected_population`;
- `survivor_population`;
- `local_area_manifest`.

Each settlement population record contains household records tied to generated buildings, including building identity, household resident capacity, settlement/site identity and aggregate resident/infected/survivor counts.

The planner intentionally does not pre-create thousands of person WHAT entities. System 38 preserves that aggregate truth and materializes an individual only when needed.

## 3. Deterministic resident projection and infection

`PopulationResidentProjection` converts already-counted household capacity into stable resident slots on demand. For each household building with capacity N it derives:

`resident.<building_id>.<ordinal>`

The projected record retains resident ID, source building, resident ordinal, settlement/site identity and generated home cell. It does not increment population totals.

A stable infection score is derived from world seed plus building identity and resident ordinal. Resident slots are ordered by that score and exactly each settlement's existing `infected_population` count is marked infected. The same world plan therefore produces the same infected resident identities without inventing population.

The first active infected prefers the central playable area and selects the nearest deterministic infected resident record to the player reference cell, with fallback to another valid infected resident only if the preferred site has none.

## 4. Infection state overlay

`InfectedState` stores resident provenance for hydrated infected actors. It does not replace the actor with a parallel zombie species.

A valid infected record requires the same exact resident/actor ID, `infected = true`, a real source building ID and a positive household resident ordinal. The actor remains `actor.survivor`: infection changes state and behavior, not the physical fact that this is a human body using shared simulation owners.

## 5. Hydration into active simulation

`FirstInfectedHydrationService`:

1. selects one deterministic infected resident slot;
2. reads its real generated home cell;
3. finds a real clear materialized cell near that household;
4. creates the exact resident ID as an `actor.survivor` WHAT entity;
5. places it on the normal ACTOR channel;
6. enrolls it in shared locomotion, hand equipment, inventory containment, Health, skills, carry and System-34 condition state;
7. records infection/provenance in `InfectedState`;
8. returns the exact hydrated actor identity/record/cell.

`CombatGameMain` performs this after System-37 combat composition boots using the already-generated global plan. It does not rerun island population/local-area generation just to obtain one actor.

## 6. Physical spawn rule

The infected remains materially tied to its household record, but active placement must also respect the materialized playable world. The hydrator searches a bounded radius around the source home and uses the existing spatial/collision query to choose a real clear cell. If no valid cell exists, hydration fails closed.

## 7. First infected behavior adapter

`FirstInfectedBehaviorService` is the first production autonomous behavior adapter. It owns **only intention selection**.

It does not own:

- a second clock or frame update loop;
- visual truth;
- hearing/source truth;
- movement/collision;
- Health;
- combat damage;
- attack cooldowns;
- teleport/path snapping.

It consumes observer-scoped information and submits ordinary actor actions into the existing owners.

The implemented intention vocabulary is intentionally small:

- `infected.idle`;
- `infected.pursue_visible`;
- `infected.pursue_last_seen`;
- `infected.investigate_sound`;
- `infected.attack_visible`.

This is sufficient to prove the simulation chain without starting a bespoke AI framework before the underlying owner contracts are known to work.

## 8. System-23 visual behavior

Production creates a dedicated `ObserverPerceptionService` for the exact resident-backed infected. It shares:

- the canonical world/door state;
- the same WHEN clock;
- the shared `PerceptionMemoryStore` under the infected's own observer ID;
- the same visual-acquisition provider used by the player, so physical lighting/acquisition rules remain common.

Visual behavior reads only the infected observer's actor observation and `VISIBLE` state.

When the player is currently visible:

- the current observed player cell becomes the target;
- if the player is in physical forward contact, intention becomes `attack_visible`;
- otherwise intention becomes `pursue_visible`.

When current visibility is lost but a prior actor observation remains, the infected may pursue the **last seen cell**. It does not read the player's current world placement to cheat around LOS.

## 9. System-26 hearing behavior

The exact infected actor is registered as an ordinary `SpatialSoundService` listener.

Behavior consumes only `HeardSoundObservation` data. In particular, it uses the observer-safe `perceived_cell`, strength/certainty/tick metadata and never receives or reconstructs an exact hidden source actor/cell from the sound system.

When the player is unseen and a useful external cue is heard, intention becomes `investigate_sound` and the target actor identity remains empty.

The investigation target is latched to the uncertain perceived cell so ordinary self-generated footsteps do not repeatedly replace an external investigation with a fake exact source. A cue localized to the infected's own occupied cell is not used as an investigation destination.

## 10. Ordinary WHEN movement

There is no infected update clock.

The behavior adapter reacts to simulation events such as perception/sound changes and shared WHEN action transitions. While the player is decision-paused, perception/intention may update but the infected does not advance merely because render frames pass.

When the player commits an action and the shared WHEN clock opens, a ready infected may submit an ordinary action at that same world tick. Subsequent infected action completions can select/submit the next ordinary action while the world remains running.

Pursuit/investigation uses the existing movement service:

- normal turn-left/turn-right actions;
- normal step-forward actions;
- normal collision/traversal validation;
- deterministic directional preference;
- only a small bounded left/right local detour when a direct step is blocked.

Full many-actor navigation is deliberately not invented in the one-infected proof. Every actual movement consequence remains owned by the existing movement/world/collision systems.

## 11. Ordinary System-37 attack

When the currently visible player physically occupies the infected's forward contact cell, the behavior adapter asks the existing `CombatActionService` for lawful strike offers and submits the first lawful ordinary strike path.

The current empty-handed first infected therefore uses the existing `combat.strike_unarmed` action. Contact timing, physical occupancy, misses, Health/injury consequences, exertion and System-26 combat sound remain System-37/shared-owner behavior.

There is no infected-only damage number, attack timer or aggro hit routine.

## 12. Death/corpse shutdown

System 38 still owns neither Health nor corpse truth.

When canonical Health reaches zero, the generic death service removes living ACTOR occupancy and creates persistent corpse truth. `FirstInfectedBehaviorService` observes the loss of living Health/placement and stops. A dead infected cannot submit another movement or combat action.

`InfectedState` retains the exact resident provenance after death so the corpse/dead resident is still traceable to the same population slot.

## 13. Focused verification

Current prompt-owned verifier pair:

- `game/scripts/ci/PromptFirstInfectedBehaviorSmoke.gd`
- `.github/workflows/prompt-first-infected-behavior.yml`

Verified functional head:

- `90f1c0c974afebcee71403bdd39c8ce4d7a52451`
- `Prompt First Infected Behavior` run `34171663807` — **SUCCESS**.

The real production-scene verifier proves:

1. the first resident-backed infected remains production-hydrated;
2. its behavior service and dedicated System-23 observer are running;
3. no autonomous actions advance merely from render frames during player decision pause;
4. a truthful visible player observation becomes `pursue_visible`;
5. opening the shared WHEN clock causes autonomous submission of ordinary movement;
6. pursuit reaches contact and submits an ordinary System-37 strike;
7. that strike produces canonical player Health damage;
8. resident/infection provenance is unchanged by pursuit/combat;
9. with player visual knowledge removed, a real propagated System-26 cue is heard;
10. the resulting intention is `investigate_sound` with **no exact source actor identity**;
11. the target cell equals System-26's observer-safe perceived cell;
12. the infected physically moves closer to that perceived cell through ordinary movement;
13. generic lethal Health damage stops behavior, removes ACTOR occupancy and prevents future WHEN submissions;
14. resident/infection provenance survives death.

### Verification failures repaired without weakening gameplay assertions

The first verifier run (`34171408724`) stopped at parsing because `CombatGameMain` redeclared two preload names already inherited from `GameMain`, and two verifier candidate cells needed explicit `Vector2i` typing. Those compile defects were corrected.

The next executable run (`34171525608`) showed correct perception/sound production truth but no autonomous action. The root cause was the verifier itself: scenario relocation did `unplace_entity()` then `set_placement()`. The intermediate unplaced state truthfully caused the production behavior to fail-stop because the infected temporarily had no living ACTOR placement. The smoke was corrected to use `WorldMutationService.set_placement()` as the existing atomic placement-replacement path. No production behavior assertion was weakened.

The unchanged behavior expectations then passed on `34171663807`.

## 14. Scaling boundary

The **one-infected simulation loop is now proven**. Do not reopen this behavior model merely to add variety before scaling work exposes a concrete need.

Still intentionally not solved here:

- materializing/activating many infected simultaneously;
- many-observer perception/hearing scheduling and cost control;
- full crowd/path navigation and congestion policy;
- group/herd behavior emerging from shared sound/occupancy;
- persistence/streaming policy for large inactive populations;
- survivor NPC behavior/dialogue.

## 15. Next operation

Scale the proven resident-backed loop carefully rather than designing new zombie abilities.

Start with a **small active infected cohort**, not island-wide hordes. Reuse the same resident projection/hydration, observer-safe System-23/System-26 knowledge and ordinary WHEN movement/combat submission per actor. Establish activation/streaming and bounded event-driven scheduling/performance rules, then measure before increasing active counts.

Do not introduce per-frame AI loops, magical shared target knowledge, global aggro radii, teleport path correction or a parallel combat clock to make scaling easier.

## 16. North-star fit

The first autonomous infected now emerges from already-existing simulation truth:

- world generation produced the household;
- population planning counted the resident and infection;
- deterministic projection names the existing resident slot;
- hydration gives that same identity a physical body;
- System 23 supplies observer-scoped visual knowledge;
- System 26 supplies uncertain heard observations;
- the behavior adapter chooses only an intention;
- shared movement and WHEN perform locomotion;
- System 37 performs physical attack;
- Health/generic death performs mortality/corpse transition.

No hidden zombie reality layer was added to make the first infected behave.
