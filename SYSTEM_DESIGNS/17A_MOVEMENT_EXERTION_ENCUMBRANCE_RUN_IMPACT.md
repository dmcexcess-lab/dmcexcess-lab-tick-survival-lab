# 17A Movement Exertion / Encumbrance / Run Impact Revision

Status: **DRAFT — discussion only; do not implement until explicitly approved**

Drafted from the user direction on 2026-08-16:

> “Encumbrance and terrain should multiply the amount of tics movement takes as well as the amount of fatigue gain while running. At max encumbrance running is disabled and walking builds fatigue but its not effected by weight only terrain. Running into something should hurt. Exit isnt working for me lets just exit to google for now.”

This is a bounded revision of implemented Systems 03 / 13B / 13E / 17. The direct-Google Leave Game change is a small System 16 maintenance fix bundled with implementation after approval; it is not a new gameplay system.

## 1. Goal

Make movement effort physically coherent:

- terrain and carried load both multiply movement time;
- Run fatigue responds to both terrain and carried load;
- Walk fatigue responds to terrain but **not** carried load;
- at or above full carrying capacity, Run cannot begin;
- a committed Run into a known hard blocker causes a real physical impact and HP loss instead of becoming a harmless rejected button press;
- Leave Game on Web goes directly to Google instead of trying browser history first.

No stamina bar or persistent Run mode is added.

## 2. Existing behavior intentionally revised

System 17 currently:

- applies terrain first, then actor duration modifiers through an additive basis-point capability scale;
- blocks Run at fatigue 80+ but not at 100% carry capacity;
- adds exactly +1 fatigue per successful Run stride regardless of terrain/load;
- adds no Walk fatigue;
- rejects a Run before time is spent if either crossed cell is already Collision BLOCKED;
- System 16 Leave Game tries `history.back()` before Google.

17A intentionally supersedes those points only.

## 3. Movement-time multiplication

### Terrain remains the base physical cost

Existing terrain rules continue to own walk timing in ticks.

Examples:

- ordinary terrain: 10 walk ticks;
- hypothetical harder terrain: 14 walk ticks.

Run retains the System 17 pace rule:

`run_stride_base_ticks = ceil(walk_terrain_ticks * 0.60)`

Thus 10-tick terrain gives 6 base Run ticks per stride; 14-tick terrain gives 9.

### Actor factors become true multipliers

17A revises the 03 mobility provider duration composition from additive adjustments to deterministic multiplicative scales.

Canonical scales:

- standing step/run stance scale = `1.00`;
- crouched Walk stance scale = `1.40`;
- fatigue scale = `1.00 + (fatigue * 0.0065)`; fatigue 100 = `1.65`;
- encumbrance scale = `1.00 + (load_ratio * 0.75)`; exactly 100% capacity = `1.75`.

Resolved movement duration is the base terrain/run-stride cost multiplied by the applicable stance, fatigue and encumbrance scales, with one deterministic integer ceiling at the end.

Conceptually:

`movement_ticks = ceil(base_terrain_ticks * stance_scale * fatigue_scale * encumbrance_scale)`

For Run, `base_terrain_ticks` means the 60%-pace Run stride cost.

This makes terrain and encumbrance genuinely multiplicative instead of being combined as additive percentage pressure.

### Over-capacity walking

Carry above capacity remains representable.

- Walk remains legal unless some other capability blocks it.
- encumbrance timing continues scaling above 100% capacity.
- Run is separately blocked at 100%+ capacity.

## 4. Run eligibility at maximum encumbrance

`ActorCarryMobilityModifierProvider` gains an explicit Run-start block:

- `load_ratio_bp < 10000` -> Carry itself permits Run;
- `load_ratio_bp >= 10000` -> `CAPABILITY_BLOCKED`, reason `too_encumbered_to_run`.

This composes with the existing rules:

- crouched Run blocked;
- fatigue 80+ Run blocked;
- missing Carry/Needs truth fails closed.

Once a Run begins, start capability remains latched as in System 17. A later state change does not cancel stride two by itself.

## 5. Terrain effort factor

For v1 exertion, terrain difficulty is derived from the same semantic walk timing already owned by MovementTraversalPolicy rather than creating a second terrain-stat catalog.

Use the recovered normal walk baseline of 10 ticks:

`terrain_effort_factor = walk_terrain_ticks / 10.0`

Examples:

- 10-tick terrain -> `1.0x` effort;
- 14-tick terrain -> `1.4x` effort;
- 20-tick terrain -> `2.0x` effort.

This is deliberately simple. A future terrain system may split time-cost from exertion-cost if a real gameplay need appears.

## 6. Walking fatigue

Walking now causes real fatigue on **successful physical step commits**.

Walk fatigue ignores carried weight completely.

V1 proposed formula per successful forward/backward Walk cell:

`walk_fatigue_gain = max(1, ceil(terrain_effort_factor))`

Examples:

- normal 10-tick terrain -> +1 fatigue;
- 14-tick terrain -> +2 fatigue;
- 20-tick terrain -> +2 fatigue.

Encumbrance can make the Walk take longer, but it does not increase the Walk fatigue charge. This directly follows the user's distinction: **walking fatigue is terrain-driven, not weight-driven.**

A Walk canceled by damage before physical placement commit gains no Walk fatigue in v1. Partial-action exertion accounting is intentionally deferred rather than inventing a hidden fractional system.

A new or generalized stateless Movement exertion coordinator applies this through the public Needs mutation API. MovementActionService itself must not import Needs.

## 7. Running fatigue

Run remains more acutely demanding and continues charging per stride.

Run fatigue is multiplied by both terrain and encumbrance.

Use the existing encumbrance timing factor:

`run_encumbrance_factor = 1.00 + (load_ratio * 0.75)`

V1 proposed Run-stride fatigue:

`run_stride_fatigue = max(1, round(terrain_effort_factor * run_encumbrance_factor))`

Examples:

- normal terrain, empty/light load -> +1 per stride;
- normal terrain around 75% capacity -> +2 per stride;
- 14-tick terrain around 50% capacity -> +2 per stride;
- 20-tick terrain around 50% capacity -> +3 per stride;
- at 100%+ capacity Run is unavailable, so no Run fatigue is calculated.

The integer rounding is deliberate: Needs remains the existing coarse 0..100 model; 17A does not add fractional stamina or another persistence domain merely for sub-point exertion.

A successful Run stride gains its charge. A Run impact stride also gains its charge because the survivor still committed the sprint effort before hitting the obstacle.

## 8. Running into a blocker causes impact

### Core behavioral revision

A **known hard Collision BLOCKED** cell is no longer a zero-cost Run rejection.

Run request-time validation still rejects:

- UNKNOWN/unmaterialized space;
- missing/unclassified terrain;
- explicitly untraversable terrain;
- invalid actor/capability/timing truth.

But a known hard blocker is treated as a physical impact candidate.

This means pressing Run toward a wall/tree/other hard occupied cell is a real bad tactical choice instead of a harmless UI no-op.

### Stride behavior

At each committed Run stride phase:

- if target is CLEAR, move one cell normally;
- if target is BLOCKED, do not move into it, emit a semantic Run-impact fact, apply the attempted stride's Run fatigue, and terminate the Run;
- if target becomes UNKNOWN, fail closed without inventing impact damage.

Examples:

- blocker in cell +1 -> spend first-stride time, remain at origin, take impact damage, Run ends;
- cell +1 clear and cell +2 blocked -> reach +1 on stride one, then hit blocker on stride two, remain at +1, take impact damage, Run ends;
- blocker appears after Run begins -> same physical impact behavior at the affected stride.

No rollback occurs.

## 9. Run impact damage

Movement does not import Health.

Add a stateless `MovementRunImpactDamageService` (name may vary slightly) that observes the semantic Run-impact fact and calls public `ActorHealthState.apply_damage()`.

V1 proposed impact tuning:

- hard Run impact = **5 HP damage**.

The impact damage:

- is real HP loss and therefore emits existing `damage_applied`;
- does not cancel/undo the already-resolved physical Run impact through the ordinary Walk-damage interruption path;
- does not yet create an injury record;
- does not damage or knock back the blocker;
- may later be specialized by combat/doors/actors without making Movement own those systems.

This is a deliberately small consequence model: hit a solid thing at a sprint, lose HP.

## 10. Input and presentation

No new controls are added.

Existing Run controls remain:

- Shift+W / Shift+Up;
- native touch RUN button.

HUD/Stats already read real HP/fatigue and therefore update from these consequences without owning the mechanics.

## 11. Leave Game maintenance fix

System 16 Web Leave Game is simplified exactly as requested.

Current history/back attempt is removed.

Web behavior becomes:

`window.location.assign('https://www.google.com/')`

Native non-Web behavior may continue to quit normally.

No browser-history heuristic remains.

## 12. Expected implementation surface after approval

Expected production changes are bounded to:

- `game/scripts/simulation/actors/locomotion/ActorMobilityModifierProvider.gd`
- `game/scripts/simulation/actors/locomotion/ActorMovementCapabilityService.gd`
- `game/scripts/simulation/actors/needs/ActorNeedsMobilityModifierProvider.gd`
- `game/scripts/simulation/actors/carry/ActorCarryMobilityModifierProvider.gd`
- `game/scripts/simulation/movement/MovementTraversalPolicy.gd`
- `game/scripts/simulation/movement/MovementActionService.gd`
- replace/generalize `MovementRunExertionService.gd` into a focused movement-exertion coordinator if needed
- new stateless Run-impact -> Health coordinator
- `game/scripts/app/CanonicalDemoMain.gd` composition-only wiring
- `game/scripts/ui/CanonicalPlayerShell.gd` direct-Google maintenance fix
- focused System 17A smoke/workflow and protected regressions
- durable 03/13B/13E/17/System16 docs/context/changelog.

## 13. Protected modules

17A must not redesign:

- WHERE / WHAT foundations;
- Collision classification itself;
- WHEN internals;
- persistent stance shape;
- Health HP/injury model;
- Needs 0..100 persistent record shape;
- Carry derived weight/capacity truth;
- Inventory/Hands/Item Transfer;
- renderers/art/HUD/inspectors;
- demo map;
- generation/streaming;
- Reboot.

Movement continues to consume public Collision/terrain/capability contracts only.

## 14. Acceptance criteria

Implementation verification must prove at minimum:

1. normal terrain/empty healthy Walk remains 10 ticks;
2. normal terrain/empty healthy Run remains 6 ticks per stride / 12 total;
3. terrain and encumbrance multiply movement timing;
4. fatigue and stance still modify timing through public locomotion capability;
5. 100%+ carry blocks Run with `too_encumbered_to_run`;
6. over-capacity Walk remains possible and increasingly slow;
7. normal successful Walk increases fatigue;
8. Walk fatigue changes with terrain difficulty;
9. Walk fatigue is identical at two different carry loads when terrain is identical;
10. Run fatigue increases with terrain difficulty;
11. Run fatigue increases with encumbrance below the Run cutoff;
12. fatigue 80+ still blocks Run;
13. crouched Run still blocks;
14. known hard blocker at first Run stride produces impact after stride time, 5 HP loss, no movement into blocker, and Run fatigue;
15. blocker at second Run stride preserves the valid first stride, then causes 5 HP impact and stops;
16. UNKNOWN does not masquerade as a physical impact;
17. ordinary Walk damage interruption still works;
18. Run-impact Health damage does not retroactively roll back the Run's physical outcome;
19. Stats/HUD reflect real HP/fatigue changes without new fake state;
20. Leave Game Web code directly assigns Google and contains no `history.back()` path;
21. Systems 02/03/13A/13B/13E/14/15/16/17 regressions remain green;
22. exact-final-SHA Godot parse/startup, dedicated CI, Web export and Pages deploy pass.

## 15. North-star fit

17A strengthens the **Ultima-style turn-based mini Zomboid** identity by making movement choices physically consequential without adding a stamina minigame:

- difficult ground takes longer and tires you more;
- heavy load takes longer and makes sprinting harder;
- full encumbrance removes sprint as an option;
- walking remains possible under load but terrain, not weight, decides its direct fatigue charge;
- sprinting blindly into a solid object actually hurts;
- all consequences stay in their owning domains through narrow coordinators.

## 16. Draft decisions requiring explicit approval

1. Movement duration uses true multiplicative stance/fatigue/encumbrance scales over terrain base cost.
2. Existing encumbrance factor remains +75% at exactly capacity; over-capacity Walk continues scaling.
3. Run is blocked at 100%+ capacity with `too_encumbered_to_run`.
4. Terrain effort derives from `walk_terrain_ticks / 10` for v1.
5. Successful Walk gains `ceil(terrain_effort_factor)` fatigue and ignores encumbrance for fatigue.
6. Run stride fatigue is `round(terrain_effort_factor * encumbrance_factor)`, minimum 1.
7. A known hard blocker is a Run impact candidate rather than request-time zero-cost rejection.
8. Run impact stops the sprint at the last legal cell and charges the attempted stride's fatigue.
9. Run impact causes 5 HP damage through a stateless Movement -> Health coordinator.
10. UNKNOWN/untraversable terrain still fails closed and does not become impact damage.
11. Web Leave Game goes directly to Google with no history/back attempt.
