function sim_get_equipped_item(p, slot) {
    // If equip doesn't exist yet (legacy party members), treat as empty
    if (!variable_struct_exists(p, "equip") || !is_struct(p.equip)) {
        return undefined;
    }

    switch (slot) {
        case "weapon":  return p.equip.weapon;
        case "armor":   return p.equip.armor;
        case "trinket": return p.equip.trinket;
    }

    return undefined;
}
