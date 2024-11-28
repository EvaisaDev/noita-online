local helpers = {
    RAGDOLL_FX = {
        NONE = 0x0,
        NORMAL = 0x1,
        BLOOD_EXPLOSION = 0x2,
        BLOOD_SPRAY = 0x3,
        FROZEN = 0x4,
        CONVERT_TO_MATERIAL = 0x5,
        CUSTOM_RAGDOLL_ENTITY = 0x6,
        DISINTEGRATED = 0x7,
        NO_RAGDOLL_FILE = 0x8,
        PLAYER_RAGDOLL_CAMERA = 0x9,
    },
    DAMAGE_TYPES = {
        DAMAGE_MELEE = 0x1,
        DAMAGE_PROJECTILE = 0x2,
        DAMAGE_EXPLOSION = 0x4,
        DAMAGE_BITE = 0x8,
        DAMAGE_FIRE = 0x10,
        DAMAGE_MATERIAL = 0x20,
        DAMAGE_FALL = 0x40,
        DAMAGE_ELECTRICITY = 0x80,
        DAMAGE_DROWNING = 0x100,
        DAMAGE_PHYSICS_BODY_DAMAGED = 0x200,
        DAMAGE_DRILL = 0x400,
        DAMAGE_SLICE = 0x800,
        DAMAGE_ICE = 0x1000,
        DAMAGE_HEALING = 0x2000,
        DAMAGE_PHYSICS_HIT = 0x4000,
        DAMAGE_RADIOACTIVE = 0x8000,
        DAMAGE_POISON = 0x10000,
        DAMAGE_MATERIAL_WITH_FLASH = 0x20000,
        DAMAGE_OVEREATING = 0x40000,
        DAMAGE_CURSE = 0x80000,
        DAMAGE_HOLY = 0x100000
    }
}


helpers.GetDamageTypes = function(bit_flag)
    local damage_types = {}


    for damage_type_name, damage_type_value in pairs(helpers.DAMAGE_TYPES) do
        if bit.band(bit_flag, damage_type_value) == damage_type_value then
            table.insert(damage_types, damage_type_name)
        end
    end

    return damage_types
end

helpers.GetRagdollFX = function(index)
    for ragdoll_fx_name, ragdoll_fx_value in pairs(helpers.RAGDOLL_FX) do
        if ragdoll_fx_value == index then
            return ragdoll_fx_name
        end
    end
end

return helpers