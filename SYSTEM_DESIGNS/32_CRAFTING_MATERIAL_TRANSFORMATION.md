# Tick Survival Lab — System 32 Crafting / Material Transformation

Status: **IMPLEMENTED + CI VERIFIED — Candidate 001 / Roadmap Phase 2 complete**

Described: **2026-08-27**
Approved by user: **2026-08-27**
Verified executable: `8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`
Exact-head context: `verify/system32-crafting`

Roadmap owner: **Phase 2 — Crafting**

## Core rule

> **Crafting transforms specific real persistent item entities into specific real persistent item entities. The recipe describes the transformation; WHEN charges the time; existing item/world owners hold the result.**

System 32 does not create an abstract material wallet, UI stack economy, hidden output buffer, second inventory, second world state, or second clock.

## Implemented scope

Candidate 001 implements the approved 2A–2C slices as one cohesive System-32 owner.

### 2A — Recipe + plan foundation

Implemented modules:

- `game/scripts/simulation/crafting/CraftingItemCatalog.gd`
- `CraftingRecipe.gd`
- `CraftingRecipeCatalog.gd`
- `CraftingWorkstationCatalog.gd`
- `CraftingPlanQuery.gd`

Rules:

- requirements count **real stable item entities**, never abstract stack counts;
- exact semantic requirements are selected deterministically by stable item ID;
- valid source set is the actor's real personal possession graph from existing hands/containment/carry truth;
- nearby floor items and external world containers are never auto-pulled;
- consumed inputs cannot be enrolled System-11 container-items;
- required tools are real possessed items and are not consumed in Candidate 001;
- Candidate-001 recipes reject System-30 perishables rather than silently deleting freshness history;
- every input/tool/output has known positive System-13D weight;
- output mass may not exceed consumed-input mass;
- projected post-craft carried mass must stay within the current System-13E hard ceiling;
- query work is read-only and spends zero WHEN ticks;
- no whole-world entity scan is used.

### 2B — Timed physical transformation

Implemented owner:

- `game/scripts/simulation/crafting/CraftingActionService.gd`

Action type:

`crafting.craft_recipe`

Final phase:

`crafting.commit`

Rules:

- every accepted craft has explicit positive recipe duration;
- Candidate 001 uses WHEN `CANCELABLE` interruption semantics;
- request-time rejection spends zero ticks;
- cancellation before final commit consumes nothing and creates nothing;
- hard application pause advances zero crafting ticks;
- exact ingredient/tool/workstation/carry truth is revalidated at final commit;
- exact consumed items are removed from their existing hand/container owner and then removed from WHAT;
- outputs are new stable WHAT `item.*` entities;
- outputs are contained directly by the survivor's ordinary System-11 actor-root container;
- deterministic output IDs derive from authoritative action serial + output ordinal;
- output identity persists normally after creation;
- there is no Crafting-owned persistent output inventory.

### Bounded compensation

Crafting uses a small mutation journal containing only the exact recipe entities touched by the commit.

If a later mutation fails:

1. newly created outputs are cleared/removed;
2. removed input entities are recreated with the same stable ID + semantic;
3. their captured hand/container disposition is restored through the owning public service;
4. the craft reports a compensated failure.

If restoration itself cannot succeed, System 32 reports `critical_consistency_failure` instead of pretending success.

The implementation was additionally hardened so a failed WHAT deletion after a source relation was cleared must restore that source relation and still counts as a failed consumption step. A green test alone was not used to waive this consistency edge case.

No full-world snapshot transaction is used.

### 2C — Workstation + player integration

Implemented modules:

- `CraftingInteractionOfferProvider.gd`
- `game/scripts/player/CraftingPlayerInteractionController.gd`
- `game/scripts/ui/CraftingPanel.gd`
- `game/scripts/ui/CraftingPlayerShell.gd`
- `game/scripts/ui/icons/CraftingSemanticUiIconCatalog.gd`
- `game/scripts/app/CraftingCanonicalDemoMain.gd`

Explicit workstation capability:

`prop.workbench_heavy -> crafting.workbench.general`

The existing generated heavy workbench remains System-19/WHAT physical truth. System 32 only classifies that existing real object as a crafting workstation.

Workstation recipes require:

- a current placed OBJECT with the explicit capability;
- shared System-29 `CONTACT_FORWARD` reach;
- the same capability/placement/reach truth at final commit.

System 32 publishes read-only `crafting.use_workstation` / `CRAFT` offers through System 29. System 23 visibility filtering remains upstream of player-facing workstation selection.

The canonical player shell now includes a CRAFT entry. The Crafting panel is phone/Safari-first and shows recipe requirements, tools, workstation need, output, time, carry projection, and explicit unavailability reason.

Browsing and inspection spend zero simulation ticks. The panel uses WHEN hard application pause while open. Pressing CRAFT releases the panel's pause before requesting the real timed action, then the result may reopen the panel.

Gameplay keyboard/touch/world-pointer/camera controls use the same modal blocking contract as the existing shell/loot UI.

## Candidate-001 recipe content

Five bounded recipes prove the substrate:

1. `crafting.paper_bundle`
   - stale newspaper + worn cardboard
   - 8 ticks
   - output `item.crafting.paper_bundle`, 220 g
2. `crafting.metal_scrap_bundle`
   - rusted fasteners + broken screwdriver
   - requires hammer
   - 12 ticks
   - output `item.crafting.metal_scrap_bundle`, 400 g
3. `crafting.wire_salvage_bundle`
   - scrap wire + cracked phone charger
   - requires pliers
   - 10 ticks
   - output `item.crafting.wire_salvage_bundle`, 200 g
4. `crafting.patch_component_kit`
   - rag bundle + duct tape
   - requires scissors
   - 10 ticks
   - output `item.crafting.patch_component_kit`, 500 g
5. `crafting.improvised_toolkit`
   - metal scrap bundle + wire salvage bundle + patch component kit + screws
   - requires hammer + screwdriver + reachable general workbench
   - 24 ticks
   - output `item.crafting.improvised_toolkit`, 1000 g

The last recipe proves a genuine multi-stage chain in which earlier crafted entities become exact later inputs.

## Crafted item vocabulary / System 31

Crafted outputs are System-32 content, not System-24 virgin loot. They therefore do not automatically appear in untouched world containers.

All five output semantics register real System-13D weights and intentional low-resolution System-31-compatible icons through the additive `CraftingSemanticUiIconCatalog`.

The historical base System-31 catalog remains unchanged for its protected Phase-1 contract; the live Phase-2 composition uses the Crafting-aware extension.

## Ownership boundaries preserved

System 32 consumes but does not replace:

- WHAT — item/workstation identity and placement;
- WHEN — authoritative action timing/pause;
- System 09 — hand assignment;
- System 11 — containment;
- System 12 — ordinary pickup/drop/equip/container transfer;
- System 13D — physical weight;
- System 13E — carried mass/carry ceiling;
- System 24 — virgin loot/search;
- System 29 — neutral reach and player-facing interaction composition;
- System 30 — freshness;
- System 31 — semantic icon presentation.

## Explicit non-goals / future seams

Candidate 001 deliberately does not implement:

- perishable/cooking transformations or freshness inheritance;
- consuming item-containers;
- durability, condition or repair;
- construction/build placement;
- powered workstations;
- Power/Water/Refrigeration;
- nutrition/Health effects;
- Skills, XP, quality rolls or recipe discovery;
- Vehicles;
- firearms/ammunition or combat;
- AI crafting decisions.

Later owners may consume System-32 recipe/action seams without moving their mechanic truth into Crafting.

## Performance contract

System 32 adds no `_process()` / `_physics_process()` simulation loop, per-item Timer, per-recipe persistent Node, recurring world scan, or `WorldState.entity_ids()` gameplay query.

Cost scales with:

- one selected recipe;
- the actor's bounded personal possession graph;
- the tiny shared System-29 reach set for a workstation recipe;
- the small fixed number of recipe entities touched at commit.

This preserves the phone/Safari performance floor.

## Verification

Permanent focused workflow:

`.github/workflows/system32-crafting.yml`

Focused smoke:

`game/scripts/ci/CraftingSmoke.gd`

The focused contract proves, among other things:

- five valid Candidate-001 recipes and five real crafted-output semantics;
- all crafted outputs have positive System-13D weight;
- no Candidate-001 recipe silently consumes/creates a perishable;
- floor ingredients are not auto-pulled;
- exact stable-ID ingredient selection is deterministic;
- real WHEN durations are spent;
- only selected inputs are destroyed;
- required tools remain physical and unconsumed;
- cancellation before commit consumes/creates nothing;
- injected mid-commit failure restores exact input identity/containment;
- explicit workbench capability and shared System-29 reach are enforced;
- workbench publishes a real CRAFT interaction offer;
- the multi-stage crafted-component chain works;
- protected transfer/carry/loot/interaction/freshness/icon contracts remain green;
- canonical project startup succeeds.

Verified executable:

`8b4db898f0e02dd84298dbc5291f3e1a88c11ce4`

All **20 required exact-head contexts** are green on that executable, including:

- `verify/system32-crafting`;
- `verify/system24-loot`;
- `verify/system29-interaction-affordance`;
- `verify/system30-item-freshness`;
- `verify/system31-semantic-ui-icons`;
- `verify/performance-architecture`;
- `verify/pages-deploy`;
- all other protected System-00D/00F and Systems-19-through-28 contexts in the canonical stack.

Automated implementation/CI verification is complete. Human visual/interaction acceptance of the new CRAFT shell/panel and workbench workflow is still pending and is not claimed by CI.

## Roadmap consequence

Roadmap Phase 2 is **IMPLEMENTATION COMPLETE + CI VERIFIED**.

The next lifecycle target is **DESCRIBE Phase 3 — Power and Water**. Completion of System 32 does not authorize Phase-3 runtime code.