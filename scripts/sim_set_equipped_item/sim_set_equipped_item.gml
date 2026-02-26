function sim_set_equipped_item(p, slot, item) {
    // Ensure equip struct exists (prevents draw-time crashes on legacy party members)
    if (!variable_struct_exists(p, "equip") || !is_struct(p.equip)) {
        p.equip = {
            weapon: undefined,
            armor: undefined,
            trinket: undefined
        };
    }

    switch (slot) {
        case "weapon":  p.equip.weapon  = item; break;
        case "armor":   p.equip.armor   = item; break;
        case "trinket": p.equip.trinket = item; break;
    }

    // Compatibility: also keep string-ish fields updated for any legacy UI/log code.
    // (Safe even if nothing uses them.)
    p.weapon  = sim_item_name(p.equip.weapon);
    p.armor   = sim_item_name(p.equip.armor);
    p.trinket = sim_item_name(p.equip.trinket);
}
