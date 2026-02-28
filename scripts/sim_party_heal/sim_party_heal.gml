function sim_party_heal(sim, amount) {
    if (variable_global_exists("balance") && is_struct(global.balance) && variable_struct_exists(global.balance, "heal_scalar")) {
        amount = floor(amount * global.balance.heal_scalar);
    }
    amount = max(1, amount);
    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        p.hp = min(p.max_hp, p.hp + amount);
    }
    sim_log(sim, "✨ Party heals +" + string(amount) + " (group).");
}
