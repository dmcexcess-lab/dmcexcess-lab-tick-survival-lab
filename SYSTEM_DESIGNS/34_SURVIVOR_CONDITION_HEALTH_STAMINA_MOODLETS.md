# System 34 — Survivor Condition, Health, Fatigue & Moodlets

Status: **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED — human playtest pending**

The filename retains its approved-candidate history; the canonical model has no separate Stamina resource.

## Core rule

> **Condition is physical/mental truth. Moodlets describe that truth. Moodlets never create the truth.**

System 34 composes existing Health, WHEN, item/freshness, Carry, Perception, Sound, Weather and Utility truth through narrow services and queries.

## Authoritative condition model

Six high-is-good channels use a 0–100 scale:

- Satiety — hunger pressure when low;
- Hydration — thirst/dehydration pressure when low;
- Rest — long-horizon sleep state;
- Engagement — fun/boredom;
- Comfort — physical comfort/distress;
- Calm — calm/fear.

Fatigue is the one short-horizon endurance pressure: **0 rested -> 100 exhausted**. Fatigue is stamina/endurance; there is no parallel Stamina pool. Rest remains distinct because it represents longer-horizon sleep need.

Existing System-13 Health remains HP/injury owner. System 34 derives an effective maximum-health ceiling and applies explicit physical-need/overexertion harm through that owner.

## Condition tiers and moodlets

All six channels share these boundaries:

| Value | Tier | Consequence contribution | Moodlet |
|---:|---|---:|---|
| 80–100 | GREEN | +1 | none |
| 45–79 | NORMAL | 0 | none |
| 30–44 | YELLOW | -2 | mild pressure |
| 15–29 | ORANGE | -5 | serious pressure |
| 0–14 | RED | -10 | critical pressure |

Positive and normal state remain readable in meters/inspection but do not clutter the moodlet row. Live labels and Health/Carry/Fatigue composition are specified in `13F_ACTOR_MOODLETS.md`.

## Derived consequences

The read-only modifier query combines condition potency and Fatigue, with bounded outputs for effective max Health, Fatigue gain/recovery, movement speed, carry capacity and body-powered/melee damage. Presentation does not apply these rules.

- Speed changes authoritative action duration without delaying input dispatch.
- Firearm energy is not weakened by a body-powered damage multiplier.
- Walking remains possible at maximum Fatigue; severe Fatigue blocks starting another run.
- Exertion adds Fatigue and running costs much more than walking, scaled by terrain and actual carried load.
- Fatigue recovers only as authoritative WHEN advances; real-time decision pause recovers nothing.
- Continuing physical exertion beyond maximum Fatigue causes real HP damage and can kill through canonical Health.

## Time and survival actions

Persistent records use sparse fixed-point anchors. Current condition and Fatigue are analytic functions of those anchors and the world tick; there are no condition Nodes, timers, daily loops or recurring world scans.

Satiety, Hydration, Rest and Engagement decline with authoritative time. Comfort and Calm drift toward neutral. Zero Hydration, Satiety and Rest cause explicit bounded Health damage at different rates; mental channels do not directly drain HP.

Eating/drinking consumes a real carried persistent item after a committed action. Spoiled/raw foods are not silently converted into safe meals. Tap drinking requires a real reachable fixture with currently available System-33 service and revalidates on completion. Rest and sleep are real WHEN actions; bed/ground truth affects Comfort while all elapsed-time pressures continue to advance.

Engagement improves from meaningful completed activity. Comfort reads real rest surface, weather/sky exposure and severe carried load. Calm/fear reads real injury, current visible threats and sufficiently alarming heard observations—never hidden source truth.

## UI and compatibility

The live HUD permanently shows Health and Fatigue plus the six condition meters. Stats shows condition effects. Historical System-13 Needs/Moodlet fixtures remain for regression compatibility, but `System34GameMain` disconnects their live fatigue movement/exertion adapters and installs System 34 as the canonical owner. Schema-v1 System-34 saves migrate remaining Stamina reserve to the inverse Fatigue pressure.

## Verification

`System34SurvivorConditionSmoke.gd` proves tier boundaries, quiet normal/positive presentation, all pressure moodlets, real injury/load moodlets, WHEN-only Fatigue recovery, run blocking, overexertion harm down to zero Health, modifier caps, Health ceiling behavior, lethal physical needs, deterministic snapshot/restore and real sustainment semantics. The later death/corpse transition remains outside System 34.

Protected actor Health/Needs/Carry/Freshness, movement/input, System-33 utility, spatial-sound and canonical startup regressions must remain green. Human browser acceptance remains separate from automated verification.
