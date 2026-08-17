extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const CatalogClass = preload("res://scripts/simulation/items/properties/ItemPhysicalPropertyCatalog.gd")
const WeightQueryClass = preload("res://scripts/simulation/items/properties/ItemWeightQuery.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_properties_contract()
    if failures.is_empty():
        print("ITEM_PHYSICAL_PROPERTIES_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ITEM_PHYSICAL_PROPERTIES_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_properties_contract() -> void:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    var catalog := CatalogClass.new()
    _check(catalog.semantic_types().is_empty(), "catalog begins empty rather than guessing weights")
    _check(catalog.register_profile(&"item.hammer", 900), "positive integer gram profile registers")
    _check(catalog.register_profile(&"item.backpack", 1000), "second profile registers")
    _check(not catalog.register_profile(&"item.hammer", 950), "duplicate semantic profile rejected")
    _check(not catalog.register_profile(&"item.zero", 0), "zero weight rejected")
    _check(not catalog.register_profile(&"prop.chair", 1000), "non-item semantic rejected")
    var types: Array[StringName] = catalog.semantic_types()
    _check(types.size() == 2 and types[0] == &"item.backpack" and types[1] == &"item.hammer", "semantic types sort deterministically")
    var profile = catalog.profile(&"item.hammer")
    _check(profile != null and profile.weight_grams == 900, "profile read returns registered weight")
    if profile != null:
        profile.weight_grams = 1
    _check(catalog.weight_grams(&"item.hammer") == 900, "profile reads are copy-safe")

    wm.create_entity(&"item.hammer", "item.a")
    wm.create_entity(&"item.unknown", "item.b")
    wm.create_entity(&"prop.chair", "prop.a")
    var query := WeightQueryClass.new(world, catalog)
    var known: Dictionary = query.query("item.a")
    _check(int(known.get("status", -1)) == WeightQueryClass.Status.KNOWN and int(known.get("weight_grams", 0)) == 900, "WHAT item resolves semantic weight")
    var unknown: Dictionary = query.query("item.b")
    _check(int(unknown.get("status", -1)) == WeightQueryClass.Status.UNKNOWN and String(unknown.get("reason", "")) == "weight_unclassified", "missing profile is UNKNOWN not zero")
    var invalid: Dictionary = query.query("prop.a")
    _check(int(invalid.get("status", -1)) == WeightQueryClass.Status.INVALID, "non-item WHAT entity is invalid")
    var missing: Dictionary = query.query("missing")
    _check(int(missing.get("status", -1)) == WeightQueryClass.Status.UNKNOWN, "missing item identity is unknown")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
