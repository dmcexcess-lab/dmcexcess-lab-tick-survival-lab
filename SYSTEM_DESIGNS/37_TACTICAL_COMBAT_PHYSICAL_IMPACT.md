# System 37 — Tactical Combat / Physical Impact

Status: **COMBAT FOUNDATION CLOSED — melee, firearms/ammunition/reload, generic death/corpse transition implemented + focused production-scene CI**

Approval basis: on 2026-09-07 the user approved combat centered on the existing WHEN clock, exact physical actor/item identity, committed versus interruptible actions, physical contact/rays rather than homing attacks, real Health/Fatigue consequences, System-23/26 perception and sound, and no combat-only shadow state.

## 1. Core rule

> **Combat is ordinary physical action under pressure.**

Combat has no second clock, action-point economy, animation cooldown truth, combat inventory, special health meter, or UI-owned target state. Every attack/reload is an ordinary WHEN action. Equipment, containment, Health, condition, world placement, collision and sound remain with their existing owners.

The combat foundation is now sufficient for lethal play against real actors. Knockdown/brace and broader weapon variety remain extensions; they are not blockers for the first infected phase.

## 2. Production composition

Production root:

`game/main.tscn -> CombatGameMain.gd -> VehicleGameMain.gd`

`CombatGameMain` composes:

- `CombatImpactProfileCatalog` / `CombatActionService` for melee and shove;
- `CombatInteractionOfferProvider` / `CombatPlayerController` for the real player route;
- `CombatSoundEmitterAdapter` for melee System-26 emissions;
- `FirearmProfileCatalog` / `FirearmState` / `FirearmActionService`;
- `FirearmDamageInterruptionService` / `FirearmSoundEmitterAdapter`;
- `CorpseState` / `ActorDeathTransitionService`.

No existing vehicle, movement, Health, condition, inventory/equipment, collision, perception or sound ownership was replaced.

## 3. Melee actions and physical contact

Implemented melee actions remain:

- `combat.strike_primary` — exact RIGHT HAND item;
- `combat.strike_secondary` — exact LEFT HAND item;
- `combat.strike_unarmed` — only when the relevant hand is actually empty;
- `combat.shove` — committed forward displacement attempt.

Strikes carry an explicit `combat.contact` phase. Facing is latched at action start, while attacker/target placement is re-read at CONTACT. The intended target is hit only if it is still physically in the strike cell; if it moved away, the strike does not home. If another living Health actor now occupies that exact contact cell, physical occupancy may make that actor the contact instead.

Light effective striking mass (<900 g) is WHEN `CANCELABLE`; heavy strikes (>=900 g) and SHOVE are `COMMITTED`. A real Health damage event requests ordinary interruption before contact. WHEN policy remains authoritative about whether the action actually stops.

CONTACT intents are resolved through the existing late same-tick impact batch so two same-tick attacks can both land before tactical decision pause. Queue/source ordering is not hidden initiative.

## 4. Exact melee item identity and physical impact

Combat never stores an `active_weapon` shadow reference. A melee action latches the exact WHAT ID already assigned to the anatomical hand and revalidates that same identity at CONTACT.

`CombatImpactProfile` describes reusable physical facts—contact mode, effective length, rigidity, leverage, handling/balance and contact transfer—not authored weapon damage numbers. Existing item mass and System-34 body/melee condition feed body-powered impact. Specialized point/blunt profiles remain for known tools such as the sharpened stake and stone hammer; ordinary hand-held items with real positive mass can receive the conservative generic blunt path.

System 13A remains the only HP/injury owner. Melee impact maps point/edge/blunt contact to existing puncture/laceration/blunt-trauma injury vocabulary. System 34 remains the only short-horizon endurance owner; combat does not recreate Stamina.

## 5. Firearm physical state

Firearms are not integer-ammo weapons.

`FirearmState` records exact persistent identities:

- firearm WHAT ID;
- exact inserted magazine WHAT ID;
- exact chambered live-round WHAT ID.

A firearm and its compatible magazine are real containment owners. A magazine's ammunition quantity is derived from the exact round entities physically contained by that magazine. Chambering moves one exact round entity from magazine containment into firearm containment. There is no authoritative `ammo_count` integer.

The first physical profile vocabulary includes:

- `item.firearm.service_pistol`;
- `item.firearm.magazine.9mm`;
- `item.ammo.9mm_round`.

Their masses are registered in the canonical item physical-property catalog. This is a minimum truthful firearm vocabulary, not a commitment to only one future firearm type.

## 6. Fire and aim are WHEN actions

Implemented firearm actions:

- `combat.fire_snap` — COMMITTED, discharge at tick +2, total 4 ticks;
- `combat.fire_aimed` — COMMITTED, discharge at tick +5, total 7 ticks;
- `combat.reload` — RESUMABLE, with physical eject/insert/chamber phases.

Snap and aimed fire share the same firearm/state primitive. The difference is action commitment/time and usable physical range, not a second shooting subsystem.

At discharge, the service revalidates the same exact equipped firearm and exact chambered round. The projectile query follows the actor's latched forward direction across real terrain/collision cells. Current ranges are 6 cells for snap fire and 12 cells for aimed fire. The ray stops when geometry stops physical travel; it does not target-home to a clicked actor.

On a living actor hit, canonical Health receives damage and a critical torso gunshot injury. The exact chambered live-round WHAT entity is consumed. Semiautomatic cycling then moves the next exact round from the inserted magazine into the chamber when one exists.

## 7. Reload has truthful intermediate state

Reload is a real WHEN `RESUMABLE` action with distinct physical phases:

1. `combat.reload_eject` — the old exact magazine leaves the firearm and returns to actor containment;
2. `combat.reload_insert` — the selected exact compatible magazine moves from actor containment into the firearm;
3. `combat.reload_chamber` — one exact round moves from inserted magazine containment into the firearm chamber.

The selected firearm/magazine identities are latched in the action payload. If real damage interrupts reload, `FirearmDamageInterruptionService` asks WHEN to interrupt it. Because reload is RESUMABLE, already-completed phases remain physical truth and the unfinished action is retained. Resume continues from the remaining scheduled phases; it does not reset or secretly teleport ammunition.

This means interruption after ejection truthfully leaves an empty-magwell firearm, old magazine carried, and replacement magazine still carried until resume/insert occurs.

## 8. Firearm sound

`FirearmSoundEmitterAdapter` routes discharge into the existing System-26 sound owner. Gunshots use combat acoustic recognition/category with gunshot-specific event identity and high source power.

Combat owns no zombie-attraction radius. Future infected behavior must hear the same propagated/attenuated System-26 observations available to any listener.

## 9. Generic death / corpse transition

Death is downstream of Health, not a special firearm or infected rule.

`ActorDeathTransitionService` watches the canonical Health transition from HP > 0 to HP <= 0. For any enrolled living actor it:

1. force-fails the actor's active WHEN action;
2. creates persistent corpse identity `corpse.<actor_id>` with semantic `object.corpse`;
3. enrolls that corpse as a real containment owner;
4. clears living right/left hand assignment;
5. moves the actor's exact directly carried item identities into corpse containment;
6. removes living ACTOR placement;
7. places the corpse in the same physical location;
8. records source actor <-> corpse provenance in `CorpseState`.

Items are moved, not cloned into a loot table. A physical item that existed before death remains that same WHAT identity afterward.

`object.corpse` has an explicit non-blocking collision profile. Corpses therefore remain physical/persistent without accidentally becoming UNKNOWN blockers.

## 10. Player-facing route

The existing center on-foot touch control remains the practical `STRIKE` / `player.combat_forward` semantic route, with desktop `F` using the same intent.

`CombatPlayerController` now routes that intent through the equipped firearm owner first. If there is no firearm, it falls back to the established forward melee action. If a firearm is equipped with an empty chamber, the same intent can begin the lawful reload path instead of inventing a separate UI-owned ammo state.

Exact visible actor melee targeting remains available through the shared System-29 chooser. ACTOR occupancy alone grants no interaction; `CombatInteractionOfferProvider` still gates offers through canonical Health, reach and current System-23 visibility.

## 11. No Combat skill

The canonical skill catalog remains Awareness, Stealth, Mechanical and Survival. System 37 does not recreate the retired Combat skill. Current combat results arise from physical state, player timing/facing, exact equipment, condition/Fatigue, occupancy/collision and Health.

## 12. Focused verification history

### Melee foundation

Fresh prompt-local verifier at the time:

- `game/scripts/ci/PromptCombatActionsSmoke.gd`
- `.github/workflows/prompt-combat-actions.yml`

Successful melee functional head:

- `9e06f6949062c7598a6a595ca6daed5e369e52f8`
- `Prompt Combat Actions` run `34165616529` — SUCCESS.

That run proved exact hand-item identity, COMMITTED/CANCELABLE behavior, non-homing contact, canonical injury/Fatigue/sound, practical touch STRIKE, and mutual same-tick hits.

### Firearm / reload / death + first real infected integration

Current prompt-owned verifier:

- `game/scripts/ci/PromptCombatFirearmDeathSmoke.gd`
- `.github/workflows/prompt-combat-firearm-death.yml`

Integrated functional head:

- `e997ac13b74a1955fb5fe152f1b0753886009acc`
- `Prompt Combat Firearm Death` run `34170545140` — SUCCESS.

It boots real `res://main.tscn` and proves:

1. firearm and corpse/death production owners boot;
2. exact firearm/magazine/round identities use real containment;
3. reload is WHEN RESUMABLE;
4. ejection creates real intermediate state before interruption;
5. real Health damage interrupts reload without erasing completed progress;
6. resume inserts the same exact selected magazine and chambers an exact live-round identity;
7. magazine quantity is derived from remaining exact round entities;
8. snap fire is a timed physical forward discharge;
9. the exact chambered round is consumed;
10. System-26 receives the firearm discharge;
11. lethal damage triggers generic corpse transition;
12. death force-fails an active WHEN action;
13. exact equipped/carried item identity survives in corpse containment;
14. corpse collision is explicitly non-blocking;
15. semiautomatic cycling chambers the next exact round;
16. the same generic death path works on the first production resident-backed infected described by System 38.

Early focused runs found two narrow integration defects and were repaired in production rather than weakening assertions: the initial death listener used the wrong five-argument Health signal contract, and the first infected hydrator incorrectly assumed Skill/Carry states exposed `is_ready()` methods. The final unchanged integrated assertions are green on the head/run above.

## 13. Deliberately deferred extensions

Combat foundation closure does **not** mean every future weapon/body mechanic is implemented. Deferred extensions include:

- broader firearm, ammunition and magazine types;
- manual-action firearm cycling / malfunctions if later justified by physical item state;
- armor-ballistics refinement beyond current Health/injury path;
- true stability/knockdown and brace owners;
- richer corpse decomposition/dragging if supported by future condition/physical primitives.

These are extensions, not substitutes for the now-closed exact firearm/ammunition/reload/death truth.

## 14. Next phase boundary

The combat prerequisite for infected play is closed. System 38 now hydrates the first real infected from authoritative island population records.

Next infected work should give that resident-backed actor an autonomous **perception -> intention -> ordinary WHEN action** loop using existing System-23 vision, System-26 hearing, movement and System-37 combat. Do not build a custom zombie clock or duplicate combat/movement owners.

## 15. North-star fit

System 37 now provides lethal combat without becoming a conventional combat layer bolted onto the simulation:

- one authoritative WHEN clock;
- physical commitment/interruption;
- exact hand item identity;
- exact firearm/magazine/live-round identity;
- physical non-homing melee contact and firearm rays;
- real reload intermediate state;
- canonical Health/injury/Fatigue;
- real propagated sound;
- same-tick concurrent impact;
- generic actor death and persistent exact-item corpse transition;
- UI routes actions but owns no combat truth.
