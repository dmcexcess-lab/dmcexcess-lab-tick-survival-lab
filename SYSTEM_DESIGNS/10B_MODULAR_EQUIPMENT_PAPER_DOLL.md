# Tick Survival Lab — 10B Modular Equipment / Paper Doll / Clothing Projection

Status: **IMPLEMENTED + EXACT-HEAD AUTOMATED VERIFIED — human playtest pending**

Implemented executable head: **`31bc923a92eabcd96f69603933d9669399858eeb`**  
Date: **2026-09-05**

This document is the current extension of the historical Systems 09/10 hand-only contracts. Where those older documents describe equipment as exactly two hands or presentation as hand-only, this contract supersedes that scope while preserving their anatomical right/left semantics and stable physical-item identity rules.

## Core authority rule

> **Equipment state is authoritative. The player sprite and paper doll are read-only projections of that state; neither becomes a second equipment truth.**

`ActorHandEquipmentState` remains the canonical assignment store despite its historical class name. Its current slot vocabulary is:

1. right hand / `PRIMARY_RIGHT`;
2. left hand / `SECONDARY_LEFT`;
3. back;
4. head;
5. torso;
6. legs;
7. feet;
8. hands.

The state keeps one reverse item-assignment index so one stable physical item cannot occupy multiple equipment slots. Normal writes continue through `ActorHandEquipmentMutationService` and player-facing timed equip/stow/drop continues through the existing Item Transfer action owner.

No paper-doll dictionary, renderer cache or UI row owns assignment state.

## Equipment profiles and restrictions

`ActorEquipmentProfileCatalog` remains the semantic slot-compatibility owner for the current bounded item set.

The skateboard rule is unchanged and protected:

- allowed only in right hand, left hand or back;
- never a torso/legs/feet/hands/head item;
- ordinary personal/backpack stow remains prohibited by the existing policy-aware transfer path.

This pass does not weaken inventory containment, stable-item identity or transfer timing rules.

## Shared read-only projection

`game/scripts/simulation/actors/equipment/ActorEquipmentProjection.gd` is the common presentation seam used by UI and world rendering.

It reads:

- WHAT for stable item semantic identity;
- authoritative equipment assignments;
- equipment presentation profiles.

It exposes all eight canonical slots in stable slot order and a deterministic occupied visual-layer sequence:

`BACK -> LEGS -> TORSO -> FEET -> HEAD -> HANDS -> RIGHT HAND -> LEFT HAND`

The projection performs no mutation and stores no alternate ownership map.

## Modular player visuals

`ActorEquipmentPresentationRenderer.gd` now consumes the shared projection rather than independently interpreting assignment truth.

Current practical overlays include:

- headwear;
- torso clothing;
- leg clothing;
- footwear;
- gloves;
- held items;
- back equipment, including skateboard.

Presentation redraws when equipment/world truth signals change. No per-frame equipment simulation or second avatar system was added. The renderer stays inside the existing tactical actor rendering stack.

The visual language is deliberately modular and bounded; future clothing/item art can expand profile-to-visual mapping without changing equipment authority.

## Paper doll / ordinary inventory UI

`ActorEquipmentPaperDollQuery.gd` combines the slot projection with derived equipment protection reads.

`ActorInventoryInspectorQuery.gd` now includes that equipment read model while preserving existing inventory/carry/freshness reads.

`EquipmentPlayerShell.gd` extends the existing production inventory/player shell. The normal INVENTORY modal now includes:

- `EQUIPMENT / PAPER DOLL`;
- all eight authoritative slots;
- the exact equipped item or `Empty` for each slot;
- real equip/stow/drop actions routed through the existing timed transfer owner;
- `PROTECTION / CLOTHING` derived totals.

The production scene root remains `VehicleGameMain.gd`; only the PlayerShell script is extended. No standalone equipment/debug window is introduced.

## Protection, weather and insulation

Current equipped-item totals remain read-only derived values:

- bite/cut armor;
- blunt/ballistic armor;
- water resistance.

This pass restores **insulation** only as a separate clothing thermal/comfort property.

`ActorEquipmentProtectionQuery` derives all four values directly from currently equipped authoritative items on every query. It does not persist/copy a second protection state.

`query_thermal(actor_id)` exposes the narrow downstream seam:

- `known`;
- `insulation`.

Insulation is **not armor**, does not change bite/cut or blunt/ballistic semantics, and this pass does not invent a body-temperature simulation. Weather/body-comfort systems may consume this query later.

Current bounded profile values are intentionally simple gameplay data and may be tuned later without architectural change.

## Verification

Owning workflow: `.github/workflows/actor-hand-equipment-presentation.yml`

The workflow now imports/parses Godot 4.7.1 and runs the existing Art Catalog, hand-equipment, living-actor and hand-presentation regressions plus `ActorEquipmentPaperDollSmoke.gd`.

Exact executable head **`31bc923a92eabcd96f69603933d9669399858eeb`** passed the owning **Actor Hand Equipment Presentation contract** run **`340663978`**.

`ActorEquipmentPaperDollSmoke.gd` protects at minimum:

- all eight slots read authoritative equipment truth;
- paper doll changes immediately after authoritative unequip;
- bite/cut, blunt/ballistic and water totals derive from equipped clothing;
- insulation derives separately from equipped clothing;
- thermal query seam exposes insulation;
- deterministic modular visual ordering;
- visual projection removes unequipped layers;
- read-only projections do not increment equipment revision;
- one stable item cannot be duplicated into a second slot;
- skateboard remains hand/back-only and cannot enter a clothing slot;
- production equipment shell instantiates.

Verification repair head **`d5197d971fe65f1be4d3bf654cba36e1b09c46cb`** corrected a stale Item Transfer regression that still treated `insulation` as forbidden. The repaired contract now protects the current rule instead: insulation is permitted only as derived thermal/comfort clothing data and remains separate from bite/cut armor, blunt/ballistic armor and water resistance. That exact head reached aggregate commit status **success**, with no failed or pending status observed, and `verify/pages-deploy` succeeded.

The exact executable head's protected vehicle, HUD/camera, streaming, lighting, weather/condition, interaction and visual-geometry regressions remained green through the verification repair.

## Protected integration invariants

This pass does not intentionally change:

- production root `VehicleGameMain.gd`;
- walking versus mounted control-surface replacement;
- CENTER/FOLLOW or MAP availability/geometry;
- retired visible Zoom +/- controls;
- retired Health/Fatigue progress bars;
- `Looking at:` placement;
- world generation/road/water/streaming rules;
- vehicle timing/fuel/braking behavior.

In particular, skateboard remains the explicit vehicle braking exception: it is brakeless and may reverse/dismount while moving. Bicycle, motorcycle, car and truck still require stopping before reverse/exit.

## Next integration seam

With equipment/paper-doll/clothing projection closed, the next approved work is the player/world/object interaction practicality audit: verify existing systems are actually reachable through ordinary UI and finish missing real paths for eating/drinking, sleeping, deconstruction, repairs, window boarding/opening/smashing/climbing and other already-built interaction mechanics before combat or infected/NPC work.