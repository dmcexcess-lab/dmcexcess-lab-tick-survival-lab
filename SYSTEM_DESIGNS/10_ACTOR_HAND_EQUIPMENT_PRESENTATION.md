# Tick Survival Lab — 10 Actor Hand Equipment Presentation

Status: **IMPLEMENTED — canonical two-pass held-item presentation with recovered First Fire art and dedicated Godot CI, 2026-08-16**

Approval basis: after 09 Actor Hand Equipment State was implemented, the user explicitly approved the requested held-item presentation: real primary/right and secondary/left objects floating beside survivors, rotating with facing, with the far hand hidden behind the body when facing east/west. The user also directed that the eventual canonical demo remain Safari-first and use real UI/state rather than placeholders.

## 1. Goal

Present the real stable physical items assigned by 09 to survivor primary/right and secondary/left hands without making rendering own equipment truth, inventory, combat, lighting, input, UI, or physics.

10 reads:

- WHAT for survivor placement/facing and item semantic identity;
- 09 Actor Hand Equipment State for stable primary/right and secondary/left item IDs;
- 04 Art Catalog for recovered held-item art descriptors and presentation metadata.

It mutates no simulation state.

## 2. Owners

Production:

- `game/assets/held_item_atlas.svg`
- `game/scripts/render/ActorHandDrawCommand.gd`
- `game/scripts/render/ActorHandEquipmentLayerRenderer.gd`

Narrow additive 04 Art Catalog contract:

- `SOURCE_HELD_ITEMS`
- `resolve_held_item(semantic_id)`
- `held_item_draw_scale(semantic_id)`
- `held_item_native_facing(semantic_id)`
- recovered held-item asset provenance in `ArtBaselineManifest.gd`

Testing:

- `game/scripts/ci/ActorHandEquipmentPresentationSmoke.gd`
- `.github/workflows/actor-hand-equipment-presentation.yml`
- expanded `ArtCatalogSmoke.gd` / `.github/workflows/art-catalog.yml`

08 `ActorLayerRenderer.gd` and all 09 production files remain unchanged.

## 3. Two-pass composition contract

10 is intentionally not folded into 08.

The same `ActorHandEquipmentLayerRenderer` class is instantiated with one of two presentation passes:

- `BACK`
- `FRONT`

Future canonical tactical composition orders them as:

1. held-item BACK pass;
2. 08 living actor body layer;
3. held-item FRONT pass.

That lets the actor body itself occlude the far-side held object instead of deleting or faking item state. Tactical renderer/orchestration owns the eventual node/layer composition; 10 only exposes the two focused passes.

## 4. Supported actor truth

10 presents hand equipment only for:

- `actor.survivor`

Controlled and NPC survivors use the same 09 state and 10 presentation. `actor.infected` does not receive fake equipment capability.

Missing 09 enrollment is diagnostic, not silently interpreted as empty hands. An explicitly enrolled empty hand emits no held-item command and is not an error.

## 5. Anatomical hand semantics

09 remains authoritative:

- `PRIMARY_RIGHT` = anatomical right hand;
- `SECONDARY_LEFT` = anatomical left hand.

These meanings never swap when the actor turns.

For screen coordinates with +Y downward and actor facing vector `f`:

`right = (-f.y, f.x)`

`left = -right`

10 derives offsets from those anatomical vectors rather than hardcoded screen left/right.

## 6. Recovered same-owner art

Recovery sources:

- First Fire `FFTacticalVisuals.gd` blob `c10388a851a797fe19932b84b2e2ab7377828e8f`;
- First Fire `FFTacticalTiles.gd` blob `732da9f6fff7b8dac60253e9d4ed4c9460f9fceb`;
- First Fire `tactical_atlas.svg` blob `2caff9a1c2ec84fc7d56e6b2c64bce953c575029`.

The recovered asset is a separate focused atlas:

`game/assets/held_item_atlas.svg` -> Git blob `6c29e8a925b6f107de8440e1dd8dc002ffd768cd`

It contains exact vector recovery/repacking of the relevant historical cells only:

- 0 knife — First Fire source 192;
- 1 club/baseball bat — 193;
- 2 hammer — 194;
- 3 improvised spear — 195;
- 4 crowbar — 196;
- 5 hatchet — 197;
- 6 pistol — 198;
- 7 shotgun — 199;
- 8 flashlight — 64;
- 9 headlamp — 65;
- 10 lantern — 66;
- 11 glow stick — 67;
- 12 road flare — 68.

The original ten protected Tick assets and the separately recovered 08 `actor_atlas.svg` remain byte-identical.

## 7. Semantic held-item mappings

Recognized initial WHAT item semantics:

- `item.utility_knife`, `item.kitchen_knife` -> knife;
- `item.wooden_club`, `item.baseball_bat` -> club;
- `item.hammer`;
- `item.improvised_spear`;
- `item.crowbar`;
- `item.hatchet`;
- `item.pistol`;
- `item.shotgun`;
- `item.flashlight`;
- `item.headlamp`;
- `item.lantern`;
- `item.glow_stick`;
- `item.road_flare`.

These are presentation mappings only. They define no damage, weight, ammo, durability, light output, tool capability, inventory size, or equip legality.

Unknown `item.*` held art returns typed UNKNOWN/diagnostic; there is no generic weapon or utility fallback.

## 8. Scale and native orientation

Recovered weapon silhouettes draw at:

`14 / 32` of one tactical cell.

Recovered utility icons draw at:

`12 / 32` of one tactical cell.

Scale follows item kind, not hand slot. A flashlight in primary remains utility-sized; a knife in secondary remains weapon-sized.

Recovered held art is treated as **EAST-native**.

Actor-facing rotation:

- EAST = `0°`;
- SOUTH = `+90°`;
- WEST = `180°`;
- NORTH = `-90°`.

Rotation is presentation-only.

## 9. Recovered hand offsets

Historical First Fire offsets are retained proportionally in cell units.

Primary/right center:

`actor_center + right * (11/32 cell) - forward * (1.5/32 cell)`

Secondary/left center:

`actor_center + left * (10.5/32 cell) - forward * (1/32 cell)`

The historical dark circular readability backdrop is retained and participates in the same BACK/FRONT pass as its item.

## 10. Occlusion/pass rules

### NORTH
- primary/right -> FRONT
- secondary/left -> FRONT

### SOUTH
- primary/right -> FRONT
- secondary/left -> FRONT

### EAST
- primary/right -> FRONT
- secondary/left -> BACK

### WEST
- primary/right -> BACK
- secondary/left -> FRONT

The BACK item remains real state/command; the later actor body draw naturally covers the far-side portion.

## 11. Draw command

`ActorHandDrawCommand` retains:

- stable actor ID;
- stable item ID;
- item semantic type;
- hand slot;
- BACK/FRONT pass;
- actor anchor/facing;
- local item center;
- draw size;
- rotation radians;
- copied ArtSelection / diagnostic reason.

Deterministic command order:

1. actor anchor Y;
2. actor anchor X;
3. stable actor ID;
4. hand slot.

Arbitrary multi-cell ACTOR occupancy is deduplicated to at most one command per occupied hand.

## 12. Visible discovery and diagnostics

The renderer scans only visible WHAT `ACTOR` occupancy, deduplicates survivor IDs, reads the canonical placement/facing, then reads 09 hand assignments.

A held item is expected to be a persistent unplaced WHAT `item.*` entity. Contradictory/stale truth is diagnostic, including:

- missing 09 enrollment;
- missing survivor placement;
- invalid ACTOR channel/facing/occupancy;
- missing assigned item entity;
- assigned non-`item.*` entity;
- assigned item simultaneously tactically placed;
- unknown held-item art;
- invalid scale/native-facing metadata;
- malformed selection/texture-load failure.

Diagnostics are bounded. Unknown content is never silently substituted.

## 13. Redraw and performance

No `_process()` polling.

Redraw is event-driven for:

- configure/view/pass/cache changes;
- WHAT reset;
- relevant visible survivor placement/removal;
- visible survivor hand enrollment/removal/assignment changes;
- deletion or tactical placement change of an item assigned to a visible survivor;
- 09 state reset.

Terrain, unrelated entities, and distant hand changes do not redraw when public-contract relevance can be established.

Visible ACTOR occupancy only, stable-ID deduplication, maximum two held-item commands per visible survivor, lazy texture cache, and no permanent Node per item preserve mobile/Safari scalability.

## 14. Public renderer contract

`ActorHandEquipmentLayerRenderer` exposes:

- `configure(world_state, art_catalog, hand_equipment_state) -> bool`
- `set_render_pass(pass) -> bool`
- `render_pass() -> int`
- `set_visible_window(origin, size_cells, cell_pixels) -> bool`
- `has_valid_view()`
- `plan_visible_commands() -> Array[ActorHandDrawCommand]`
- `clear_texture_cache()`
- bounded diagnostic reads
- `redraw_requested(reason)`

## 15. Forbidden ownership

10 does not own/import:

- 09 hand mutation or equip legality;
- Inventory/Containment, pickup/drop;
- item gameplay stats;
- combat/aiming/ammo/damage/muzzle flash;
- carried lighting behavior;
- Health/Needs/encumbrance;
- AI or WHEN;
- Collision/Movement/Locomotion;
- corpse/death state;
- camera/zoom/input/UI;
- generation;
- frozen reboot runtime;
- tactical composition itself.

## 16. Verification

Initial complete code head:

`fb875e5515a0a13ec6578a8ed72cb4d6af172cd2`

Dedicated **Actor Hand Equipment Presentation contract** run `31987226709` passed on that exact code head with:

- source-boundary checks;
- all protected/recovered art identities;
- Godot 4.7.1 import/parse;
- Art Catalog regression;
- 09 Actor Hand Equipment regression;
- 08 Living Actor Renderer regression;
- full 10 presentation smoke.

Dedicated **Recovered Art Catalog contract** run `31987226704` also passed on that exact code head.

The 10 smoke proves N/E/S/W rotation and offsets, EAST/WEST back/front hand assignment, NORTH/SOUTH both-front behavior, slot-independent item scale, stable item identity, explicit-empty behavior, missing/stale/unknown diagnostics, multi-cell deduplication, deterministic overlap ordering, and redraw filtering.

No production repair commit was required after the complete 10 candidate was published.

## 17. Future seams

- Tactical Renderer composes BACK -> 08 actor -> FRONT.
- Inventory/Containment and future timed equip actions mutate 09 without changing 10.
- two-handed items can later reserve both slots under an explicit 09/10 rule revision;
- item appearance/quality variants can extend Art Catalog without changing stable item identity;
- attack/aiming poses remain a later presentation contract;
- carried lighting reads the same stable item assignment through its own mechanic domain;
- detailed Inventory UI can inspect the same item IDs;
- Authored Visual Test Area can exercise this renderer once canonical composition exists.

## 18. North-star fit

Visible equipment makes real survival state readable directly in the Ultima-style world. The implementation stays small—two hands, cardinal rotation, simple occlusion—while preserving persistent physical identity and clean system boundaries underneath.

The two-pass contract gives physical-looking body occlusion without turning art into physics or turning 08 into an equipment renderer.
