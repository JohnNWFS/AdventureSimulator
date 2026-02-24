function sim_party_avg_hp_pct(sim) {
    var total = 0;
    var count = 0;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (!sim_party_is_active(p)) continue;

        total += (p.hp / max(1, p.max_hp));
        count += 1;
    }

    if (count <= 0) return 0;
    return total / count;
}
