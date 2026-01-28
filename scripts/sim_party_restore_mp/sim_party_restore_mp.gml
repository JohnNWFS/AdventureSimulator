
function sim_party_restore_mp(sim, amount) {
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        p.mp = min(p.max_mp, p.mp + amount);
    }
    sim_log(sim, "🔷 Party restores MP +" + string(amount) + " (group).");
}

