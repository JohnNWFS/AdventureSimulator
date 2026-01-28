function sim_party_avg_hp_pct(sim) {
    var total = 0;
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        total += (p.hp / p.max_hp);
    }
    return total / array_length(sim.party);
}



