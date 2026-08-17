# System 17A Implementation Changelog

Date: 2026-08-16

System: **Movement Exertion / Encumbrance / Run Impact Revision**

## Initial 17A player-visible changes

- Terrain, fatigue and encumbrance multiply movement tick cost rather than contributing as additive percentage pressure.
- Fresh/empty normal movement remains 10-tick Walk and 6+6-tick two-cell Run.
- At 100% or greater soft carry capacity, Run is disabled; Walk remains possible and increasingly slow.
- Running fatigue increases with both terrain difficulty and encumbrance below the Run cutoff.
- Running into a known solid blocker is a real committed impact rather than a harmless Run rejection.
- A hard Run impact stops at the last legal square, charges the attempted stride's exertion and causes 5 HP damage.
- Web `LEAVE GAME` navigates directly to Google instead of attempting browser Back first.

## Initial 17A architecture changes

- Canonical mobility providers expose multiplicative duration scales in basis points.
- `ActorMovementCapabilityService` composes stance, fatigue and carry scales multiplicatively with one deterministic final ceiling.
- `MovementTraversalPolicy` exposes read-only base Walk terrain timing so exertion can reuse terrain truth without duplicating a terrain catalog.
- Added `MovementExertionService` as the one stateless Movement -> Needs/Carry exertion coordinator.
- Added `MovementRunImpactDamageService` as a stateless Movement -> Health impact coordinator.
- Removed the superseded Run-only `MovementRunExertionService`.
- `MovementActionService` emits semantic exertion and Run-impact facts while retaining no Health/Needs/Carry implementation dependency.

## Initial 17A verification

Initial candidate:

`ac949279d0c0474e2c566b4d24f614947e442320`

It passed project parse and all protected System 02/03/13A/13B/13E/17 regressions. The new 17A smoke exposed a test-fixture lifetime mistake: stateless `RefCounted` coordinators were created only as local variables and freed when the fixture returned, so their signal observations disappeared.

No production change was needed for that failure.

Hardened test head:

`eeb5eb421337df3067f45b41fb4837fdb9b8875b`

Dedicated **Movement Exertion Encumbrance and Run Impact contract** run `32000627706` passed the complete initial 17A behavior. Promoted SHA `cb6e5b7058bf9a3a68aac4751b999f4ad826f410` later passed exact-head 17A, System 17, Web export and Pages deployment.

---

# 17A.1 Correction — overweight-only Walk fatigue + 2x hard carry ceiling

User correction on 2026-08-16:

> “Walking should only affect fatigue when over weight my bad. Being more overweight shouldn't matter. There should be an absolute max carry weight that you simply cant carry any more but it should be maybe x2 max carry weight.”

Detailed durable contract: `17A1_OVERWEIGHT_WALK_FATIGUE_HARD_CARRY_LIMIT.md`.

## Corrected player-visible behavior

- Walk adds **zero movement fatigue at or below soft carrying capacity**.
- Only strictly overweight Walk commits add terrain fatigue.
- Once overweight, the amount over capacity does **not** increase Walk fatigue; terrain alone sets the charge.
- Movement duration still scales with actual load ratio, so greater overweight remains slower even though Walk fatigue does not scale with the overage.
- Soft capacity remains the Run cutoff.
- Absolute normal possession ceiling is now **2x soft capacity**.
- Default soft capacity remains 18 kg, so default hard ceiling is **36 kg**.
- A pickup may reach the hard ceiling exactly but cannot exceed it.
- Picking up a container counts the container plus nested contents.
- At the hard ceiling, dropping/repacking/equipping remains possible because those operations do not add carried mass.

## Corrected architecture

- `ActorCarryState` derives `hard_limit_grams = capacity_grams * 2`; it does not persist a second hard-limit field.
- `ActorCarryQuery` now exposes hard-limit truth and reusable `query_item_tree(item_id)` recursive incoming weight.
- Added neutral `ItemAcquisitionCapacityPolicy` so System 12 stays independent of Carry implementation.
- Added `ActorCarryAcquisitionPolicy` as the 13E concrete adapter.
- `ItemTransferActionResult` adds `CARRY_LIMIT_EXCEEDED`.
- World -> personal-container and world -> hand acquisitions check capacity at request, commit, and immediately after source removal before destination mutation.
- Post-source failure compensates by restoring the original loose item, extending System 12's verified reentrant-safety rule.
- Low-level 09/11 persistence remains unchanged and can still represent exceptional over-hard state for diagnostics/imports.

## Correction verification

Candidate correction SHA:

`67a130b36fe35189651e942a386248352027a8d5`

Passed **Movement Exertion Encumbrance and Run Impact contract** run `32002310686`, including:

- project parse;
- Movement/Locomotion/Health/Needs/Carry/System17/ItemTransfer regressions;
- Walk fatigue = 0 at 50% and exactly 100% capacity;
- identical terrain fatigue at 110% and 190% load;
- unchanged load-sensitive movement duration;
- Run fatigue/impact regressions;
- canonical demo/HUD/player-shell regression and startup.

Passed **Item Transfer Actions contract** run `32002310787`, including:

- 18 kg -> 36 kg hard-limit derivation;
- exact hard-limit acquisition;
- >hard-limit zero-tick rejection;
- recursive incoming container weight;
- commit-time capacity revalidation;
- synchronous post-source carry mutation followed by correct source restoration;
- legal drop at the hard ceiling;
- all existing System 12 transfer/compensation regressions.

Exact documentation-promotion SHA is recorded in the completion response after final Pages validation.
