# Tick Survival Lab — 10 Actor Hand Equipment Presentation

Status: **APPROVED — user explicitly approved the held-item presentation direction on 2026-08-16; implementation authorized**

Approval basis: 09 Actor Hand Equipment State locked the requested visual behavior as its immediate downstream contract. After 09 was implemented and verified, the user explicitly replied **“Approved”** to proceeding with Actor Hand Equipment Presentation. This document formalizes that already-approved behavior before production code is added.

## 1. Goal

Present the real stable physical items assigned by 09 to survivor primary/right and secondary/left hands as readable floating held-object art beside the actor while preserving:

- authoritative actor position/facing from WHAT;
- authoritative hand assignment from 09;
- semantic item identity from WHAT `item.*` entities;
- recovered same-owner First Fire held-item artwork;
- deterministic N/E/S/W rotation;
- anatomical right/left meaning independent of facing;
- east/west body occlusion through explicit back/front presentation passes;
- strict separation from Inventory, combat, lighting, item stats, UI, input, camera and simulation truth.

10 does not decide what an actor is allowed to equip. It only presents what 09 says is in each hand.

## 2. Owners

Production after approval:

- `game/assets/held_item_atlas.svg`
- `game/scripts/render/ActorHandDrawCommand.gd`
- `game/scripts/render/ActorHandEquipmentLayerRenderer.gd`

Narrow additive 04 Art Catalog extension:

- `SOURCE_HELD_ITEMS` registration;
- semantic `item.*` -> recovered held-art mapping;
- held-art draw scale/native-facing metadata queries;
- separately pinned held-item recovery asset provenance.

Testing:

- `game/scripts/ci/ActorHandEquipmentPresentationSmoke.gd`
- `.github/workflows/actor-hand-equipment-presentation.yml`
- expanded `ArtCatalogSmoke.gd` / Art Catalog CI regression.

08 `ActorLayerRenderer.gd` remains unchanged.

## 3. Required inputs / read dependencies

`ActorHandEquipmentLayerRenderer` is a standalone `Node2D` configured with read-only dependencies:

- `WorldState` — actor placement/facing and item semantic identity;
- `ArtCatalog` — recovered held-item art descriptors/metadata;
- `ActorHandEquipmentState` — primary/right + secondary/left stable item assignments.

It may also receive one presentation-pass setting:

- `BACK`
- `FRONT`

No dependency reaches into 08 renderer internals. 10 independently reads canonical WHAT/09 truth so the living-actor renderer remains replaceable.

## 4. Why two renderer passes

The requested east/west occlusion cannot be represented honestly by one held-item layer always drawn above actors.

Canonical future composition is:

1. ground / structures / props as appropriate;
2. **held-item BACK pass**;
3. **living actor body layer (08)**;
4. **held-item FRONT pass**;
5. later overlays as their own systems require.

10 therefore supports two instances of the same focused renderer owner configured for different passes. Tactical renderer/orchestration later decides node/layer ordering; 10 does not become the composition root.

This allows the actor body itself to obscure the far-side held object instead of deleting, dimming, or faking its state.

## 5. Supported actors

10 presents hand equipment only for canonical living survivors:

- `actor.survivor`

This matches 09 enrollment capability.

`actor.infected` and unknown future actor families are ignored by this renderer rather than being assigned fake hand state.

Controlled versus NPC survivor is irrelevant to 10: both consume the same 09 physical hand truth.

## 6. Hand semantics

09 remains authoritative:

- `PRIMARY_RIGHT` = anatomical right hand;
- `SECONDARY_LEFT` = anatomical left hand.

These meanings never swap when the actor turns.

For canonical screen coordinates where +Y is down, let facing vector be `f` and anatomical right-side vector be:

`right = (-f.y, f.x)`

Then anatomical left is:

`left = -right`

Presentation offsets are actor-relative and derive from those vectors rather than hardcoded screen-left/screen-right assumptions.

## 7. Recovered art archaeology

Same-owner First Fire recovery sources inspected before implementation:

- `dmcexcess-lab/first-fire/game/scripts/FFTacticalVisuals.gd` blob `c10388a851a797fe19932b84b2e2ab7377828e8f`;
- `dmcexcess-lab/first-fire/game/scripts/FFTacticalTiles.gd` blob `732da9f6fff7b8dac60253e9d4ed4c9460f9fceb`;
- `dmcexcess-lab/first-fire/game/assets/tactical_atlas.svg` blob `2caff9a1c2ec84fc7d56e6b2c64bce953c575029`.

Historical weapon silhouettes:

- source 192 — knife;
- 193 — club / baseball bat;
- 194 — hammer;
- 195 — improvised spear;
- 196 — crowbar;
- 197 — hatchet;
- 198 — pistol;
- 199 — shotgun.

Historical utility item icons used by First Fire survivor hand drawing:

- source 64 — flashlight;
- 65 — headlamp;
- 66 — lantern;
- 67 — glow stick;
- 68 — road flare.

First Fire placed the weapon at the survivor's right-side vector and the secondary item at the left-side vector. It did **not** rotate the art by facing and drew both over the body. 10 recovers the real art/offset concept while intentionally improving rotation and east/west occlusion per the user's newer explicit request.

## 8. New recovered held-item atlas boundary

10 adds a separate narrow:

`game/assets/held_item_atlas.svg`

It contains exact vector recovery/repacking of the 13 relevant source cells only:

- indices 0–7: knife, club, hammer, spear, crowbar, hatchet, pistol, shotgun;
- indices 8–12: flashlight, headlamp, lantern, glow stick, road flare.

The existing ten protected Tick assets and separately recovered 08 actor atlas remain byte-identical.

The new asset receives its own pinned Git blob/provenance entry. It is not mislabeled as part of the golden Tick baseline.

## 9. Canonical semantic held-art mapping

Initial recognized semantic item kinds:

- `item.utility_knife` -> knife;
- `item.kitchen_knife` -> knife;
- `item.wooden_club` -> club;
- `item.baseball_bat` -> club;
- `item.hammer` -> hammer;
- `item.improvised_spear` -> spear;
- `item.crowbar` -> crowbar;
- `item.hatchet` -> hatchet;
- `item.pistol` -> pistol;
- `item.shotgun` -> shotgun;
- `item.flashlight` -> flashlight;
- `item.headlamp` -> headlamp;
- `item.lantern` -> lantern;
- `item.glow_stick` -> glow stick;
- `item.road_flare` -> road flare.

These mappings are presentation vocabulary only. They do not define item damage, weight, ammo, tool capability, lighting behavior, durability, inventory size or equip legality.

Unknown `item.*` kinds return typed UNKNOWN art/diagnostic rather than becoming a knife, pistol, flashlight or generic box.

## 10. Art Catalog additive contract

04 gains narrow presentation-only methods:

- `resolve_held_item(semantic_id: StringName) -> ArtSelection`
- `held_item_draw_scale(semantic_id: StringName) -> float`
- `held_item_native_facing(semantic_id: StringName) -> int`

Current recovered profile:

- weapon silhouettes draw at `14 / 32` of one tactical cell;
- utility icons draw at `12 / 32` of one tactical cell;
- all recovered held art is treated as **EAST-native** for deterministic actor-facing rotation.

Item size follows the art/item family, not the hand slot. Moving a flashlight from left to right does not make it weapon-sized; moving a knife to secondary does not shrink it to utility size.

The Art Catalog remains descriptor/metadata selection only. It does not draw or read equipment state.

## 11. Facing rotation

All held art rotates around its own presentation center according to actor facing relative to EAST-native source orientation:

- EAST: `0°`;
- SOUTH: `+90°`;
- WEST: `180°`;
- NORTH: `-90°`.

Rotation is presentation-only. It never modifies WHAT item placement, actor facing, item identity, hand slot or collision.

## 12. Hand position / recovered offsets

Historical First Fire offsets are preserved proportionally in cell units rather than hardcoded absolute pixels:

Primary/right center:

`actor_center + right_side * (11 / 32 cell) - forward * (1.5 / 32 cell)`

Secondary/left center:

`actor_center + left_side * (10.5 / 32 cell) - forward * (1.0 / 32 cell)`

These values are presentation geometry only. They do not create sub-cell simulation positions.

The subtle dark circular backdrop used historically for readability is preserved as presentation treatment, scaled to the actual held-art size. It participates in the same BACK/FRONT pass as its item.

## 13. Pass / occlusion rules

### NORTH

Both hands are laterally readable relative to the actor body.

- primary/right -> FRONT;
- secondary/left -> FRONT.

### SOUTH

- primary/right -> FRONT;
- secondary/left -> FRONT.

### EAST

Facing east makes screen-south the actor's anatomical right/near side and screen-north the anatomical left/far side.

- primary/right -> FRONT;
- secondary/left -> BACK.

### WEST

Facing west makes screen-south the actor's anatomical left/near side and screen-north the anatomical right/far side.

- primary/right -> BACK;
- secondary/left -> FRONT.

The BACK object remains a real command/state. Normal actor-body draw coverage creates the requested partial/full occlusion.

## 14. Draw command contract

`ActorHandDrawCommand` retains at minimum:

- stable `actor_id`;
- stable `item_id`;
- item semantic type;
- hand slot;
- requested presentation pass;
- actor anchor;
- actor facing;
- local item center;
- draw size;
- rotation radians/quarter-turn;
- copied `ArtSelection` or diagnostic state.

Commands are immutable-style/copy-safe where practical.

Deterministic order within a pass:

1. actor anchor Y;
2. actor anchor X;
3. stable actor ID;
4. hand slot numeric order.

## 15. Visible discovery

10 scans only the supplied visible global-cell window through canonical WHAT ACTOR occupancy.

Survivor stable IDs are deduplicated because arbitrary ACTOR footprints can touch multiple visible cells.

For each visible survivor:

1. validate entity and ACTOR placement/facing;
2. check 09 enrollment;
3. read explicit primary/right and secondary/left IDs;
4. skip explicitly empty hand slots;
5. validate referenced WHAT item entity still exists and remains `item.*`;
6. resolve held-item art/metadata;
7. assign BACK/FRONT pass from facing + anatomical slot;
8. emit at most one command per non-empty hand.

A tactically unplaced held item is expected. 10 does not require or invent a LOOSE_ITEM placement for equipped items.

## 16. Missing / stale truth diagnostics

Fail visibly/boundedly for relevant visible survivor state such as:

- survivor missing 09 enrollment;
- hand points to missing WHAT item entity;
- referenced entity no longer belongs to `item.*`;
- unknown held-item semantic art;
- invalid actor facing/placement/channel/occupancy;
- malformed/non-drawable ArtSelection;
- texture load failure.

An enrolled survivor with an explicitly empty hand produces no held-item command and is not an error.

Unknown future item art is never silently substituted.

## 17. Redraw / invalidation

No `_process()` polling.

Redraw requests occur on:

- configure;
- visible window/cell-size change;
- pass setting change;
- texture-cache clear;
- WHAT world reset;
- relevant visible survivor ACTOR placement/move/removal;
- deletion of an item currently assigned to a visible survivor;
- 09 actor enrollment/removal;
- 09 hand assignment change;
- 09 state reset.

Terrain, structures, props, unrelated actors/items and distant equipment changes should not force redraw when relevance can be determined through public contracts.

## 18. Public renderer contract

Expected surface:

- `configure(world_state, art_catalog, hand_equipment_state) -> bool`
- `set_render_pass(pass: int) -> bool`
- `render_pass() -> int`
- `set_visible_window(origin, size_cells, cell_pixels) -> bool`
- `has_valid_view() -> bool`
- `plan_visible_commands() -> Array[ActorHandDrawCommand]`
- `clear_texture_cache()`
- bounded diagnostic access;
- `redraw_requested(reason)` signal.

The same class is instantiated once for BACK and once for FRONT in future canonical composition.

## 19. Non-goals / forbidden ownership

10 must not own/import:

- hand assignment mutation;
- Inventory / Containment / pickup / drop / equip legality;
- item stats/definitions beyond art mapping;
- two-handed reservation rules;
- combat, aiming, attack animation, muzzle flash, ammo/damage;
- flashlight/light-source simulation;
- Health / Needs / fatigue / encumbrance;
- AI;
- WHEN/action timing;
- Collision / Movement;
- actor locomotion state;
- corpse/death state;
- camera/zoom;
- touch/keyboard/Safari input;
- HUD/stats/inventory/menu UI;
- generation;
- frozen reboot runtime;
- Tactical Renderer composition itself.

## 20. Performance / Safari

- visible ACTOR occupancy only;
- stable-ID deduplication;
- maximum two item commands per visible enrolled survivor;
- lazy texture cache;
- event-driven redraw;
- no full-world scan or per-frame polling;
- no permanent Node per item/actor;
- no touch/hover logic inside renderer.

Safari has no special drawing semantics here; mobile performance remains first-class by preserving bounded visible work.

## 21. Acceptance tests

Dedicated Godot 4.7.1 contract should prove:

- source-boundary isolation;
- all ten protected Tick assets remain byte-identical;
- recovered actor atlas remains byte-identical;
- held-item atlas exact pinned blob identity and source provenance recorded;
- project import/parse;
- Art Catalog regression;
- 09 Actor Hand Equipment regression;
- 08 Living Actor regression;
- exact 15 semantic aliases/kinds resolve to the 13 recovered held-art cells;
- unknown held item fails visibly;
- item-specific draw scale follows item kind, not slot;
- native EAST-facing metadata;
- N/E/S/W rotation values;
- historical proportional right/left offsets;
- NORTH/SOUTH both hands FRONT;
- EAST secondary BACK + primary FRONT;
- WEST primary BACK + secondary FRONT;
- same stable assignments preserved while facing changes;
- explicit empty hands emit no item commands;
- missing enrollment is diagnostic, not silently empty;
- stale/missing item entity is diagnostic;
- multi-cell survivor occupancy deduplicates to at most two hand commands;
- deterministic overlap/order;
- hand state mutation redraws visible actor only where relevant;
- relevant actor movement/item deletion redraws;
- unrelated terrain/non-actor/non-assigned-item changes do not redraw;
- texture load/draw path works for rotated atlas regions;
- no imports from Inventory/Combat/Lighting/WHEN/AI/Input/UI/Reboot.

## 22. Future seams

- Tactical Renderer will compose BACK -> 08 Actor -> FRONT instances.
- Inventory/Containment and timed equip actions can change 09 without altering 10.
- two-handed items can later reserve both 09 slots while 10 decides whether to draw one or two visuals under an explicit rule revision;
- item Appearance/quality variants can extend Art Catalog metadata without changing equipment identity;
- aiming/attack animation can later add a separate pose/action presentation contract;
- carried lighting can read the same stable item assignment through its own mechanic domain;
- detailed Inventory UI can inspect the same stable item IDs;
- Authored Visual Test Area can exercise the real layer once canonical composition exists.

## 23. North-star fit

Visible equipment makes the readable top-down world communicate real survival state without requiring a menu. The system stays mini by keeping only two hand visuals and simple cardinal rotation while preserving real physical identity and consequence underneath.

The two-pass occlusion rule buys readable physical grounding without turning art into physics or forcing 08 to become an equipment renderer.

## 24. Approved decisions

Approved 2026-08-16 through the user's explicit request and follow-up **“Approved”**:

- show real objects in survivor primary/right and secondary/left hands;
- items float beside the actor;
- held art turns with actor facing;
- primary/right and secondary/left remain anatomical roles;
- east/west hide the far-side object through actor-body occlusion;
- EAST: secondary BACK, primary FRONT;
- WEST: primary BACK, secondary FRONT;
- NORTH/SOUTH show both clearly;
- recover real First Fire held-item art before creating replacement art;
- keep this presentation separate from Inventory/Combat/Lighting/UI;
- future Safari-first demo will compose this layer rather than reimplement held-item drawing in a demo script.
