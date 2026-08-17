extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const HealthClass = preload("res://scripts/simulation/actors/health/ActorHealthState.gd")
const NeedsClass = preload("res://scripts/simulation/actors/needs/ActorNeedsState.gd")
const HandStateClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentState.gd")
const HandMutationClass = preload("res://scripts/simulation/actors/equipment/ActorHandEquipmentMutationService.gd")
const Slots = preload("res://scripts/simulation/actors/equipment/ActorHandSlot.gd")
const InventoryStateClass = preload("res://scripts/simulation/inventory/InventoryContainmentState.gd")
const InventoryMutationClass = preload("res://scripts/simulation/inventory/InventoryContainmentMutationService.gd")
const CatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")
const CarryStateClass = preload("res://scripts/simulation/actors/carry/ActorCarryState.gd")
const CarryQueryClass = preload("res://scripts/simulation/actors/carry/ActorCarryQuery.gd")
const MoodletClass = preload("res://scripts/simulation/actors/moodlets/ActorMoodlet.gd")
const MoodletServiceClass = preload("res://scripts/simulation/actors/moodlets/ActorMoodletService.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_moodlet_contract()
    if failures.is_empty():
        print("ACTOR_MOODLETS_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ACTOR_MOODLETS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _fixture() -> Dictionary:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    wm.create_entity(&"actor.survivor", "actor.a")
    var health := HealthClass.new(world)
    health.enroll_actor("actor.a")
    var needs := NeedsClass.new(world)
    needs.enroll_actor("actor.a")
    var hands := HandStateClass.new()
    var hand_mutations := HandMutationClass.new(hands, world)
    hand_mutations.enroll_actor("actor.a")
    var inventory := InventoryStateClass.new()
    var inventory_mutations := InventoryMutationClass.new(inventory, world)
    inventory_mutations.enroll_container("actor.a")
    var catalog := CatalogClass.new()
    var weight_query := WeightQueryClass.new(world, catalog)
    var carry_state := CarryStateClass.new(world)
    carry_state.enroll_actor("actor.a")
    var carry_query := CarryQueryClass.new(world, hands, inventory, weight_query, carry_state)
    var moodlets := MoodletServiceClass.new(health, needs, carry_query)
    return {
        "wm": wm,
        "health": health,
        "needs": needs,
        "hand_mutations": hand_mutations,
        "catalog": catalog,
        "carry_state": carry_state,
        "carry_query": carry_query,
        "moodlets": moodlets,
    }

func _test_moodlet_contract() -> void:
    var fixture: Dictionary = _fixture()
    var wm: WorldMutationService = fixture["wm"]
    var health: ActorHealthState = fixture["health"]
    var needs: ActorNeedsState = fixture["needs"]
    var hand_mutations: ActorHandEquipmentMutationService = fixture["hand_mutations"]
    var catalog: ItemPhysicalPropertyCatalog = fixture["catalog"]
    var carry_state: ActorCarryState = fixture["carry_state"]
    var moodlets: ActorMoodletService = fixture["moodlets"]

    var initial: Dictionary = moodlets.moodlets_for("actor.a")
    _check(bool(initial.get("ok", false)), "fully classified actor derives moodlets")
    _check(_ids(initial) == [&"well_rested"], "fresh actor gets only Well Rested")

    needs.set_all("actor.a", 50, 55, 50, 50)
    var warning: Dictionary = moodlets.moodlets_for("actor.a")
    var warning_ids: Array[StringName] = _ids(warning)
    _check(warning_ids.has(&"tired") and warning_ids.has(&"hungry") and warning_ids.has(&"thirsty") and warning_ids.has(&"sleepy"), "warning thresholds derive readable moodlets")
    _check(not warning_ids.has(&"well_rested"), "well rested disappears when pressure rises")

    needs.set_all("actor.a", 80, 85, 80, 80)
    var critical: Dictionary = moodlets.moodlets_for("actor.a")
    var critical_ids: Array[StringName] = _ids(critical)
    _check(critical_ids.has(&"exhausted") and not critical_ids.has(&"tired"), "fatigue category emits strongest-only moodlet")
    _check(critical_ids.has(&"starving") and not critical_ids.has(&"hungry"), "hunger category emits strongest-only moodlet")
    _check(critical_ids.has(&"dehydrated") and not critical_ids.has(&"thirsty"), "thirst category emits strongest-only moodlet")
    _check(critical_ids.has(&"sleep_deprived") and not critical_ids.has(&"sleepy"), "sleep category emits strongest-only moodlet")

    health.set_hp("actor.a", 25)
    var injured: Dictionary = moodlets.moodlets_for("actor.a")
    _check(_ids(injured).has(&"badly_injured") and not _ids(injured).has(&"injured"), "critical health moodlet replaces generic injury")
    health.set_hp("actor.a", 0)
    var zero_hp: Dictionary = moodlets.moodlets_for("actor.a")
    _check(_ids(zero_hp).has(&"no_vitality") and not _ids(zero_hp).has(&"badly_injured"), "zero HP is readable without implementing corpse state")

    wm.create_entity(&"item.rock", "item.rock")
    catalog.register_profile(&"item.rock", 20000)
    _check(hand_mutations.set_item("actor.a", Slots.Value.PRIMARY_RIGHT, "item.rock"), "heavy item held")
    var overburdened: Dictionary = moodlets.moodlets_for("actor.a")
    _check(_ids(overburdened).has(&"overburdened"), "over-capacity carry derives Overburdened")
    carry_state.set_capacity_grams("actor.a", 25000)
    var heavy: Dictionary = moodlets.moodlets_for("actor.a")
    _check(_ids(heavy).has(&"heavy_load") and not _ids(heavy).has(&"overburdened"), "75-100 percent carry derives Heavy Load")

    var ordered: Array = overburdened.get("moodlets", [])
    _check(not ordered.is_empty() and (ordered[0] as ActorMoodlet).moodlet_id == &"no_vitality", "moodlets sort by deterministic priority")
    var first_copy: ActorMoodlet = ordered[0]
    first_copy.display_name = "tampered"
    var fresh_again: Dictionary = moodlets.moodlets_for("actor.a")
    _check((fresh_again.get("moodlets", []) as Array)[0].display_name != "tampered", "derived moodlet reads do not expose stored mutable state")

    var unconfigured := MoodletServiceClass.new(HealthClass.new(), needs, fixture["carry_query"])
    var missing: Dictionary = unconfigured.moodlets_for("actor.a")
    _check(not bool(missing.get("ok", true)) and String(missing.get("reason", "")) == "health_unclassified", "missing source domain fails explicitly")

func _ids(result_value: Dictionary) -> Array[StringName]:
    var result: Array[StringName] = []
    var values: Array = result_value.get("moodlets", [])
    for value: Variant in values:
        var moodlet: ActorMoodlet = value
        result.append(moodlet.moodlet_id)
    return result

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
