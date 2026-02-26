function sim_item_slot_from_type(item_type) {
    switch (item_type) {
        case "weapon":  return "weapon";
        case "armor":   return "armor";
        case "trinket": return "trinket";
    }
    return "";
}