# System 34 — Survivor Condition, Health, Stamina & Moodlets

Status: **APPROVED — Candidate 001 implementation**

User approval: **“approved 34”**

## Core rule

> **Condition is physical/mental truth. Moodlets describe that truth. Moodlets never create the truth.**

System 34 completes the next survivor-condition layer over existing Health, WHEN, item/freshness, Carry, Perception, Sound, Weather and Utility truth without moving those domains into one monolith.

## Authoritative condition model

System 34 owns a real short-term **Stamina** reserve plus six high-is-good condition channels:

- Satiety — hunger pressure when low;
- Hydration — thirst/dehydration pressure when low;
- Rest — long-term sleep state;
- Engagement — fun/boredom;
- Comfort — physical comfort/distress;
- Calm — calm/fear.

Existing System-13 Health remains the HP/injury owner. System 34 derives an effective maximum-health ceiling from condition and may apply explicit lethal physical-need damage through that owner.

The old live Fatigue pressure is superseded. **There is no separate Fatigue meter in Candidate 001.** Rest is long-term sleep condition; Stamina is short-term exertion reserve.

## Universal condition tiers

All six channels use the same 0–100 boundaries:

| Value | Tier | Presentation | Gameplay contribution |
|---:|---|---|---:|
| 80–100 | GREEN | positive moodlet | +1 |
| 45–79 | NORMAL | no moodlet | 0 |
| 30–44 | YELLOW | mild bad moodlet | -2 |
| 15–29 | ORANGE | serious bad moodlet | -5 |
| 0–14 | RED | critical moodlet | -10 |

Candidate labels:

| Channel | Green | Yellow | Orange | Red |
|---|---|---|---|---|
| Satiety | Well Fed | Hungry | Famished | Starving |
| Hydration | Hydrated | Thirsty | Parched | Dehydrated |
| Rest | Rested | Tired | Exhausted | Sleep-Deprived |
| Engagement | Entertained | Bored | Restless | Stir-Crazy |
| Comfort | Comfortable | Uncomfortable | Miserable | Wretched |
| Calm | Calm | Uneasy | Afraid | Terrified |

Normal creates no moodlet/UI chip.

## Unified derived modifier contract

Moodlets do not apply penalties. A read-only System-34 modifier query derives one condition snapshot from the six authoritative channels.

Channel potency:

- Satiety 1.0
- Hydration 1.1
- Rest 1.0
- Engagement 0.5
- Comfort 0.6
- Calm 0.8

Derived outputs and hard combined bounds:

| Output | Sensitivity | Minimum | Maximum |
|---|---:|---:|---:|
| effective max Health | 0.75 | 60% | 105% |
| max/recovery Stamina | 1.50 | 40% | 105% |
| movement speed | 0.80 | 65% | 105% |
| carry capacity | 1.00 | 60% | 105% |
| body-powered/melee damage | 1.00 | 65% | 105% |

Speed changes authoritative movement duration. It must never delay input dispatch or reintroduce queued-input behavior.

The melee/body-powered damage multiplier is a public future combat seam. It does **not** weaken firearm projectile/ammunition energy merely because the survivor is hungry or afraid.

## Health behavior

- Existing Health remains base HP/injury truth.
- System 34 derives an effective max-health ceiling.
- If worsening condition lowers the ceiling below current HP, current HP clamps downward.
- Improving condition restores the ceiling but does **not** restore the HP that was lost by the clamp.
- Hydration at zero causes the fastest direct health deterioration.
- Satiety at zero causes slower deterioration.
- Rest at zero causes the slowest deterioration.
- Engagement, Comfort and Calm do not directly drain HP.
- Candidate lethal rates are explicit sparse mutations resolved from authoritative WHEN elapsed time; no HP timer exists.

## Stamina behavior

- Stamina is short-term physical exertion reserve.
- Physical movement spends Stamina; running costs much more than walking and scales with terrain/carry pressure.
- Recovery occurs only because WHEN advances.
- Remaining on a real-time decision pause restores zero Stamina.
- Walking remains possible at zero Stamina; running requires a minimum starting reserve.
- Condition changes both effective Stamina maximum and recovery rate.

## Condition time model

Persistent records use sparse anchors and fixed-point values. Current condition is analytically derived from the anchor and authoritative world tick.

Candidate passive pressure:

- Satiety falls 50 points per in-game day.
- Hydration falls 75 points per in-game day.
- Rest falls 40 points per in-game day while awake.
- Engagement falls 15 points per in-game day without meaningful activity.
- Comfort and Calm naturally drift toward neutral rather than automatically becoming positive.

No condition channel owns a Node, timer, frame update or recurring whole-world scan.

## Real sustainment actions

### Eating/drinking

- EAT/DRINK selects an actual carried persistent item with an explicit System-34 sustainment profile.
- The committed action advances WHEN.
- The exact item remains real until action completion, then is detached from hand/containment and removed from WHAT.
- System 30 remains freshness owner. Spoiled food is not silently converted into a safe reward.
- Raw/cooking-required foods are not pretended to be ready meals merely because their item semantics exist.

### Potable tap water

A building having municipal service is not itself a magical DRINK affordance.

Tap drinking requires:

1. a real generated water fixture such as a kitchen sink/bathroom vanity in contact reach;
2. a real System-33 water service binding for that fixture cell;
3. that System-33 service currently being available;
4. revalidation when the committed drink action completes.

### Rest/sleep

- REST is a real one-hour WHEN action.
- SLEEP is a real eight-hour WHEN action in Candidate 001.
- A real nearby bed is better for Comfort than ground/floor sleep.
- Ground sleep remains possible and carries a Comfort penalty.
- The skipped time is real: hunger/hydration/rest analytic state continues to obey WHEN while sleeping.

## Engagement, Comfort and Calm inputs

Engagement can improve from meaningful completed crafting/scavenging activity. Trivial repeated UI actions are not reward generators.

Comfort consumes only facts that currently exist:

- real bed vs ground rest surface;
- real Weather precipitation plus cached real sky exposure;
- actual severe carried load.

No temperature/hypothermia variable is invented before a temperature owner exists.

Calm/fear consumes only survivor knowledge/events:

- actual HP damage;
- newly VISIBLE infected actors from System 23 current perception;
- sufficiently alarming System-26 HeardSoundObservation listener knowledge.

Hidden/remembered actors do not create psychic fear. The sound adapter receives no exact hidden source identity/cell.

## UI

- Health and Stamina are permanently visible status bars in the live HUD.
- Six condition values are readable in the HUD/Stats screen.
- GREEN/YELLOW/ORANGE/RED moodlets are colored chips; NORMAL is absent.
- Stats shows the final derived Health/Stamina/Speed/Carry/Melee modifiers.
- Presentation owns no condition truth and advances no time.

## Ownership boundaries

System 34 does not replace:

- System 13 Health/injury storage;
- System 30 item freshness;
- System 33 utility/water availability;
- System 13D/13E item weight/carry base truth;
- System 23 visibility/knowledge;
- System 26 hearing observations;
- System 28 Weather;
- WHEN action scheduling/time.

The live composition removes the legacy Fatigue mobility/exertion adapters after historical System-13 boot, then registers System 34 as the live condition/stamina owner. Legacy isolated fixtures remain available for regression compatibility until deliberate cleanup.

## Performance boundary

- zero per-frame condition simulation;
- zero per-condition timers;
- zero pause-time Stamina recovery;
- no daily catch-up loop;
- no recurring world scan;
- condition settles only at bounded actor/action/mutation boundaries;
- environment pressure uses local/cached queries only;
- modifier snapshots are read-only derived truth.

## Candidate 001 verification contract

Automated coverage must prove at minimum:

1. exact GREEN/NORMAL/YELLOW/ORANGE/RED boundaries;
2. normal produces no moodlet and each non-normal tier uses the approved labels;
3. combined modifier caps/bonuses are respected;
4. condition time changes only with WHEN;
5. decision-pause wall time recovers no Stamina;
6. physical exertion spends Stamina and WHEN recovery works;
7. worsening Health ceiling can remove HP and recovery does not magically heal it;
8. zero physical needs can cause real HP damage while mental channels cannot directly kill;
9. deterministic snapshot/restore;
10. real carried food/drink semantics and no raw-food fake;
11. effective carry capacity consumes the System-34 modifier without changing base carry state;
12. live legacy Fatigue adapters are superseded without breaking historical isolated regressions;
13. canonical startup succeeds with System34GameMain;
14. protected input responsiveness, utility/water truth and existing Health/Carry behavior remain green.

Human browser acceptance remains separate from automated verification.
