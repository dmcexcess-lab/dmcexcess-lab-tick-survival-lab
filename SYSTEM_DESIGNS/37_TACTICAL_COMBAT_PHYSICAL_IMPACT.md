# System 37 — Tactical Combat / Physical Impact

Status: **MELEE / ACTION SLICE IMPLEMENTED + FOCUSED CI — broader combat closure still in progress**

Approval basis: on 2026-09-07 the user approved the combat design centered on authoritative ticks, committed versus interruptible actions, exact physical hand-item identity, physical contact rather than homing attacks, same-tick impact resolution, real Fatigue/Health consequences, perception-gated exact targeting, and System-26 sound.

## 1. Core rule

> **Combat is ordinary physical action under pressure.**

Combat does not own a second clock, initiative rounds, action points, animation cooldowns, or frame-time consequences. Every combat action is submitted to the existing WHEN kernel. The player may think indefinitely while decision-paused; once an action begins, world ticks advance and other actors' already-scheduled actions continue concurrently.

The first implemented slice establishes melee/contact truth and the player-facing action path. Firearm/ammunition/reload truth and generic death/corpse transition are intentionally not faked and remain required before combat is globally closed.

## 2. Production composition

Production root is now:

`game/main.tscn -> CombatGameMain.gd -> VehicleGameMain.gd`

`CombatGameMain` is composition/wiring only. It installs:

- `CombatImpactProfileCatalog`;
- `CombatActionService`;
- `CombatInteractionOfferProvider`;
- `CombatSoundEmitterAdapter`;
- `CombatPlayerController`.

Existing vehicle, movement, Health, condition, equipment, perception, sound and world-interaction owners remain authoritative.

## 3. Authoritative WHEN actions

Implemented semantic actions:

- `combat.strike_primary` — strike with the exact physical item in anatomical RIGHT hand;
- `combat.strike_secondary` — strike with the exact physical item in anatomical LEFT hand;
- `combat.strike_unarmed` — strike with an actually empty hand;
- `combat.shove` — committed short-range displacement attempt.

Strikes have an explicit `combat.contact` phase before action completion/recovery.

Current timing derives from real item mass plus physical handling profile rather than an authored weapon damage/cooldown table. Heavier objects generally reach contact/recover more slowly.

Current interruption rule:

- strike effective mass below 900 g -> WHEN `CANCELABLE`;
- strike effective mass 900 g or above -> WHEN `COMMITTED`;
- SHOVE -> WHEN `COMMITTED`.

A real `Health.damage_applied` event requests interruption only while the combat action is still before its CONTACT tick. WHEN itself decides the result from the action policy:

- light CANCELABLE strike -> canceled before contact;
- heavy COMMITTED strike -> ordinary damage does not cancel it.

This preserves the existing System-17 distinction between physical commitment and ordinary damage interruption instead of creating combat-only timing semantics.

## 4. Exact physical item identity

Combat has no `active_weapon`, no combat inventory and no shadow loadout.

A strike reads the existing anatomical hand assignment and records the exact WHAT item ID. At CONTACT it revalidates that the exact item is still assigned to that exact hand and still exists. If the physical striking item changed, the action fails rather than silently substituting another same-type item.

Unarmed striking is available only when an anatomical hand is actually empty.

## 5. Physical impact profiles, not weapon damage numbers

`CombatImpactProfile` contains reusable physical-contact facts:

- semantic item type;
- contact mode: blunt / edge / point;
- effective length;
- rigidity;
- leverage;
- balance/handling;
- contact-transfer factor.

It deliberately contains **no authored damage value**.

Known specialized profiles currently refine:

- sharpened stake -> point;
- stone hammer -> blunt;
- wood plank -> blunt;
- scrap metal -> blunt.

Any real hand-held item that already has canonical positive mass may still receive a conservative generic blunt profile. Missing mass fails closed; it is never treated as zero.

Current body-powered damage derives from:

`real mass × rigidity × leverage × contact transfer × System-34 melee/body multiplier`

with a bounded first-slice output. Firearm energy is not part of this calculation and must remain separate when firearm truth exists.

## 6. Contact is physical, not homing

A clicked actor establishes intended target identity; it does not grant homing.

At request time the actor must be in the attacker's physical forward contact cell. Facing is latched when the action begins.

At CONTACT:

- attacker placement and facing are revalidated;
- exact hand item is revalidated;
- strike cell is recomputed from physical attacker placement + latched facing;
- the intended target is hit only if still physically occupying the strike cell;
- if the intended target left, another living Health actor physically occupying that cell may be contacted instead;
- if nobody is there, the attack misses.

Therefore movement is already evasion. A target that leaves the strike cell before contact is missed without needing a magical dodge roll.

## 7. Same-tick impact batch

CONTACT phases do not immediately mutate Health.

They create pending impact intents for the current world tick and schedule one late same-tick `combat.resolve_impacts` event at priority 1000.

That resolution first snapshots actor occupancy for every involved strike cell and chooses every target before applying any damage/displacement mutation.

This prevents source-ID/queue ordering from becoming hidden initiative. Two attacks whose CONTACT phases occur on the same tick can both land before tactical decision pause, including mutual injury.

The same-tick batch still respects earlier physical world changes: if movement has already changed occupancy before the late impact snapshot, the strike sees that new physical reality.

## 8. Health and injuries

System 13A remains the only owner of HP/injury truth.

A resolved strike calls canonical Health damage and adds one broad persistent injury using existing body regions/severities. Contact mode maps to injury vocabulary:

- point -> puncture;
- edge -> laceration;
- blunt -> blunt trauma.

Broad body region selection is deterministic from stable actor/action identity.

Combat does not own a second health meter, wound store, pain/infection system or corpse truth.

## 9. Fatigue / exertion

System 34 remains the only short-horizon endurance owner; there is no combat Stamina pool.

Beginning a real strike or shove applies immediate physical exertion through System 34. The action records that post-cost Fatigue as a floor so analytic time recovery during the action cannot instantly refund the effort merely because System 34 does not yet classify combat action names as recurring exertion.

The existing System-34 melee/body multiplier also affects body-powered impact output.

## 10. Perception and exact target interaction

The neutral System-29 world-interaction discovery seam now admits `ACTOR` occupancy alongside loose items, objects and structures.

Important invariant:

> **ACTOR occupancy alone grants no interaction.**

Providers still own availability. `CombatInteractionOfferProvider` exposes combat actions only when:

- exact target is another actor;
- target has canonical Health > 0;
- target is physically in forward contact reach;
- at least one target cell is currently System-23 `VISIBLE`.

Remembered/unseen actors therefore do not leak exact current identity/location into the combat chooser.

The existing responsive shared `WorldInteractionPanel` presents exact actor actions with explicit tick duration and commitment labels.

## 11. Blind / forward strike

The normal on-foot controls now use the center combat slot for a 56 px `STRIKE` button; desktop `F` emits the same semantic `player.combat_forward` intent.

This route does not require a known visible target. It simply begins the best currently lawful physical forward strike from the player's actual hands. Physical occupancy at CONTACT decides whether anything is hit.

This is the intended future route for striking toward uncertain hearing cues in darkness without revealing hidden source truth.

Mounted controls still replace the on-foot control surface, so STRIKE is not exposed as an on-foot action while mounted.

## 12. SHOVE

SHOVE is a 6-tick COMMITTED action with CONTACT at tick +3.

At resolution it attempts to displace the contacted actor one cell directly away from the attacker using the existing spatial/collision query and WHAT placement mutation. If the destination is physically blocked, no fake displacement occurs.

A successful shove requests ordinary interruption of the target's active action. WHEN policy still determines whether that target action actually stops.

Knockdown/forced-failure truth is not yet implemented and must not be simulated by making every shove a forced failure.

## 13. Sound

Combat does not own hearing.

`CombatSoundEmitterAdapter` converts truthful combat phases into System-26 physical emissions:

- strike CONTACT emits `combat.swing`;
- resolved physical impact emits `combat.impact`, with bounded source power influenced by actual damage.

System 26 remains responsible for propagation, attenuation, hearing uncertainty, recognition and observer-safe presentation.

There is no zombie-attraction radius in Combat. Future infected must hear these same physical emissions through System 26.

## 14. No Combat skill

The canonical skill catalog remains Awareness, Stealth, Mechanical and Survival. Combat does not recreate the retired Combat skill.

Current physical outcomes depend on player decisions, timing, facing, exact equipment, mass/contact properties, Fatigue/condition, physical occupancy and Health.

## 15. Focused verification

Fresh prompt-owned verifier:

- `game/scripts/ci/PromptCombatActionsSmoke.gd`
- `.github/workflows/prompt-combat-actions.yml`

It boots real `res://main.tscn` and uses only a DEV-only survivor target to exercise the production combat path. It proves:

1. production combat composition boots;
2. exact visible actor enters the existing shared chooser;
3. touch STRIKE control is >=48 px;
4. chooser exposes tick/commitment information;
5. exact real stone-hammer identity drives a COMMITTED strike;
6. impact writes canonical HP loss + injury;
7. strike spends real Fatigue;
8. combat emits physical System-26 sound;
9. target leaving the strike cell before resolution causes a miss;
10. light sharpened-stake strike is CANCELABLE and real pre-contact damage cancels it;
11. heavy COMMITTED strike survives ordinary damage and still reaches contact;
12. different actors act concurrently on one WHEN clock;
13. two same-tick contacts both land before decision pause.

Initial run `34165344802` failed only because the smoke tried to observe synchronous cancellation by mutating a captured scalar. The log proved production had already removed the light action because the next player action was accepted. The verifier observation was repaired to a mutable result record without weakening the gameplay assertion.

Successful focused run:

- functional head `9e06f6949062c7598a6a595ca6daed5e369e52f8`;
- `Prompt Combat Actions` run `34165616529` — SUCCESS.

## 16. Deliberately unfinished combat closure

The following are **not implemented by this slice** and must not be represented as complete:

### Firearms / ammunition / reload

There is no authoritative firearm chamber/magazine/ammunition owner yet. Do not fake guns with a damage button or integer ammo counter. The next firearm slice should preserve the approved philosophy:

- exact firearm/ammunition physical identity;
- real chamber/magazine state;
- discharge as a timed phase;
- physical line/geometry at discharge;
- snap versus aimed timing from one primitive;
- System-26 gunshot sound;
- RESUMABLE reload with physical intermediate state.

### Death / corpse transition

Health still owns `HP == 0` only. Combat does not yet own or fake corpses.

A generic living-actor death transition is still required before infected play:

- force active action failure when physically dead;
- remove living/action-capable occupancy;
- create persistent corpse truth;
- preserve exact carried/equipped physical item identity without loot copying or disappearance.

### Knockdown / brace

A true stability/knockdown owner and brace action remain future combat extensions. COMMITTED currently means ordinary damage/shove interruption may be ignored; no arbitrary stun chance was added.

## 17. Next phase rule

Do not start production infected/NPC behavior until firearm/ammunition truth and generic death/corpse transition close the remaining combat foundation needed for practical lethal combat.

After combat closure, hydrate the first real infected from existing population records and make it submit ordinary WHEN movement/combat actions while perceiving through Systems 23/26.

## 18. North-star fit

This slice makes combat recognizably Tick Lab rather than a conventional combat layer placed on top of a turn-based game:

- decision pause belongs to readiness;
- actions occupy authoritative ticks;
- other actors act concurrently;
- commitment matters;
- physical movement can evade a strike;
- exact held items matter;
- damage emerges from physical properties and condition;
- sound propagates into the same simulated world;
- same-tick physical contact is genuinely concurrent;
- UI only exposes actions and never owns their truth.
