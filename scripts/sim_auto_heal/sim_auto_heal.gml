function sim_auto_heal(sim) {
    var healer = sim.party[3];
    if (healer.mp < 3) return;

    var best_i = -1;
    var best_pct = 999;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        if (p.dead || p.retired) continue;

        var pct = p.hp / max(1, p.max_hp);
        if (pct < best_pct) {
            best_pct = pct;
            best_i = i;
        }
    }

    if (best_i != -1 && best_pct < 0.90) {
        var target = sim.party[best_i];

        var heal_raw  = sim_rand_range(sim, 8, 18) + sim.difficulty * 2;
        if (variable_global_exists("balance") && is_struct(global.balance) && variable_struct_exists(global.balance, "heal_scalar")) {
            heal_raw = floor(heal_raw * global.balance.heal_scalar);
        }
        heal_raw = max(1, heal_raw);
        var before_hp = target.hp;

        if (target.status_state == "downed") {
            target.hp = max(2, min(target.max_hp, heal_raw));
            target.status_state = "alive";
        } else {
            target.hp = min(target.max_hp, target.hp + heal_raw);
        }
        healer.mp -= 3;

        var healed_amt = target.hp - before_hp;

        sim_log_tag(sim, "HEAL",
            "🩹 Healer restores " + target.name + " +" + string(healed_amt) +
            " HP (" + string(before_hp) + "→" + string(target.hp) + ")."
        );
    }
} // sim_auto_heal
