function sim_party_heal(sim, amount) {
    var heal_scalar = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "heal_scalar")) ? global.tuning.heal_scalar : 1.0;
    amount = floor(amount * heal_scalar);
    amount = max(1, amount);
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        p.hp = min(p.max_hp, p.hp + amount);
    }
    sim_log(sim, "✨ Party heals +" + string(amount) + " (group).");
}
