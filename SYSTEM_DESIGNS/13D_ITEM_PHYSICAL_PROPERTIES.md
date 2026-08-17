# Tick Survival Lab — 13D Item Physical Properties

Status: **APPROVED — user explicitly approved all System 13 children for implementation on 2026-08-16**

Parent: `13_ACTOR_STATS_STATUS_ARCHITECTURE.md`.

## Goal
Own reusable physical item-definition facts needed by more than one mechanic, beginning with real item weight, without teaching Inventory/Hands/Carry where items are or duplicating item location truth.

## Non-goals
13D does not own containment, hand assignment, pickup/drop/equip actions, carried totals, item rendering, quantity/stacks, condition/durability, or a universal item metadata bag.

## Owner
`game/scripts/simulation/items/properties/`:
- `ItemPhysicalProfile.gd`
- `ItemPhysicalPropertyCatalog.gd`
- `ItemWeightQuery.gd`

## Public contract
`ItemPhysicalPropertyCatalog` explicitly registers a profile by semantic `item.*` type and provides mutation-safe profile reads. `ItemWeightQuery` combines read-only WHAT item identity/type with the catalog and returns typed KNOWN/UNKNOWN/INVALID results for a stable item ID.

## Weight representation
Canonical v1 weight is a positive integer number of **grams**. Integer grams avoid floating drift and convert cleanly for later display (`1000 g = 1 kg`).

A profile contains:
- semantic item type (`StringName` beginning `item.`);
- `weight_grams: int > 0`.

The catalog intentionally ships with **no guessed universal weights**. Content/demo composition must explicitly register actual item types it creates. Same-owner recovered weights may be registered by later content where exact values exist.

## Type defaults
V1 weight is a semantic-type definition, not redundant state copied onto every item entity. All instances of the same semantic type use the profile unless a future explicitly designed per-instance physical override system is needed.

## Missing-data rule
Missing profile is UNKNOWN/fail-closed for weight consumers. Carry must not silently assume zero weight for an unclassified possessed item.

## Persistence
The catalog is content/configuration, not per-save actor state; it has no save snapshot. World items remain stable WHAT entities. Future save orchestration persists item identity/location through their owning systems.

## Dependencies
Allowed: read-only WHAT in `ItemWeightQuery`.
Forbidden: 09 Hands, 11 Inventory, 12 Transfer, Carry, Health, Needs, Skills, UI/render/art, reboot.

## Failure cases
Reject invalid semantic IDs, zero/negative weights, duplicate registrations unless explicitly unregistered/replaced through the catalog API, missing/non-item WHAT entities, and missing profile queries.

## Tests
Dedicated smoke covers registration, deterministic semantic ordering, positive integer grams, copy-safe profiles, duplicate rejection, WHAT item resolution, missing profile UNKNOWN, non-item INVALID, and no location-system imports.

## Future seams
Bulk or other genuinely shared immutable physical facts may be added as explicit profile fields later. Per-instance modifiers require their own approved typed state rather than converting this catalog into a generic dictionary.

## North-star fit
Real weight creates physical survival consequences while keeping item location and item definition cleanly separated.

## Approved decisions — 2026-08-16
1. Weight is canonical integer grams.
2. Weight is registered by semantic item type in v1.
3. Missing weight classification is UNKNOWN, never implicit zero.
4. The catalog contains no guessed built-in weights merely to populate UI.
5. 13D never owns item disposition or carried totals.
