# Tick Survival Lab — Current Handoff

Last updated: **2026-09-03**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**.

## Current verified head

- **Exact gameplay executable:** `156ee4b0a1727a5d5d26b479cf7a0dea9e9b462a` — `Align health fatigue needs and moodlets`
- **Exact-head result:** **51 completed workflows, 51 successes, zero failures, zero pending**.
- **Owning System 34 run:** `33807332330` — completed / success.
- **Pages build/deploy run:** `33807332596` — completed / success.
- **Streaming/materialization and 12-seed playable-boot run:** `33807332569` — completed / success.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- The later commit containing this handoff is documentation-only and does not change the executable above.

## Completed operation — Health, Fatigue, Needs and Moodlets alignment

The playable survivor now has one canonical short-horizon exertion value:

- **Fatigue:** `0` rested -> `100` physically exhausted.
- **Rest:** separate high-is-good long-horizon sleep/recovery condition.
- There is no parallel live Stamina pool or Stamina HUD meter.
- Schema-v1 System-34 saves migrate remaining Stamina reserve by inversion into Fatigue pressure and remove the duplicate legacy fields.

Physical action and recovery are consequential:

- walking adds a small amount of Fatigue;
- running adds materially more and scales with terrain and real carried load;
- severe Fatigue blocks starting another run but never removes ordinary walking;
- physical action time does not secretly recover Fatigue;
- explicit rest/sleep actions relieve Fatigue;
- continued exertion beyond maximum Fatigue causes real damage through canonical Health and can reduce HP to zero;
- System 34 does not own the later death/corpse transition.

Physical needs now use the existing Health owner rather than presentation flags:

- starvation, dehydration and sleep deprivation apply bounded real HP damage;
- condition-derived effective Health ceilings never heal lost HP when conditions recover;
- mental/comfort channels do not directly invent HP damage.

Moodlets are derived warnings rather than stored or duplicated truth:

- normal and positive meters produce no moodlet-chip clutter;
- Satiety, Hydration, Rest, Engagement, Comfort and Calm produce only meaningful warning tiers;
- Fatigue produces `Winded`, `Physically Exhausted` or `Spent` at its own pressure thresholds;
- Health directly produces `Injured`, `Badly Injured` or `No Vitality`;
- real Carry truth directly produces `Heavy Load` or `Overburdened`;
- HUD and Stats show canonical Health/Fatigue and condition effects.

The old System-13 Needs/Moodlet fixtures remain for isolated compatibility regressions. `System34GameMain` disconnects their old movement/exertion path, so they are not a second live condition owner.

## Verification completed

Local Godot 4.7.1 verification passed:

- import / parse;
- `System34SurvivorConditionSmoke.gd`, including legacy-save migration and zero-Health overexertion;
- Health, legacy Needs, Carry, Moodlets and Freshness regressions;
- canonical HUD and player shell;
- Movement exertion/encumbrance and input responsiveness;
- protected Actor Skills, Crafting, World Loot and Spatial Sound regressions;
- protected System-33 power/water regression;
- canonical playable startup with `CANONICAL_DEMO_BOOT_OK`.

GitHub exact-head verification then completed 51/51 successfully, including Pages, the full 12-seed procedural playable-boot matrix, and the aggregate exact-head status publisher.

## New skill direction — recorded, not implemented in this operation

The future player catalog is exactly four broad skills:

- **Awareness**;
- **Stealth**;
- **Mechanical** — repair, deconstruction/reclamation, vehicle hot-wiring and related practical machinery work;
- **Survival** — first aid, scavenging, fire-starting and primitive survival crafting.

Field actions and crafting share one composable model: **concrete tool + concrete resource/material + relevant skill check**. Recorded examples are hammer + nails, wrench + bolts, screwdriver + wires, and rag + alcohol. Sticks, rocks, rags and newspapers/magazines should support primitive Survival tools, weapons and armor.

Skill should affect real-world outcomes such as treatment quality, time, failure risk and reclaimed material yield as well as recipe/crafting outcomes. Missing physical tools/materials are the natural hard blocker; low skill should normally produce risk or inefficiency instead of an invisible substitute item.

The current executable six-skill level/XP scaffold remains unchanged until this four-skill migration is implemented deliberately. Current crafting, scavenging, world loot and sound code were not modified by the completed condition operation.

## Protected neighboring behavior

- Preserve the accepted full 80×96 physical-light renderer, stateless LOS and input-lock/responsiveness recovery.
- Do not solve generated utility topology defects in presentation code.
- Preserve real procedural fenced substations, roughly ten generated buildings per substation, shared roadside feeder trees, short service drops, logical/non-physical regional source-to-substation links, and the two-pole road-crossing side hold.
- Preserve the one real persistent island-wide municipal water plant with no external-power dependency and the real persistent rural private wells.
- Do not reintroduce wastewater/sewer/septic.
- Do not fake items, facilities, action resources, skill outcomes or moodlet/condition truth in UI.
- Do not add frame-driven condition processing, per-actor timers or recurring whole-world scans. Condition/Fatigue remain analytic from WHEN anchors and action boundaries.
- Do not weaken the owning System-34 regression, protected Health/Carry/input/utility tests, or the consolidated 12-seed planner/playable-boot matrices.

## Human acceptance status

Automated verification is complete. Human browser/phone/Safari acceptance is still pending for the current condition feel and the earlier System-33 utility/renderer behavior.

## NEXT OPERATION

Human-play the live build in a WebGL2-capable desktop browser and on phone/Safari:

1. verify walking/running raises Fatigue at a believable rate and ordinary walking remains possible when exhausted;
2. verify Rest remains visibly distinct from short-term Fatigue and rest/sleep recovery feels correct;
3. verify hunger, thirst, sleep, comfort, fear and boredom moodlets appear only when meaningful and do not duplicate meter truth;
4. verify injury/zero-Health and real carry burden produce the correct moodlets;
5. confirm movement responsiveness, lighting, LOS and startup remain on the accepted baseline;
6. inspect multiple fresh seeds for the protected power-line crossing/substation/water/well behavior.

If that playtest exposes a defect, fix the owning implementation without weakening the verified contracts above. Otherwise record human acceptance. The next bounded implementation after that—or sooner on explicit user direction—is to replace the six-skill scaffold with Awareness, Stealth, Mechanical and Survival, then connect scavenging, first aid, deconstruction/reclamation, repair/hot-wiring and primitive crafting through one real tool + material + skill-check contract.
