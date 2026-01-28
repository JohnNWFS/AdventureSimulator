function sim_resolve_merchant(sim) {
    var offer = choose("Health Tonic", "Armor Patch", "Spell Scroll", "Sharpening Stone");
    var cost  = sim_rand_range(sim, 20, 35);

    if (sim.gold_total < cost) {
        sim_log_tag(sim, "MERCHANT_SKIP",
            "🧿 Merchant: party browses, buys nothing."
        );
        return;
    }

    var buyer = sim.party[sim_rand_range(sim, 0, 3)];
    var gold_before = sim.gold_total;

    sim.gold_total -= cost;

    sim_log_tag(sim, "MERCHANT_BUY",
        "🧿 Merchant: " + buyer.name + " buys " + offer +
        " for " + string(cost) + " gold (" +
        string(gold_before) + "→" + string(sim.gold_total) + ")."
    );

    // Apply item
    switch (offer) {
        case "Health Tonic":
            sim_log_tag(sim, "ITEM_GAIN",
                "🧪 " + buyer.name + " acquires Health Tonic."
            );

            // OPTIONAL: immediate party heal (as in your log)
            var tonic_heal = sim_rand_range(sim, 8, 14);
            sim_log_tag(sim, "GROUP_HEAL",
                "✨ Health Tonic heals +" + string(tonic_heal) + " (group)."
            );

            for (var i = 0; i < array_length(sim.party); i++) {
                var p = sim.party[i];
                var before = p.hp;
                p.hp = min(p.max_hp, p.hp + tonic_heal);

                sim_log_tag(sim, "HP_DELTA",
                    "  ❤️ " + p.name + " HP " + string(before) + "→" + string(p.hp) + "."
                );
            }
            break;

        case "Armor Patch":
            sim.party[0].base_def += 1;
            sim.party[0].def = max(0, sim.party[0].base_def - sim.party[0].wounds);

            sim_log_tag(sim, "STAT_DEF",
                "🛡 " + sim.party[0].name + " DEF increases to " +
                string(sim.party[0].def) + "."
            );
            break;

        case "Spell Scroll":
            sim.party[1].atk += 1;
            sim_log_tag(sim, "STAT_ATK",
                "📜 " + sim.party[1].name + " ATK increases to " +
                string(sim.party[1].atk) + "."
            );
            break;

        case "Sharpening Stone":
            sim.party[2].atk += 1;
            sim_log_tag(sim, "STAT_ATK",
                "🗡 " + sim.party[2].name + " ATK increases to " +
                string(sim.party[2].atk) + "."
            );
            break;
    }
}
