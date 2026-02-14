function sim_director_next_event(sim) {
    // Big beats
    if (sim.beat == 0) return "intro";
    if (sim.beat >= sim.beats_target - 1) return "boss";

    if (!variable_struct_exists(sim.director, "beats_since_relief")) {
        sim.director.beats_since_relief = 0;
    }

    // Short-run coverage guarantees for quick validation.
    if (variable_struct_exists(sim, "debug_short_mode") && sim.debug_short_mode) {
        if (sim.coverage.combat == 0 && sim.beat >= 2) return "combat";
        if (sim.coverage.exploration == 0 && sim.beat >= 3) return "adventure";
        if (sim.coverage.merchant == 0 && sim.beat >= 5) return "merchant";
        if (sim.coverage.relief == 0 && sim.beat >= 7) return "relief";
    }

    // Retreat flow: bridge beats -> city scene -> relief beats.
    if (sim.retreat_to_city) {
        if (sim.director.retreat_bridge_left > 0) {
            sim.city_scene_pending = false;
            sim.director.retreat_bridge_left -= 1;
            return "retreat_bridge";
        }

        if (!sim.city_scene_played) {
            sim.city_scene_pending = true;
            return "city_scene";
        }

        if (sim.retreat_beats_left > 0) {
            sim.retreat_beats_left -= 1;
            return "relief";
        }

        sim.retreat_to_city = false;
    }

    if (sim.city_scene_pending) {
        return "city_scene";
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

    // Guaranteed relief cadence with spacing.
    if (sim.director.beats_since_relief >= 9) {
        return "relief";
    }

    var relief_ready = (sim.director.beats_since_relief >= 4);

    // Recovery pressure checks: worst member matters, not just average.
    if (relief_ready && (worst_hp_pct <= 0.16 || avg_hp_pct < 0.38 || sim.tension > 82)) {
        return "relief";
    }

    // If wounds are building, push relief opportunities with spacing.
    if (relief_ready && wounded_members > 0 && sim.director.beats_since_relief >= 5 && sim_chance(sim, 50)) {
        return "relief";
    }

    // Merchant: respect cooldown and per-zone cap.
    if (sim.director.merchant_cd == 0 && sim.director.merchants_this_zone < 2 && sim_chance(sim, 13)) {
        return "merchant";
    }

    // Chest: respect cooldown.
    if (sim.director.chest_cd == 0 && sim_chance(sim, 12)) {
        sim.director.chest_cd = 4;
        return "chest";
    }

    // Adventure beats actively compete with combat.
    if (sim.director.adventure_cd == 0) {
        var adv_pressure = 34;
        if (sim.tension > 70) adv_pressure += 10;
        if (sim.zone == "Wilderness" || sim.zone == "Dungeon") adv_pressure += 8;

        if (sim_chance(sim, adv_pressure)) {
            sim.director.adventure_cd = 1;
            return "adventure";
        }
    }

    // Default
    return "combat";
}
