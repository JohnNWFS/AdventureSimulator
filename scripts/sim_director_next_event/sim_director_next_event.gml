function sim_director_next_event(sim) {
    // Big beats
    if (sim.beat == 0) return "intro";
    if (sim.beat >= sim.beats_target - 1) return "boss";

    if (!variable_struct_exists(sim.director, "beats_since_relief")) {
        sim.director.beats_since_relief = 0;
    }

    if (sim.city_scene_pending) {
        return "city_scene";
    }

    // Retreat flow: only relief + city scene + eventual boss cap
    if (sim.retreat_to_city) {
        if (!sim.city_scene_played) {
            sim.city_scene_pending = true;
            return "city_scene";
        }

        if (sim.retreat_beats_left > 0) {
            sim.retreat_beats_left -= 1;
            return "relief";
        }

        return "boss";
    }

    var avg_hp_pct = sim_party_avg_hp_pct(sim);
    var worst_hp_pct = 1.0;
    var wounded_members = 0;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (p.dead || p.retired) continue;

        var pct = p.hp / max(1, p.max_hp);
        if (pct < worst_hp_pct) worst_hp_pct = pct;
        if (p.wounds >= 2) wounded_members += 1;
    }

    // Guaranteed relief cadence to avoid gauntlets
    if (sim.director.beats_since_relief >= 7) {
        return "relief";
    }

    // Recovery pressure checks: worst member matters, not just average
    if (worst_hp_pct <= 0.20 || avg_hp_pct < 0.45 || sim.tension > 75) {
        return "relief";
    }

    // If wounds are building, push more relief opportunities
    if (wounded_members > 0 && sim.director.beats_since_relief >= 3 && sim_chance(sim, 60)) {
        return "relief";
    }

    // Merchant: respect cooldown and per-zone cap
    if (sim.director.merchant_cd == 0 && sim.director.merchants_this_zone < 2 && sim_chance(sim, 12)) {
        return "merchant";
    }

    // Chest: respect cooldown
    if (sim.director.chest_cd == 0 && sim_chance(sim, 16)) {
        sim.director.chest_cd = 4;
        return "chest";
    }

    // Default
    return "combat";
}
