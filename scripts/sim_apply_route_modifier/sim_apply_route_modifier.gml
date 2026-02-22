function sim_apply_route_modifier(sim, mode) {
    var ttl = sim_rand_range(sim, 1, 3);

    if (mode == "fast") {
        sim.director.route_mod = {
            ambush_mult: 1.45,
            loot_mult: 1.30,
            hazard_mult: 0.90,
            social_mult: 0.80,
            relief_mult: 0.75,
            risk_mult: 1.20,
            ttl: ttl,
            label: "fast ledge"
        };
    } else if (mode == "safe") {
        sim.director.route_mod = {
            ambush_mult: 0.75,
            loot_mult: 0.90,
            hazard_mult: 1.25,
            social_mult: 1.30,
            relief_mult: 1.15,
            risk_mult: 0.90,
            ttl: ttl,
            label: "safer tunnel"
        };
    } else {
        sim.director.route_mod = {
            ambush_mult: 0.70,
            loot_mult: 0.70,
            hazard_mult: 0.80,
            social_mult: 0.95,
            relief_mult: 1.20,
            risk_mult: 0.80,
            ttl: ttl,
            label: "backtrack"
        };
    }

    sim_log_tag(sim, "NAV_STATE",
        "🧭 Route modifier active: " + sim.director.route_mod.label +
        " for " + string(ttl) + " beats."
    );
}