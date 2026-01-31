function sim_get_equipped_item(p, slot) {
    if (!is_struct(p.equip)) return undefined;
    switch (slot) {
        case "weapon": return p.equip.weapon;
        case "armor":  return p.equip.armor;
        case "trinket": return p.equip.trinket;
    }
    return undefined;
}