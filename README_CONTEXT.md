# Tick Survival Lab — Current Handoff

Last updated: **2026-09-03**

This is the authoritative continuation checkpoint. Read `README_SOPS.md`, fetch current `main` once, and continue from **NEXT OPERATION**.

## Current verified head

- **Exact gameplay executable:** `8a2a9b7c1f3cf5281d4f579820cbd5c2cb445206` — `Repair primitive Survival integration contracts`
- **Primary push verification:** **41/41 workflows completed successfully**.
- **Exact-head/status publisher verification:** **7/7 additional runs completed successfully**.
- **Total run records tied to the executable:** **48 successes, zero failures, zero queued, zero running, zero cancelled**.
- **Live build:** `https://dmcexcess-lab.github.io/dmcexcess-lab-tick-survival-lab/`
- The later commit containing this handoff is documentation-only and does not change the executable above.

## Completed operation — Four-skill contract and primitive Survival crafting

The player skill catalog is now exactly four broad skills:

- **Awareness**;
- **Stealth**;
- **Mechanical** — repair, deconstruction/reclamation, vehicle hot-wiring and related practical machinery work;
- **Survival** — first aid, scavenging, fire-starting and primitive survival crafting.

The old six-skill live catalog is gone. Stats and current protected shell regressions enumerate the four canonical skills dynamically.

Crafting now uses the intended composable contract already owned by System 32:

**concrete physical material/resource + concrete physical tool + relevant broad skill check**

- Missing required tools/materials are hard physical blockers.
- Skill never invents or substitutes a missing item.
- The skill action profile changes real action duration and success chance.
- Outputs are real persistent WHAT entities with physical weight and ordinary containment/carry behavior.
- The crafting UI displays the relevant skill, level, difficulty, success chance and skill-adjusted duration.

### Primitive Survival resources now in real loot truth

System 24 now owns three additional weighted virgin-loot semantics:

- `item.outdoors.sturdy_stick` — Sturdy Stick;
- `item.outdoors.smooth_stone` — Smooth Stone;
- `item.junk.old_magazine` — Old Magazine.

Existing real `Rag Bundle`, `Dirty Rag` and `Old Newspaper` semantics are reused rather than duplicated.

The new resources enter existing deterministic searchable-container profiles. They do **not** currently appear through an invented ground-foraging shortcut or invisible inventory grant.

### Primitive Survival recipes now implemented

Three bounded Survival recipes now transform real possessed materials through the existing action service:

1. **Sharpened Wooden Stake**
   - material: Sturdy Stick
   - tool: Kitchen Knife
   - skill: Survival

2. **Improvised Stone Hammer**
   - materials: Sturdy Stick + Smooth Stone + Dirty Rag
   - tool: Scissors
   - skill: Survival

3. **Paper Tinder Bundle**
   - materials: Old Newspaper + Old Magazine
   - tool: Scissors
   - skill: Survival

The exact consumed item identities are destroyed only on successful commit; required tools remain physical and unconsumed. Cancellation and commit-failure compensation remain protected.

System 31/current crafting icon presentation explicitly covers the three primitive source resources and the three new crafted outputs using existing authored low-resolution glyphs. No family fallback is used to pretend unknown item semantics are covered.

## Deliberately not implemented yet

Do not treat the new item names as evidence of systems that do not yet exist:

- there is **no outdoor ground-forage/scavenge action yet** for sticks/stones;
- Sharpened Wooden Stake has **no invented weapon/combat damage behavior yet**;
- Improvised Stone Hammer is **not yet a generalized substitute for the normal Hammer tool requirement**;
- Paper Tinder Bundle has **no invented ignition/fire-use behavior yet**;
- primitive armor is not implemented by this slice.

Connect those outputs to real consumers only when the owning combat/tool/fire/equipment systems exist.

## Verification completed

Exact executable `8a2a9b7c1f3cf5281d4f579820cbd5c2cb445206` completed the complete current GitHub verification set successfully:

- System 32 Crafting, including physical-input/tool blocking, skill-adjusted timing/success contract, deterministic item selection, cancellation/compensation and the full primitive Survival chain;
- System 31 semantic icon coverage, including the new resources and crafted outputs;
- canonical Player Shell using the four canonical skills;
- Phase 1E content integration using the current Loot v4 / Loot Profile v3 vocabulary;
- Actor Skills and protected Health/Needs/Carry/Moodlet/Freshness contracts;
- protected movement, run/exertion/encumbrance, input responsiveness and damage-interruptible walking contracts;
- World Interaction/reach, World Loot and Spatial Sound contracts;
- protected System-33 power/water contracts;
- physical lighting, LOS, large visual geometry and renderer contracts;
- procedural generation, streaming/materialization and playable-boot matrices;
- Pages build/deployment and current live Web build;
- aggregate exact-head status publishing.

Final automated state: **41/41 primary push workflows green plus 7/7 exact-head/status runs green; no failed or pending run remains**.

## Existing survivor-condition contract remains protected

- **Fatigue:** `0` rested -> `100` physically exhausted.
- **Rest:** separate high-is-good long-horizon sleep/recovery condition.
- There is no parallel live Stamina pool or Stamina HUD meter.
- Walking adds small Fatigue; running adds materially more and scales with terrain and real carried load.
- Severe Fatigue blocks starting another run but never removes ordinary walking.
- Physical action time does not secretly recover Fatigue; explicit rest/sleep actions relieve it.
- Continued exertion beyond maximum Fatigue causes real Health damage and can reduce HP to zero.
- Starvation, dehydration and sleep deprivation apply bounded real HP damage through the existing Health owner.
- Moodlets remain derived warnings, not duplicated stored truth.

## Protected neighboring behavior

- Preserve the accepted full 80×96 physical-light renderer, stateless LOS and input-lock/responsiveness recovery.
- Do not solve generated utility topology defects in presentation code.
- Preserve real procedural fenced substations, roughly ten generated buildings per substation, shared roadside feeder trees, short service drops, logical/non-physical regional source-to-substation links, and the two-pole road-crossing side hold.
- Preserve the one real persistent island-wide municipal water plant with no external-power dependency and real persistent rural private wells.
- Do not reintroduce wastewater/sewer/septic.
- Do not fake items, facilities, action resources, skill outcomes or condition/moodlet truth in UI.
- Do not add frame-driven condition processing, per-actor timers or recurring whole-world scans.
- Do not weaken the owning System-34, Skills, Crafting, Loot, Health/Carry/input/utility tests or consolidated procedural/playable-boot matrices.

## Human acceptance status

Automated verification for the current executable is complete. Human browser/phone/Safari acceptance is still pending for:

- condition/Fatigue feel;
- movement responsiveness, lighting/LOS and startup baseline;
- generated System-33 power-line/substation/water/well behavior across fresh seeds;
- current crafting/skill presentation on WebGL2 desktop and phone/Safari.

## NEXT OPERATION

Implement a bounded **outdoor Survival scavenging/foraging action for primitive materials** so sticks and stones can be acquired from the physical outdoor world rather than only searchable containers.

Required shape:

1. derive explicit local candidate truth from real terrain/vegetation/world context rather than a recurring whole-world scan;
2. expose the action through the existing interaction/reach architecture where appropriate;
3. spend real WHEN time;
4. apply the canonical **Survival** action profile to duration/outcome;
5. create only real persistent resource entities on successful resolution;
6. never invisibly grant inventory, repopulate an exhausted source, or create a frame-driven/per-actor recurring scanner;
7. keep resource abundance bounded and deterministic enough for persistent-world reasoning.

After that seam exists, connect the primitive crafted outputs to real combat/tool/fire consumers only through those owners rather than adding special-case UI behavior. Later bounded skill integrations remain first aid, scavenging quality/yield, Mechanical deconstruction/reclamation, repair and hot-wiring through the same physical tool + material + broad-skill philosophy.
