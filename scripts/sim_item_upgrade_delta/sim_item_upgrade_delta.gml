function sim_item_upgrade_delta(p, slot, new_item) {
    var old_item = sim_get_equipped_item(p, slot);
    if (!is_struct(old_item)) return sim_role_weighted_power(p, new_item);

    var new_score = sim_role_weighted_power(p, new_item);
    var old_score = sim_role_weighted_power(p, old_item);

    return (new_score - old_score);
}