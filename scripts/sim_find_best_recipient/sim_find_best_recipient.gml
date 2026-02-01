function sim_find_best_recipient(sim, item, slot) {
    var best_idx = 0;
    var best_delta = -999999;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        var d = sim_upgrade_delta(p, slot, item);
        if (d > best_delta) {
            best_delta = d;
            best_idx = i;
        }
    }

    return { idx: best_idx, delta: best_delta };
}