function sim_party_heal(sim, amount) {
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        p.hp = min(p.max_hp, p.hp + amount);
    }
    sim_log(sim, "✨ Party heals +" + string(amount) + " (group).");
}
