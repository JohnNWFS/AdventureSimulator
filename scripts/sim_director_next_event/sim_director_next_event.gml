function sim_director_recent_count(sim, ev_name, window) {
    if (!is_array(sim.recent_beats)) return 0;

    var count = 0;
    var start = max(0, array_length(sim.recent_beats) - window);
    for (var i = start; i < array_length(sim.recent_beats); i++) {
        if (sim.recent_beats[i] == ev_name) count += 1;
    }
    return count;
}

function sim_director_schedule_from_zone_profile(sim, route_mod) {
    var profile = sim_get_zone_profile(sim);
    if (!is_struct(profile) || !variable_struct_exists(profile, "beat_weights")) return "";

    var weights = profile.beat_weights;
    var options = [];

    var encounter_scalar = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "encounter_rate_scalar")) ? global.tuning.encounter_rate_scalar : 1.0;
    var merchant_cap = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "merchants_per_zone_cap")) ? floor(global.tuning.merchants_per_zone_cap) : 2;
    var merchant_chance_base = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "merchant_chance_base")) ? global.tuning.merchant_chance_base : 13;
    var chest_chance_base = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "chest_chance_base")) ? global.tuning.chest_chance_base : 12;

    var merchant_freq_mult = clamp(merchant_chance_base / 13, 0.15, 3.0);
    var exploration_freq_mult = clamp(chest_chance_base / 12, 0.15, 3.0);

    var combat_w = variable_struct_exists(weights, "combat") ? variable_struct_get(weights, "combat") : 0;
    if (combat_w > 0) array_push(options, { w: max(1, round(combat_w * encounter_scalar * encounter_scalar)), v: "combat" });

    var exploration_w = variable_struct_exists(weights, "exploration") ? variable_struct_get(weights, "exploration") : 0;
    if (exploration_w > 0) array_push(options, { w: max(1, round(exploration_w * route_mod.loot_mult * exploration_freq_mult)), v: "exploration" });

    var merchant_w = variable_struct_exists(weights, "merchant") ? variable_struct_get(weights, "merchant") : 0;
    if (merchant_w > 0 && sim.director.merchant_cd == 0 && sim.director.merchants_this_zone < merchant_cap) {
        array_push(options, { w: max(1, round(merchant_w * route_mod.loot_mult * merchant_freq_mult)), v: "merchant" });
    }

    var social_w = variable_struct_exists(weights, "social") ? variable_struct_get(weights, "social") : 0;
    if (social_w > 0) array_push(options, { w: floor(social_w * route_mod.social_mult), v: "social" });

    var hazard_w = variable_struct_exists(weights, "hazard") ? variable_struct_get(weights, "hazard") : 0;
    if (hazard_w > 0) array_push(options, { w: floor(hazard_w * route_mod.hazard_mult), v: "hazard" });

    var relief_w = variable_struct_exists(weights, "relief") ? variable_struct_get(weights, "relief") : 0;
    if (relief_w > 0) array_push(options, { w: floor(relief_w * route_mod.relief_mult), v: "relief" });

    if (array_length(options) <= 0) return "";

    var pick = loot_pick_weighted(sim, options);
    if (pick == "merchant") return "merchant";
    if (pick == "relief") return "relief";
    if (pick == "combat") return "combat";

    if (pick == "exploration" || pick == "social" || pick == "hazard") {
        sim.director.adventure_focus = pick;
        return "adventure";
    }

    return "";
}

function sim_director_next_event(sim) {
    // Big beats
    if (sim.beat == 0) return "intro";
    var threshold_shift = variable_struct_exists(sim, "city_tension_threshold_shift") ? sim.city_tension_threshold_shift : 0;
    var effective_threshold = max(10, sim.tension_threshold + threshold_shift);
    if (!sim.flags.boss_begun && sim.tension_current >= effective_threshold) return "boss";

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
        if (!variable_struct_exists(sim, "city_phase_executed") || !sim.city_phase_executed) return "city_scene";
        sim.city_scene_pending = false;
    }

    if (variable_struct_exists(sim, "city_ambush_bonus_next") && sim.city_ambush_bonus_next > 0 && sim_chance(sim, 20 * sim.city_ambush_bonus_next)) {
        sim.city_ambush_bonus_next = max(0, sim.city_ambush_bonus_next - 1);
        sim_log_tag(sim, "CITY_EFFECT_APPLIED", "🕶 Rival pressure triggers an ambush beat.");
        return "combat";
    }

    var recent_len = is_array(sim.recent_beats) ? array_length(sim.recent_beats) : 0;
    var last_ev = (recent_len > 0) ? sim.recent_beats[recent_len - 1] : "";
    var prev_ev = (recent_len > 1) ? sim.recent_beats[recent_len - 2] : "";
    var last_two_merchant = (last_ev == "merchant" && prev_ev == "merchant");
    var last_two_combat = (last_ev == "combat" && prev_ev == "combat");

    var boss_lead_in_active = false;
    if (is_struct(sim.director) && variable_struct_exists(sim.director, "boss_lead_in_active")) {
        boss_lead_in_active = sim.director.boss_lead_in_active;
    }

    var avg_hp_pct = sim_party_avg_hp_pct(sim);
    var worst_hp_pct = 1.0;
    var wounded_members = 0;

    for (var i = 0; i < array_length(sim.party); i++) {
        var p = sim.party[i];
        if (!sim_party_is_active(p)) continue;

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

    var scheduled = sim_director_schedule_from_zone_profile(sim, route_mod);
    if (scheduled == "merchant" && last_two_merchant) {
        sim.director.repeat_prevented += 1;
        sim.director.adventure_focus = "exploration";
        sim_log_tag(sim, "DIRECTOR_REROUTE", "🧠 reason=merchant_recent_repeat from=merchant to=adventure");
        return "adventure";
    }
    if (scheduled != "") return scheduled;

    // Fallback pacing for zones without beat_weights configured.
    var merchant_chance_base = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "merchant_chance_base")) ? global.tuning.merchant_chance_base : 13;
    var chest_chance_base = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "chest_chance_base")) ? global.tuning.chest_chance_base : 12;
    var merchant_cd_turns = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "merchant_cd_turns")) ? floor(global.tuning.merchant_cd_turns) : 3;
    var chest_cd_turns = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "chest_cd_turns")) ? floor(global.tuning.chest_cd_turns) : 4;
    var merchants_per_zone_cap = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "merchants_per_zone_cap")) ? floor(global.tuning.merchants_per_zone_cap) : 2;
    var encounter_rate_scalar = (variable_global_exists("tuning") && is_struct(global.tuning) && variable_struct_exists(global.tuning, "encounter_rate_scalar")) ? global.tuning.encounter_rate_scalar : 1.0;

    if (sim.director.merchant_cd == 0 && sim.director.merchants_this_zone < merchants_per_zone_cap && sim_chance(sim, floor(merchant_chance_base * route_mod.loot_mult))) {
        sim.director.merchant_cd = merchant_cd_turns;
        return "merchant";
    }
    if (sim.director.chest_cd == 0 && sim_chance(sim, floor(chest_chance_base * route_mod.loot_mult))) {
        sim.director.chest_cd = chest_cd_turns;
        return "chest";
    }
    if (sim.director.adventure_cd == 0) {
        var adv_pressure = floor((28 / max(0.25, encounter_rate_scalar)) * route_mod.social_mult);
        if (sim_chance(sim, adv_pressure)) {
            return "adventure";
        }
    }

    // Combat pressure reacts to route modifiers and repeat suppression.
    var repeat_combat = sim_director_recent_count(sim, "combat", sim.director.repeat_window);
    if (repeat_combat >= 4 && sim_chance(sim, 65)) {
        return "adventure";
    }

    if (last_two_combat && !boss_lead_in_active) {
        sim.director.repeat_prevented += 1;

        var reroute_combat = "relief";
        if (sim.director.adventure_cd == 0 && sim_chance(sim, 65)) {
            sim.director.adventure_cd = 1;
            reroute_combat = "adventure";
        } else if (sim.director.chest_cd == 0 && sim_chance(sim, floor(70 * route_mod.loot_mult))) {
            sim.director.chest_cd = chest_cd_turns;
            reroute_combat = "chest";
        } else if (sim.director.beats_since_relief < relief_gap) {
            if (sim.director.adventure_cd == 0) {
                sim.director.adventure_cd = 1;
                reroute_combat = "adventure";
            } else if (sim.director.chest_cd == 0) {
                sim.director.chest_cd = chest_cd_turns;
                reroute_combat = "chest";
            }
        }

        sim_log_tag(sim, "DIRECTOR_REROUTE", "🧠 reason=combat_recent_repeat from=combat to=" + reroute_combat);
        return reroute_combat;
    }

    // Default fallback reacts strongly to encounter tuning.
    var default_combat_chance = clamp(round(55 * encounter_rate_scalar), 15, 95);
    if (sim_chance(sim, default_combat_chance)) return "combat";
    return "adventure";
}
