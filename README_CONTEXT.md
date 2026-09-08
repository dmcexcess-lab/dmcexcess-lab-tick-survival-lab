# Tick Survival Lab — Current Repository Handoff

Read this file first, then `README_SOPS.md`. Fetch current `main` once at prompt start. This is the authoritative continuation checkpoint; do not broadly rediscover closed work.

## Current checkpoint — ROADSIDE POWER / REAL STREETLIGHTS CLOSED — 2026-09-08

The user reported tangled electric-pole wires and approved the complete repair, adding the requirement that every other roadside pole be a streetlight with a real light effect.

Functional/executable owning head: **`c069cf6f28a5148571c76ba6b2a3479ecb26c839`**.

- Implementation publication: `b9c2e64aff86a548a7b32cfdbe13d0f4442f27d4`.
- Previous verifier workflow turnover correction: `c069cf6f28a5148571c76ba6b2a3479ecb26c839`.
- Locally tested source tree: `ed17ba5820077eb05458c944195691b26529ef53`; it exactly matches the functional GitHub head's tree.
- Changelog closure: `2d90ea17027351fe5c40821c9c05a3f87077bbe3`.
- This handoff is the **FINAL repository write**. Its containing commit is the final documentation head; after publication perform only read-only exact-head Actions/Pages/status verification.

## Completed repair

Production uses `NeighborhoodPowerInfrastructureMaterializer`, composed by `UtilityGameMain`. The older base materializer's segment placement is not the live neighborhood placement path.

Root causes repaired:

1. Separate substation traversals sampled and reused road poles independently, allowing a shared pole to override physical bank continuity and bypass other services' intervening taps.
2. Customer service drops bypassed the existing roadside crossing hold and could cross neighboring leads.
3. Placement searched square rings with an upper-left bias, displacing nearby supports/attachments sideways.
4. Ten-cell route sampling was not a maximum actual wire length; customer and substation leads had no cap.

Current contracts:

- Collect all substation/customer road keys first; place one canonical shared roadside chain. Every service uses the same intervening road keys and physical support identities.
- Compass-bank continuity is independent of a service's direction of traversal. Placement prefers road-normal alignment; necessary bank changes retain a two-pole hold.
- Customer supports prefer alignment with their tap, searching outward from the building face before shifting sideways.
- Opposite-bank leads get explicit crossing supports. Nearby span geometry is checked in a temporary generation-only spatial index; intersecting leads branch through existing supports instead of making unsupported X crossings.
- **All actual wire spans are at most 16 cells Euclidean distance**, including roadside trunks, substation leads and house leads. Longer connections receive real supports and distinct physical span assets with retained service provenance.
- Every second physical support in each ordered straight roadside/bank sequence is **`prop.streetlight`**. Shared supports count once; roadside crossing/intermediate supports participate. Off-road customer/facility supports are outside roadside alternation.
- Streetlights use the existing `UtilityPoweredLightingSourceAdapter` -> `PhysicalLightingService`/rendered glow path. They bind to the support's actual distribution service, deterministically choosing the first service when shared, rather than whichever substation is geometrically nearest.
- Source outages/restoration change real world illumination. Damage to the physical support disables its real emitter through existing System-33 network consequences.
- No new runtime route planner, per-frame infrastructure scan, timer, power-state owner, or decorative-only light system was introduced.

Seed-20001 production verification: **3,157 spans; 1,048 alternating roadside streetlights; longest span 16.00 cells; zero duplicate physical spans; zero unsupported wire crossings** across all span roles.

## Focused verification / publication

Current prompt-owned disposable verifier pair:

- `game/scripts/ci/PromptRoadsidePowerSmoke.gd`
- `.github/workflows/prompt-roadside-power.yml`
- Workflow: **Prompt Roadside Power**.

The verifier boots real production `main.tscn` at seed 20001 and checks endpoint existence, actual maximum length, duplicates, independent segment intersection geometry, each alternating roadside identity, real emitter profiles, physical illumination, source off/on, physical-support damage, and actual service bindings. A small crossed-lead/long-span case checks intermediate supports and service provenance. It does not run historical suites or seed matrices.

Verified owning head: `c069cf6f28a5148571c76ba6b2a3479ecb26c839`.

- Focused CI run **`34182205529`**, job **`101923389370`**: **success**.
- Local Godot 4.7.1 focused proof: **`PROMPT_ROADSIDE_POWER_SMOKE: PASS`**, clean of script/parser/load errors.
- Pages run **`34182205542`**, build job **`101923389488`**, deploy job **`101923503646`**: **success** on the functional head.
- Final documentation-head CI/Pages must be verified read-only after this handoff commit. Do not mutate this file afterward to insert those run IDs.

Publication used the connected GitHub write API because shell git push had no HTTPS credentials. The first publication omitted the old pathname of the renamed verifier workflow, causing that obsolete workflow to fail on its deliberately removed script. The turnover correction deleted the old workflow and restored exact equality with the locally verified source tree. Only the new focused verifier and Pages remain active.

## Turnover for the next code prompt

Delete this prompt's verifier pair at the start of the next code operation, then create one new focused pair for the actual module being changed:

- `game/scripts/ci/PromptRoadsidePowerSmoke.gd`
- `.github/workflows/prompt-roadside-power.yml`

Do not restore the previous World Resolution Indicator verifier or other historical gameplay gates. The real `ZOMBIES` / `LOADING` runtime indicator remains intact.

## Remaining work / blocker

The requested roadside-wire and alternating powered-streetlight repair is complete. No unresolved implementation or publication blocker remains at this checkpoint. The user's exact screenshot location was not reproduced; verification covers the real seed-20001 island's complete generated wire geometry and live lighting owners.

Resume the previously recorded generated-house environmental-pressure acceptance operation below. Do not expand NPC navigation preemptively. Production root remains `game/main.tscn -> EnvironmentalPressureGameMain.gd -> CombatGameMain.gd -> VehicleGameMain.gd`; the active infected cohort remains **8**.

Project rule: **Complex behavior, simple systems. Do not over-engineer it.**

# NEXT OPERATION — REAL GENERATED-HOUSE ENVIRONMENTAL PRESSURE

Do **not** add route-planning architecture first.

Use the existing production eight-member cohort and closed System-39 chain against **naturally generated seed-20001 island houses and their existing generated doors/windows**.

The next focused verifier must use real generated building/opening geometry rather than prompt-created door/window semantics.

Prove, in order:

1. identify a suitable real generated seed-20001 house/building and one of its existing exterior doors or windows through existing world/materialization/building truth;
2. use a real resident-backed infected from the production cohort;
3. establish a lawful destination from observer-scoped System-23 sight/last-seen truth or a System-26 heard observation — never hidden exact player coordinates;
4. let ordinary shared-WHEN movement approach the generated building;
5. confirm ordinary collision discovers the exact generated opening as the physical blocker;
6. submit the existing generic System-39 TRY OPEN / pressure path against that exact generated WHAT identity;
7. if the generated opening resists, prove resistance is learned only after the timed physical try;
8. prove repeated physical impacts change the same persistent opening condition and eventually change canonical passability when breach is physically reached;
9. prove impact/break sound propagates through System 26 and can cause another infected with no visual target knowledge to independently investigate;
10. prove the infected passes through the changed generated opening using ordinary movement or the existing window-climb action;
11. preserve ordinary ACTOR congestion and exact resident/infection provenance throughout.

## Navigation gate

If that real generated-building scenario succeeds with current bounded local behavior, **stop there**. Do not add pathfinding.

Only if that exact scenario exposes a concrete navigation failure should the failing geometry and behavior trace be inspected. Then add only the smallest **generic actor/world route-planning seam** needed to solve the demonstrated failure.

Do not preemptively add:

- global A*;
- horde routing;
- zombie navigation grids;
- flow fields;
- attack slots;
- shared destinations;
- magical door targeting;
- teleport correction;
- crowd coordinators.

## System 38 / 39 ownership — preserve

### Population / active cohort

- infected identities derive only from already-counted household resident slots;
- no extra zombie population exists;
- `InfectedState` remains an overlay on shared human actor identity;
- production active cohort remains **8**;
- 16 is functionally proven but intentionally not adopted;
- `WorldStreamingCoordinator` remains the sole active-envelope authority.

### Perception / behavior / sound

- System 23 owns observer-scoped vision and memory;
- System 26 owns uncertain heard observations;
- no hearing path may leak hidden exact source identity to behavior;
- intentions remain deliberately small: idle / pursue visible / pursue last seen / investigate sound / attack visible / press barrier;
- no group brain, shared target truth, per-frame AI, private zombie clock, or magic attraction radius.

### Time / movement / collision / openings

- WHEN owns simulation time, readiness, phases, interruption, and the player decision pause;
- movement/world/collision own physical locomotion and blockers;
- infected occupy ordinary blocking ACTOR cells;
- System 39 reacts only to exact physical opening blockers found through those owners;
- opening damage is generic persistent opening condition, not zombie building HP;
- canonical door/window owners control broken/open/passable state;
- System 26 carries impact/break sound consequences;
- System 37 owns actor combat;
- Health/generic corpse transition owns mortality.

## Protected neighboring contracts — preserve

- exact firearm/magazine/live-round identity remains containment truth; no integer ammo counters;
- reload remains WHEN RESUMABLE with truthful eject/insert/chamber state;
- player ordinary LOCK/UNLOCK remains retired; locked openings do not leak hidden lock truth;
- shattered-window replacement remains deferred until real glass exists;
- exact selected item -> lawful action -> authoritative WHEN -> exact-entity consequence;
- equipment slots remain RIGHT HAND, LEFT HAND, BACK, HEAD, TORSO, LEGS, FEET, HANDS;
- skateboard remains one identity across loose/equipped/ridden;
- skateboard 2 cells / 2 ticks; bicycle 3 / 2; motorcycle/car/truck 3 / 1;
- mounted vehicle controls replace walking controls in the same footprint;
- UI owns no gameplay truth;
- no Survival window, Forage panel, player-visible Dev window, Zoom +/- buttons, or Health/Fatigue bars;
- `Looking at:` remains below STATS / INVENTORY / MENU;
- CENTER/FOLLOW + MAP remain available on foot/mounted.

## World / performance contracts — preserve

- world size 3072x3072;
- streaming regions 128x128, active radius 1;
- gateways four-lane paved;
- routes touching town/crossroads paved two-lane unless gateway;
- rural-rural links may be gravel/dirt single-lane traversable;
- reference seed 20001 remains the focused generated-world target;
- water remains one municipal facility + service aliases with deterministic rural wells and no municipal pipe network;
- wastewater remains retired;
- do not reintroduce routine 12-seed testing.

## Final closure rule

This is the final repository mutation for the roadside power/streetlight prompt. After this handoff commit/push, perform only read-only final branch/commit/status and current focused CI/Pages verification. Do not edit code/docs, delete the active verifier, create more commits, or rerun by editing workflows. Any unexpectedly discovered failure after this point must be reported with its exact evidence for the next operation.
