extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CollisionCatalogClass = preload("res://scripts/simulation/collision/CollisionCatalog.gd")
const TraversalClass = preload("res://scripts/simulation/movement/MovementTraversalPolicy.gd")
const FixtureClass = preload("res://scripts/demo/CanonicalDemoFixture.gd")
const Facing = preload("res://scripts/foundation/spatial/SpatialFacing.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const NeedsClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const PhysicalCatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const MoodletServiceClass = preload("res://scripts/simulation/actors/moodlets/ActorMoodletService.gd")
const SummaryClass = preload("res://scripts/ui/ActorStatusSummaryQuery.gd")
const InspectionClass = preload("res://scripts/ui/FacingInspectionQuery.gd")
const HudClass = preload("res://scripts/ui/CanonicalStatusHud.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const Intents = preload("res://scripts/input/PlayerActionIntent.gd")

var failures: Array[String] = []

func _initialize() -> void:
    var world := WorldStateClass.new()
    var mutations := WorldMutationClass.new(world)
    var collision_catalog := CollisionCatalogClass.new()
    var traversal := TraversalClass.new()
    _check(FixtureClass.build(world, mutations, collision_catalog, traversal), "canonical demo fixture builds")

    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    _check(hand_mutations.enroll_actor(FixtureClass.PLAYER_ID), "demo actor enrolls in real hand state")

    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    _check(inventory_mutations.enroll_container(FixtureClass.PLAYER_ID), "demo actor enrolls as real root inventory container")

    var health := HealthClass.new(world)
    _check(health.enroll_actor(FixtureClass.PLAYER_ID), "demo actor enrolls in real health state")
    var needs := NeedsClass.new(world)
    _check(needs.enroll_actor(FixtureClass.PLAYER_ID), "demo actor enrolls in real needs state")

    var physical_catalog := PhysicalCatalogClass.new()
    var weight_query := WeightQueryClass.new(world, physical_catalog)
    var carry_state := CarryStateClass.new(world)
    _check(carry_state.enroll_actor(FixtureClass.PLAYER_ID), "demo actor enrolls in real carry state")
    var carry_query := CarryQueryClass.new(world, hands, inventory, weight_query, carry_state)
    var moodlets := MoodletServiceClass.new(health, needs, carry_query)
    var summary_query := SummaryClass.new(health, needs, carry_query, moodlets)
    var inspection_query := InspectionClass.new(world)

    _check_initial_summary(summary_query)
    _check_inspection(world, mutations, inspection_query)
    _check_hud(world, mutations, needs, summary_query, inspection_query)

    if failures.is_empty():
        print("CANONICAL_HUD_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("CANONICAL_HUD_SMOKE_FAIL: %s" % failure)
    quit(1)

func _check_initial_summary(summary_query: ActorStatusSummaryQuery) -> void:
    var summary: Dictionary = summary_query.query(FixtureClass.PLAYER_ID)
    _check(bool(summary.get("ok", false)), "initial actor status summary is known")
    _check(int(summary.get("current_hp", -1)) == 100, "initial HP current is canonical 100")
    _check(int(summary.get("max_hp", -1)) == 100, "initial HP max is canonical 100")
    _check(int(summary.get("fatigue", -1)) == 0, "initial fatigue pressure is zero")
    _check(int(summary.get("hunger", -1)) == 0, "initial hunger pressure is zero")
    _check(int(summary.get("thirst", -1)) == 0, "initial thirst pressure is zero")
    _check(int(summary.get("sleep_pressure", -1)) == 0, "initial sleep pressure is zero")
    _check(int(summary.get("carry_weight_grams", -1)) == 0, "empty real hands/inventory derive zero carried grams")
    _check(int(summary.get("carry_capacity_grams", -1)) == 18000, "carry capacity uses canonical 18 kg default")
    var labels: Array = summary.get("moodlet_labels", [])
    _check(labels.has("Well Rested"), "boot moodlets derive Well Rested from real needs state")

func _check_inspection(
    world: WorldState,
    mutations: WorldMutationService,
    inspection_query: FacingInspectionQuery
) -> void:
    var initial: Dictionary = inspection_query.query(FixtureClass.PLAYER_ID)
    _check(bool(initial.get("ok", false)), "initial facing inspection is known")
    _check(initial.get("target_cell", Vector2i(-1, -1)) == Vector2i(6, 9), "north inspection targets one cell ahead")
    _check(String(initial.get("facing_label", "")) == "NORTH", "inspection reads canonical north facing")
    _check(String(initial.get("label", "")) == "Road", "initial looking-at label reads road terrain")

    _set_player_placement(world, mutations, FixtureClass.PLAYER_START, Facing.Value.EAST)
    var east: Dictionary = inspection_query.query(FixtureClass.PLAYER_ID)
    _check(east.get("target_cell", Vector2i(-1, -1)) == Vector2i(7, 10), "east facing changes inspected cell")
    _check(String(east.get("label", "")) == "Grass Lush", "east inspection reads new real terrain")

    _set_player_placement(world, mutations, Vector2i(2, 0), Facing.Value.SOUTH)
    var wall: Dictionary = inspection_query.query(FixtureClass.PLAYER_ID)
    _check(wall.get("target_cell", Vector2i(-1, -1)) == Vector2i(2, 1), "south inspection targets authored wall cell")
    _check(String(wall.get("label", "")) == "House Wall", "structure inspection wins over underlying terrain")

    _set_player_placement(world, mutations, FixtureClass.PLAYER_START, Facing.Value.NORTH)

func _check_hud(
    world: WorldState,
    mutations: WorldMutationService,
    needs: ActorNeedsState,
    summary_query: ActorStatusSummaryQuery,
    inspection_query: FacingInspectionQuery
) -> void:
    _set_player_placement(world, mutations, FixtureClass.PLAYER_START, Facing.Value.NORTH)
    var kernel := TickKernelClass.new(FixtureClass.PLAYER_ID)
    var hud := HudClass.new()
    get_root().add_child(hud)
    _check(hud.configure(kernel, summary_query, inspection_query, FixtureClass.PLAYER_ID), "canonical HUD configures from read-only query seams")
    var presentation: Dictionary = hud.presentation_snapshot()
    _check(String(presentation.get("line_1", "")).contains("Tick 0"), "HUD displays authoritative tick")
    _check(String(presentation.get("line_1", "")).contains("Facing NORTH"), "HUD displays canonical facing")
    _check(String(presentation.get("line_2", "")) == "Looking at: Road", "HUD displays recovered-style looking-at line")
    _check(String(presentation.get("line_3", "")).contains("HP 100/100"), "HUD displays real HP")
    _check(String(presentation.get("line_3", "")).contains("Fatigue 0"), "HUD displays real fatigue")
    _check(String(presentation.get("line_3", "")).contains("Hunger 0"), "HUD displays real hunger")
    _check(String(presentation.get("line_3", "")).contains("Thirst 0"), "HUD displays real thirst")
    _check(String(presentation.get("line_3", "")).contains("Sleep pressure 0"), "HUD displays real sleep pressure")
    _check(String(presentation.get("line_4", "")).contains("Carry 0.0 / 18.0 kg"), "HUD displays derived carry weight/capacity")
    _check(String(presentation.get("line_4", "")).contains("Well Rested"), "HUD displays derived moodlet")

    _check(needs.set_need(FixtureClass.PLAYER_ID, NeedsClass.HUNGER, 60), "test can mutate canonical hunger through owning state")
    hud.refresh()
    presentation = hud.presentation_snapshot()
    _check(String(presentation.get("line_4", "")).contains("Hungry"), "HUD refresh derives changed moodlet instead of storing it")

    hud.present_action_result(Intents.TURN_RIGHT, true, "", 3)
    presentation = hud.presentation_snapshot()
    _check(String(presentation.get("line_1", "")).contains("Turn Right"), "HUD presents semantic action result")
    hud.queue_free()

func _set_player_placement(
    world: WorldState,
    mutations: WorldMutationService,
    anchor: Vector2i,
    facing: int
) -> void:
    var current: WorldPlacement = world.placement(FixtureClass.PLAYER_ID)
    _check(current != null, "player placement exists before inspection mutation")
    if current == null:
        return
    _check(
        mutations.set_placement(
            FixtureClass.PLAYER_ID,
            current.channel,
            anchor,
            facing,
            current.footprint,
            current.structure_axis
        ),
        "test placement mutation succeeds"
    )

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
