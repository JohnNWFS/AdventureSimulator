function sim_set_equipped_item(p, slot, item) {
    switch (slot) {
        case "weapon": p.equip.weapon = item; break;
        case "armor":  p.equip.armor  = item; break;
        case "trinket": p.equip.trinket = item; break;
    }
}