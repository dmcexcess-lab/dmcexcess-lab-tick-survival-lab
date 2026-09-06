extends RefCounted
class_name VehicleItemCatalog

const SKATEBOARD := &"item.vehicle.skateboard"
const GAS_CAN := &"item.automotive.gas_can"
const CARGO_RACK := &"item.automotive.cargo_rack"
const BATTERY := &"item.automotive.car_battery"
const SPARE_WHEEL := &"item.automotive.spare_wheel"

const _WEIGHTS := {
    "item.vehicle.skateboard": 2500,
    "item.automotive.gas_can": 4200,
    "item.automotive.cargo_rack": 6500,
    "item.automotive.car_battery": 16000,
    "item.automotive.spare_wheel": 11000,
}

static func semantic_types() -> Array[StringName]:
    return [SKATEBOARD, GAS_CAN, CARGO_RACK, BATTERY, SPARE_WHEEL]

static func weight_grams(semantic: StringName) -> int:
    return int(_WEIGHTS.get(String(semantic), -1))

static func register_physical_profiles(catalog: ItemPhysicalPropertyCatalog) -> bool:
    if catalog == null:
        return false
    for semantic: StringName in semantic_types():
        var grams := weight_grams(semantic)
        if grams <= 0:
            return false
        if catalog.has_profile(semantic):
            if catalog.weight_grams(semantic) != grams:
                return false
        elif not catalog.register_profile(semantic, grams):
            return false
    return true
