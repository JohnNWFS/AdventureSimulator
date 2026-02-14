function sim_director_recent_count(sim, ev_name, window) {
    if (!is_array(sim.recent_beats)) return 0;

    var count = 0;
    var start = max(0, array_length(sim.recent_beats) - window);
    for (var i = start; i < array_length(sim.recent_beats); i++) {
        if (sim.recent_beats[i] == ev_name) count += 1;
    }
    return count;
}

function sim_director_next_event(sim) {
    // Big beats
    if (sim.beat == 0) return "intro";
    if (sim.beat >= sim.beats_target - 1) return "boss";

    if (!variable_struct_exists(sim.director, "beats_since_relief")) {
        sim.director.beats_since_relief = 0;
    }

    var route_mod = sim.director.route_mod;
    if (!is_struct(route_mod)) {
        route_mod = { ambush_mult: 1.0, loot_mult: 1.0, hazard_mult: 1.0, social_mult: 1.0, relief_mult: 1.0, risk_mult: 1.0, ttl: 0, label: "" };
    }

    // Short-run coverage guarantees for quick validation.
    if (variable_struct_exists(sim, "debug_very_short_mode") && sim.debug_very_short_mode) {
        if (sim.coverage.combat == 0 && sim.beat >= 1) return "combat";
        if (sim.coverage.exploration == 0 && sim.beat >= 3) return "adventure";
        if (sim.coverage.merchant == 0 && sim.beat >= 5) return "merchant";
        if (sim.coverage.relief == 0 && sim.beat >= 7) return "relief";
        if (sim.coverage.retreat == 0 && sim.beat >= 9) return "retreat_bridge";
    } else if (variable_struct_exists(sim, "debug_short_mode") && sim.debug_short_mode) {
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

    var emergency = (worst_hp_pct <= 0.12 || avg_hp_pct < 0.30 || sim.retreat_to_city);
    var relief_gap = sim.director.relief_min_gap;
    var relief_max_gap = sim.director.relief_max_gap;

    // Guaranteed relief cadence with spacing.
    if (sim.director.beats_since_relief >= relief_max_gap) {
        return "relief";
    }

    var relief_ready = (sim.director.beats_since_relief >= relief_gap);
    if (!relief_ready && !emergency && sim_chance(sim, 15)) {
        sim.director.repeat_prevented += 1;
    }

    if (relief_ready && (worst_hp_pct <= 0.16 || avg_hp_pct < 0.38 || sim.tension > 82)) {
        return "relief";
    }

    if (relief_ready && wounded_members > 0 && sim.director.beats_since_relief >= (relief_gap + 1) && sim_chance(sim, 50)) {
        return "relief";
    }

    // Merchant: respect cooldown and per-zone cap.
    if (sim.director.merchant_cd == 0 && sim.director.merchants_this_zone < 2 && sim_chance(sim, floor(13 * route_mod.loot_mult))) {
        return "merchant";
    }

    // Chest: respect cooldown.
    if (sim.director.chest_cd == 0 && sim_chance(sim, floor(12 * route_mod.loot_mult))) {
        sim.director.chest_cd = 4;
        return "chest";
    }

    // Adventure beats actively compete with combat.
    if (sim.director.adventure_cd == 0) {
        var adv_pressure = 34;
        if (sim.tension > 70) adv_pressure += 10;
        if (sim.zone == "Wilderness" || sim.zone == "Dungeon") adv_pressure += 8;
        adv_pressure = floor(adv_pressure * route_mod.social_mult);

        if (sim_chance(sim, adv_pressure)) {
            sim.director.adventure_cd = 1;
            return "adventure";
        }
    }

    // Combat pressure reacts to route modifiers and repeat suppression.
    var repeat_combat = sim_director_recent_count(sim, "combat", sim.director.repeat_window);
    if (repeat_combat >= 4 && sim_chance(sim, 65)) {
        return "adventure";
    }

    // Default
    return "combat";
}
