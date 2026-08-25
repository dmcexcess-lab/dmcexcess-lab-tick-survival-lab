extends SceneTree

const WorldStateClass = preload("res://scripts/foundation/world/WorldState.gd")
const WorldMutationClass = preload("res://scripts/foundation/world/WorldMutationService.gd")
const TickKernelClass = preload("res://scripts/foundation/time/TickKernel.gd")
const TimeProfileClass = preload("res://scripts/simulation/world_time/WorldTimeProfile.gd")
const FreshProfileClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessProfile.gd")
const FreshCatalogClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessProfileCatalog.gd")
const FreshStateClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessState.gd")
const AmbientClass = preload("res://scripts/simulation/items/freshness/AmbientSpoilageEnvironmentProvider.gd")
const FreshMutationClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessMutationService.gd")
const FreshQueryClass = preload("res://scripts/simulation/items/freshness/ItemFreshnessQuery.gd")

var failures: Array[String] = []

func _initialize() -> void:
    _test_freshness_contract()
    if failures.is_empty():
        print("ITEM_FRESHNESS_SMOKE_OK")
        quit(0)
        return
    for failure: String in failures:
        push_error("ITEM_FRESHNESS_SMOKE_FAIL: %s" % failure)
    quit(1)

func _test_freshness_contract() -> void:
    var world := WorldStateClass.new()
    var wm := WorldMutationClass.new(world)
    var kernel := TickKernelClass.new()
    var time_profile := TimeProfileClass.new()
    var catalog := FreshCatalogClass.new(time_profile)
    var state := FreshStateClass.new()
    var ambient := AmbientClass.new()
    var providers: Array[SpoilageEnvironmentProvider] = [ambient]
    var mutations := FreshMutationClass.new(world, state, catalog, providers)
    var query := FreshQueryClass.new(world, state, catalog, kernel, providers)

    _check(time_profile.is_valid(), "world time profile valid")
    _check(catalog.semantic_types().size() == 6, "six Candidate 001 perishables registered")
    _check(catalog.has_profile(&"item.food.apple"), "apple classified perishable")
    _check(not catalog.has_profile(&"item.food.canned_beans"), "canned beans stay shelf stable")
    _check(ambient.exposure_ticks_at(12345) == 12345, "ambient cumulative exposure is authoritative tick")
    _check(mutations.is_ready() and query.is_ready(), "freshness services ready")

    _check(wm.create_entity(&"item.food.apple", "item.apple.a") == "item.apple.a", "apple created")
    _check(wm.create_entity(&"item.food.milk_carton", "item.milk.a") == "item.milk.a", "milk created")
    _check(wm.create_entity(&"item.food.canned_beans", "item.can.a") == "item.can.a", "can created")
    _check(mutations.enroll_virgin_item("item.apple.a", 0), "apple virgin freshness enrolled")
    _check(mutations.enroll_virgin_item("item.milk.a", 0), "milk virgin freshness enrolled")
    _check(not mutations.enroll_virgin_item("item.can.a", 0), "shelf-stable item does not get freshness record")
    _check(state.item_ids() == ["item.apple.a", "item.milk.a"], "freshness state is sparse and sorted")

    var apple_profile: ItemFreshnessProfile = catalog.profile(&"item.food.apple")
    var apple_zero: Dictionary = query.query_at_tick("item.apple.a", 0)
    var apple_late: Dictionary = query.query_at_tick("item.apple.a", apple_profile.ambient_lifetime_ticks)
    _check(int(apple_zero.get("status", -1)) == FreshQueryClass.Status.KNOWN, "perishable query known")
    _check(int(apple_zero.get("age_permille", -1)) >= 0 and int(apple_zero.get("age_permille", -1)) <= 200, "deterministic virgin age bounded to 20 percent")
    _check(StringName(apple_late.get("stage", &"")) == FreshQueryClass.SPOILED, "one ambient lifetime guarantees spoiled")
    _check(int(query.query_at_tick("item.can.a", 999999).get("status", -1)) == FreshQueryClass.Status.SHELF_STABLE, "shelf stable query requires no record")

    var state_revision_before_time: int = state.revision()
    query.query_at_tick("item.apple.a", apple_profile.ambient_lifetime_ticks * 20)
    _check(state.revision() == state_revision_before_time, "time passage/query performs zero freshness mutation")

    var late_world := WorldStateClass.new()
    var late_wm := WorldMutationClass.new(late_world)
    var late_state := FreshStateClass.new()
    var late_mutations := FreshMutationClass.new(late_world, late_state, catalog, providers)
    var late_query := FreshQueryClass.new(late_world, late_state, catalog, kernel, providers)
    _check(late_wm.create_entity(&"item.food.milk_carton", "item.milk.day5") == "item.milk.day5", "late materialized milk created")
    _check(late_mutations.enroll_virgin_item("item.milk.day5", 0), "late materialized virgin item anchors to logical tick zero")
    var day_five_tick: int = time_profile.ticks_per_day() * 5
    _check(StringName(late_query.query_at_tick("item.milk.day5", day_five_tick).get("stage", &"")) == FreshQueryClass.SPOILED, "day-five first materialization does not create fresh milk")

    var snapshot: Dictionary = state.snapshot()
    var restored := FreshStateClass.new()
    _check(restored.load_snapshot(snapshot), "freshness snapshot restores")
    _check(restored.snapshot() == snapshot, "freshness snapshot round-trips deterministically")
    var bad: Dictionary = snapshot.duplicate(true)
    bad["schema_version"] = 999
    _check(not restored.load_snapshot(bad), "wrong snapshot schema rejected")

    _check(String(FreshQueryClass._stage(599)) == "FRESH", "fresh threshold below 60 percent")
    _check(String(FreshQueryClass._stage(600)) == "AGING", "aging starts at 60 percent")
    _check(String(FreshQueryClass._stage(850)) == "STALE", "stale starts at 85 percent")
    _check(String(FreshQueryClass._stage(1000)) == "SPOILED", "spoiled starts at 100 percent")

func _check(condition: bool, message: String) -> void:
    if not condition:
        failures.append(message)
