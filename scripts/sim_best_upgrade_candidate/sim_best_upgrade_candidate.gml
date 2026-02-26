function sim_best_upgrade_candidate(sim, new_item) {
    var slot = sim_item_slot_from_type(new_item.type);
    if (slot == "") return { idx: -1, delta: -999999, slot: "" };

    var best_idx = 0;
    var best_delta = -999999;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        var d = sim_item_upgrade_delta(p, slot, new_item);
        if (d > best_delta) {
            best_delta = d;
            best_idx = i;
        }
    }

    return { idx: best_idx, delta: best_delta, slot: slot };
}