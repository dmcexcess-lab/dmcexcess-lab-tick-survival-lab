extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const FootprintClass = preload("res://scripts/foundation/spatial/SpatialFootprint.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const Layers = preload("res://scripts/foundation/spatial/SpatialLayer.gd")
const CatalogClass = preload("res://scripts/art/ArtCatalog.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const RendererClass = preload("res://scripts/render/ActorHandEquipmentLayerRenderer.gd")

var failures: Array[String] = []
var redraw_reasons: Array[StringName] = []

func _initialize() -> void:
    _test_passes_rotation_offsets_and_item_scale()
    _test_empty_unknown_and_stale_diagnostics()
    _test_multicell_dedup_and_order()
    _test_redraw_filtering()

    if failures.is_empty():
        print("ACTOR_HAND_EQUIPMENT_PRESENTATION_SMOKE_OK")
        quit(0)
        return

    for failure: String in failures:
        push_error("ACTOR_HAND_EQUIPMENT_PRESENTATION_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var world_mutations := WorldMutationClass.new(world)
    var hand_state := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hand_state, world)
    var catalog := CatalogClass.new()
    return {
        "world": world,
        "world_mutations": world_mutations,
        "hand_state": hand_state,
        "hand_mutations": hand_mutations,
        "catalog": catalog,
    }

func _create_survivor(
    fixture: Dictionary,
    actor_id: String,
    anchor: Vector2i,
    facing: int,
    footprint: SpatialFootprint = null,
    enroll: bool = true
) -> bool:
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var hand_mutations: ActorHandEquipmentMutationService = fixture["hand_mutations"]
    var actual_footprint: SpatialFootprint = footprint
    if actual_footprint == null:
        actual_footprint = FootprintClass.single_cell()
    if world_mutations.create_entity(&"actor.survivor", actor_id).is_empty():
        return false
    if not world_mutations.set_placement(actor_id, Layers.Channel.ACTOR, anchor, facing, actual_footprint):
        return false
    return not enroll or hand_mutations.enroll_actor(actor_id)

func _create_item(fixture: Dictionary, item_id: String, semantic_type: StringName) -> bool:
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    return not world_mutations.create_entity(semantic_type, item_id).is_empty()

func _renderer(fixture: Dictionary, pass_value: int, origin: Vector2i = Vector2i.ZERO, size: Vector2i = Vector2i(8, 8)) -> ActorHandEquipmentLayerRenderer:
    var renderer := RendererClass.new()
    _check(renderer.configure(fixture["world"], fixture["catalog"], fixture["hand_state"]), "renderer configures")
    _check(renderer.set_render_pass(pass_value), "renderer accepts valid pass")
    _check(renderer.set_visible_window(origin, size, 32.0), "renderer accepts visible window")
    return renderer

func _test_passes_rotation_offsets_and_item_scale() -> void:
    var fixture: Dictionary = _fixture()
    _check(_create_survivor(fixture, "survivor.a", Vector2i(2, 2), Facing.Value.EAST), "create enrolled survivor")
    _check(_create_item(fixture, "item.flash.a", &"item.flashlight"), "create flashlight")
    _check(_create_item(fixture, "item.knife.a", &"item.utility_knife"), "create knife")
    var hand_mutations: ActorHandEquipmentMutationService = fixture["hand_mutations"]
    _check(hand_mutations.set_item("survivor.a", Slots.Value.PRIMARY_RIGHT, "item.flash.a"), "flashlight may occupy primary/right")
    _check(hand_mutations.set_item("survivor.a", Slots.Value.SECONDARY_LEFT, "item.knife.a"), "knife may occupy secondary/left")

    var back := _renderer(fixture, RendererClass.Pass.BACK)
    var front := _renderer(fixture, RendererClass.Pass.FRONT)

    var back_commands: Array = back.plan_visible_commands()
    var front_commands: Array = front.plan_visible_commands()
    _check(back_commands.size() == 1, "EAST has exactly one BACK hand")
    _check(front_commands.size() == 1, "EAST has exactly one FRONT hand")
    if back_commands.size() == 1:
        var command: ActorHandDrawCommand = back_commands[0]
        _check(command.hand_slot == Slots.Value.SECONDARY_LEFT, "EAST secondary/left is BACK")
        _check(command.item_id == "item.knife.a", "EAST back hand keeps stable knife identity")
        _check(is_equal_approx(command.draw_size, 14.0), "knife keeps weapon scale even in secondary")
        _check(is_equal_approx(command.rotation_radians, 0.0), "EAST native art has zero rotation")
        _check(_vec_close(command.center, Vector2(79.0, 69.5)), "EAST secondary uses historical left-hand offset")
    if front_commands.size() == 1:
        var command: ActorHandDrawCommand = front_commands[0]
        _check(command.hand_slot == Slots.Value.PRIMARY_RIGHT, "EAST primary/right is FRONT")
        _check(command.item_id == "item.flash.a", "EAST front hand keeps stable flashlight identity")
        _check(is_equal_approx(command.draw_size, 12.0), "flashlight keeps utility scale even in primary")
        _check(is_equal_approx(command.rotation_radians, 0.0), "EAST flashlight has zero rotation")
        _check(_vec_close(command.center, Vector2(78.5, 91.0)), "EAST primary uses historical right-hand offset")

    var world_mutations: WorldMutationService = fixture["world_mutations"]
    var single := FootprintClass.single_cell()

    _check(world_mutations.set_placement("survivor.a", Layers.Channel.ACTOR, Vector2i(2, 2), Facing.Value.WEST, single), "turn survivor WEST")
    back_commands = back.plan_visible_commands()
    front_commands = front.plan_visible_commands()
    _check(back_commands.size() == 1 and back_commands[0].hand_slot == Slots.Value.PRIMARY_RIGHT, "WEST primary/right is BACK")
    _check(front_commands.size() == 1 and front_commands[0].hand_slot == Slots.Value.SECONDARY_LEFT, "WEST secondary/left is FRONT")
    if back_commands.size() == 1:
        _check(is_equal_approx(back_commands[0].rotation_radians, PI), "WEST rotates held art 180 degrees")
        _check(_vec_close(back_commands[0].center, Vector2(81.5, 69.0)), "WEST primary offset rotates anatomically")

    _check(world_mutations.set_placement("survivor.a", Layers.Channel.ACTOR, Vector2i(2, 2), Facing.Value.NORTH, single), "turn survivor NORTH")
    back_commands = back.plan_visible_commands()
    front_commands = front.plan_visible_commands()
    _check(back_commands.is_empty(), "NORTH has no BACK hand")
    _check(front_commands.size() == 2, "NORTH shows both hands in FRONT")
    if front_commands.size() == 2:
        _check(front_commands[0].hand_slot == Slots.Value.PRIMARY_RIGHT and front_commands[1].hand_slot == Slots.Value.SECONDARY_LEFT, "NORTH hand command order is stable slot order")
        _check(is_equal_approx(front_commands[0].rotation_radians, -PI * 0.5), "NORTH rotates held art -90 degrees")
        _check(_vec_close(front_commands[0].center, Vector2(91.0, 81.5)), "NORTH primary offset")
        _check(_vec_close(front_commands[1].center, Vector2(69.5, 81.0)), "NORTH secondary offset")

    _check(world_mutations.set_placement("survivor.a", Layers.Channel.ACTOR, Vector2i(2, 2), Facing.Value.SOUTH, single), "turn survivor SOUTH")
    back_commands = back.plan_visible_commands()
    front_commands = front.plan_visible_commands()
    _check(back_commands.is_empty(), "SOUTH has no BACK hand")
    _check(front_commands.size() == 2, "SOUTH shows both hands in FRONT")
    if front_commands.size() == 2:
        _check(is_equal_approx(front_commands[0].rotation_radians, PI * 0.5), "SOUTH rotates held art +90 degrees")
        _check(_vec_close(front_commands[0].center, Vector2(69.0, 78.5)), "SOUTH primary offset")
        _check(_vec_close(front_commands[1].center, Vector2(90.5, 79.0)), "SOUTH secondary offset")

func _test_empty_unknown_and_stale_diagnostics() -> void:
    var fixture: Dictionary = _fixture()
    _check(_create_survivor(fixture, "survivor.empty", Vector2i(1, 1), Facing.Value.SOUTH), "create empty enrolled survivor")
    var front := _renderer(fixture, RendererClass.Pass.FRONT)
    _check(front.plan_visible_commands().is_empty(), "explicit empty hands emit no commands")

    _check(_create_survivor(fixture, "survivor.unknown", Vector2i(2, 1), Facing.Value.SOUTH, null, false), "create unenrolled survivor")
    var commands: Array = front.plan_visible_commands()
    var found_unclassified: bool = false
    for command: ActorHandDrawCommand in commands:
        if command.actor_id == "survivor.unknown" and command.diagnostic_reason() == "hand_equipment_unclassified":
            found_unclassified = true
    _check(found_unclassified, "missing hand-state enrollment is diagnostic")

    _check(_create_survivor(fixture, "survivor.stale", Vector2i(3, 1), Facing.Value.EAST), "create stale-test survivor")
    _check(_create_item(fixture, "item.stale", &"item.flashlight"), "create stale-test item")
    var hand_mutations: ActorHandEquipmentMutationService = fixture["hand_mutations"]
    var world_mutations: WorldMutationService = fixture["world_mutations"]
    _check(hand_mutations.set_item("survivor.stale", Slots.Value.PRIMARY_RIGHT, "item.stale"), "assign stale-test item")
    _check(world_mutations.remove_entity("item.stale"), "remove assigned item from WHAT")
    commands = front.plan_visible_commands()
    var found_missing: bool = false
    for command: ActorHandDrawCommand in commands:
        if command.actor_id == "survivor.stale" and command.diagnostic_reason() == "held_item_entity_missing":
            found_missing = true
    _check(found_missing, "stale missing assigned item is diagnostic")

    _check(_create_survivor(fixture, "survivor.unknown_art", Vector2i(4, 1), Facing.Value.EAST), "create unknown-art survivor")
    _check(_create_item(fixture, "item.unknown_art", &"item.future_tool"), "create unknown-art item")
    _check(hand_mutations.set_item("survivor.unknown_art", Slots.Value.PRIMARY_RIGHT, "item.unknown_art"), "assign unknown-art item")
    commands = front.plan_visible_commands()
    var found_art_unknown: bool = false
    for command: ActorHandDrawCommand in commands:
        if command.actor_id == "survivor.unknown_art" and command.diagnostic_reason() == "held_item_unclassified":
            found_art_unknown = true
    _check(found_art_unknown, "unknown held-item art fails visibly")

func _test_multicell_dedup_and_order() -> void:
    var fixture: Dictionary = _fixture()
    var wide := FootprintClass.rectangle(2, 1)
    _check(_create_survivor(fixture, "survivor.b", Vector2i(2, 2), Facing.Value.NORTH, wide), "create multi-cell survivor b")
    _check(_create_survivor(fixture, "survivor.a", Vector2i(2, 2), Facing.Value.NORTH, wide), "create overlapping multi-cell survivor a")
    _check(_create_item(fixture, "item.a.primary", &"item.pistol"), "create a pistol")
    _check(_create_item(fixture, "item.a.secondary", &"item.flashlight"), "create a flashlight")
    _check(_create_item(fixture, "item.b.primary", &"item.shotgun"), "create b shotgun")
    _check(_create_item(fixture, "item.b.secondary", &"item.lantern"), "create b lantern")
    var hands: ActorHandEquipmentMutationService = fixture["hand_mutations"]
    _check(hands.set_item("survivor.a", Slots.Value.PRIMARY_RIGHT, "item.a.primary"), "equip a primary")
    _check(hands.set_item("survivor.a", Slots.Value.SECONDARY_LEFT, "item.a.secondary"), "equip a secondary")
    _check(hands.set_item("survivor.b", Slots.Value.PRIMARY_RIGHT, "item.b.primary"), "equip b primary")
    _check(hands.set_item("survivor.b", Slots.Value.SECONDARY_LEFT, "item.b.secondary"), "equip b secondary")
    var front := _renderer(fixture, RendererClass.Pass.FRONT)
    var commands: Array = front.plan_visible_commands()
    _check(commands.size() == 4, "multi-cell occupancy deduplicates to two hands per survivor")
    if commands.size() == 4:
        _check(commands[0].actor_id == "survivor.a" and commands[1].actor_id == "survivor.a", "stable ID orders overlapping survivor a first")
        _check(commands[2].actor_id == "survivor.b" and commands[3].actor_id == "survivor.b", "stable ID orders survivor b second")
        _check(commands[0].hand_slot == Slots.Value.PRIMARY_RIGHT and commands[1].hand_slot == Slots.Value.SECONDARY_LEFT, "slot order deterministic inside actor")

func _test_redraw_filtering() -> void:
    redraw_reasons.clear()
    var fixture: Dictionary = _fixture()
    _check(_create_survivor(fixture, "survivor.visible", Vector2i(2, 2), Facing.Value.EAST), "create visible redraw survivor")
    _check(_create_survivor(fixture, "survivor.distant", Vector2i(20, 20), Facing.Value.EAST), "create distant redraw survivor")
    _check(_create_item(fixture, "item.visible.a", &"item.flashlight"), "create visible item a")
    _check(_create_item(fixture, "item.visible.b", &"item.pistol"), "create visible item b")
    _check(_create_item(fixture, "item.distant.a", &"item.lantern"), "create distant item")
    var hands: ActorHandEquipmentMutationService = fixture["hand_mutations"]
    _check(hands.set_item("survivor.visible", Slots.Value.PRIMARY_RIGHT, "item.visible.a"), "equip visible item")
    _check(hands.set_item("survivor.distant", Slots.Value.PRIMARY_RIGHT, "item.distant.a"), "equip distant item")

    var renderer := RendererClass.new()
    renderer.redraw_requested.connect(_on_redraw)
    _check(renderer.configure(fixture["world"], fixture["catalog"], fixture["hand_state"]), "redraw renderer configures")
    _check(renderer.set_render_pass(RendererClass.Pass.FRONT), "redraw renderer front pass")
    _check(renderer.set_visible_window(Vector2i.ZERO, Vector2i(8, 8), 32.0), "redraw renderer view")
    redraw_reasons.clear()

    var world_mutations: WorldMutationService = fixture["world_mutations"]
    _check(world_mutations.set_terrain(Vector2i(1, 1), &"ground.grass"), "terrain mutation succeeds")
    _check(redraw_reasons.is_empty(), "terrain mutation does not redraw hand presentation")

    _check(hands.set_item("survivor.distant", Slots.Value.SECONDARY_LEFT, "item.visible.b"), "distant hand change succeeds")
    _check(redraw_reasons.is_empty(), "distant hand assignment does not redraw visible hand layer")
    _check(hands.clear_slot("survivor.distant", Slots.Value.SECONDARY_LEFT), "clear distant temporary assignment")
    redraw_reasons.clear()

    _check(hands.set_item("survivor.visible", Slots.Value.SECONDARY_LEFT, "item.visible.b"), "visible hand change succeeds")
    _check(redraw_reasons.has(&"hand_assignment_changed"), "visible hand assignment redraws")
    redraw_reasons.clear()

    _check(world_mutations.remove_entity("item.visible.b"), "remove visible assigned item")
    _check(redraw_reasons.has(&"held_item_entity_changed"), "visible assigned item deletion redraws")
    redraw_reasons.clear()

    _check(world_mutations.set_placement("survivor.visible", Layers.Channel.ACTOR, Vector2i(3, 2), Facing.Value.EAST, FootprintClass.single_cell()), "move visible survivor")
    _check(redraw_reasons.has(&"survivor_placement_changed"), "visible survivor move redraws")

func _on_redraw(reason: StringName) -> void:
    redraw_reasons.append(reason)

func _vec_close(actual: Vector2, expected: Vector2) -> bool:
    return actual.distance_to(expected) < 0.001

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
