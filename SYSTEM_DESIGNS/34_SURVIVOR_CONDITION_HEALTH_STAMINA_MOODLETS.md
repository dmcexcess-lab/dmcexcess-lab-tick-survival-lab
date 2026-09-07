# System 34 — Survivor Condition, Health, Fatigue & Moodlets

Status: **IMPLEMENTED + EXACT-ITEM INVENTORY USE VERIFIED — human playtest pending**

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

### Ordinary Inventory exact-item EAT / DRINK closure — 2026-09-07

No new consumption subsystem or parallel UI action state was required. The production `EquipmentPlayerShell -> CraftingPlayerShell -> CanonicalPlayerShell` Inventory path asks `SurvivorSustainmentActionService.consumption_offer(actor_id, exact_item_id)` for the currently selected persistent item and preserves that exact physical `item_id` through the Inventory action button and timed action start.

Canonical sustainment profiles already map:

- `item.food.apple` -> `action_kind = eat` -> ordinary Inventory label **EAT**;
- `item.drink.water_bottle` -> `action_kind = drink` -> ordinary Inventory label **DRINK**.

`begin_consume(actor_id, exact_item_id)` schedules the authoritative WHEN action. The selected item remains a real carried entity while that action is pending; only on committed completion is that exact physical item removed. A same-type sibling is unaffected, proving consumption does not alias by semantic type.

Fresh prompt-local verification on functional head `77f58cb5776d193cae2c6ae98190f7a65b47952d`, workflow run `34086785612`, proved both exact apple EAT and exact water DRINK through the ordinary production Inventory surface. The verifier was `game/scripts/ci/PromptInventoryItemUseSmoke.gd` owned by `.github/workflows/prompt-inventory-item-use.yml` and intentionally tested no unrelated module.

First aid is also live through the normal inventory. An exact selected bandage/gauze/tape/kit targets an exact real injury; the approved improvised path requires both a rag bundle and disinfectant/alcohol wipes. Survival changes duration and outcome quality. The action consumes real supplies only at completion and writes stabilization/treatment/severity only through canonical Health.

Engagement improves from meaningful completed activity. Comfort reads real rest surface, weather/sky exposure and severe carried load. Calm/fear reads real injury, current visible threats and sufficiently alarming heard observations—never hidden source truth.

## UI and compatibility

The live HUD permanently shows Health and Fatigue plus the six condition meters. Stats shows condition effects. Historical System-13 Needs/Moodlet fixtures remain for regression compatibility, but `System34GameMain` disconnects their live fatigue movement/exertion adapters and installs System 34 as the canonical owner. Schema-v1 System-34 saves migrate remaining Stamina reserve to the inverse Fatigue pressure.

## Verification

Historical system-level smokes remain useful implementation history, but they are no longer standing CI gates. Under the repository prompt-local verification policy, executable prompts create a fresh disposable verifier for only the module being changed and retire the previous prompt-owned verifier.

For the 2026-09-07 Inventory usability closure, `PromptInventoryItemUseSmoke.gd` proved the player can select exact persistent carried items through ordinary Inventory and receive EAT/DRINK from the existing sustainment owner. It also proved the selected item still exists before timed completion, the exact selected item disappears only after authoritative completion, and a same-type sibling remains. Workflow `Prompt Inventory Item Use` run `34086785612` passed on exact functional head `77f58cb5776d193cae2c6ae98190f7a65b47952d`.

Human browser acceptance remains separate from automated verification.
