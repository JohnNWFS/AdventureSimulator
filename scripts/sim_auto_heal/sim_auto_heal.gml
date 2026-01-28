function sim_auto_heal(sim) {
    var healer = sim.party[3];
    if (healer.mp < 3) return;

    var best_i = -1;
    var best_pct = 999;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];

        // Don't "heal through death" in the same beat
        if (p.downed_this_beat) continue;

        var pct = p.hp / p.max_hp;
        if (pct < best_pct) {
            best_pct = pct;
            best_i = i;
        }
    }

    if (best_i != -1 && best_pct < 0.85) {
        var target = sim.party[best_i];

        var heal_raw  = sim_rand_range(sim, 6, 14) + floor(sim.difficulty / 2);
        var before_hp = target.hp;

        target.hp = min(target.max_hp, target.hp + heal_raw);
        healer.mp -= 3;

        var healed_amt = target.hp - before_hp;

        sim_log_tag(sim, "HEAL",
            "🩹 Healer restores " + target.name + " +" + string(healed_amt) +
            " HP (" + string(before_hp) + "→" + string(target.hp) + ")."
        );
    }
}
