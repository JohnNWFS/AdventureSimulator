function sim_resolve_merchant(sim) {
    // --- Harden stats (prevents "field not set" crashes) ---
    if (!is_struct(sim.stats)) sim.stats = {};
    if (!variable_struct_exists(sim.stats, "merchants_seen")) sim.stats.merchants_seen = 0;

    // Generate a merchant item
    var tier_target = clamp(2 + floor(sim.difficulty / 2), 1, 10);
    var offer = loot_generate_item(sim, { source: "merchant", zone: sim.zone, tier_target: tier_target });

    // If merchant rolled treasure, reroll once (merchant should feel like "gear + tools", not pure treasure)
    if (is_struct(offer) && variable_struct_exists(offer, "type") && offer.type == "treasure") {
        offer = loot_generate_item(sim, { source: "merchant", zone: sim.zone, tier_target: tier_target });
    }

    // Compute buy cost
    var cost = (is_struct(offer) && variable_struct_exists(offer, "buy_price"))
        ? offer.buy_price
        : max(10, floor(offer.value * 1.10));

    // Determine equip slot if this is gear
    var slot = sim_item_slot_from_type(offer.type);

    // Default buyer (in case non-gear)
    var buyer_idx = sim_rand_range(sim, 0, array_length(sim.party) - 1);
    var delta = 0;

    // --- If gear: pick best recipient and decide whether it's worth buying ---
    if (slot != "") {
        var pick = sim_find_best_recipient(sim, offer, slot);
        buyer_idx = pick.idx;
        delta = pick.delta;

        // If nobody can reasonably use it (or recipient invalid), skip
        if (buyer_idx < 0 || buyer_idx >= array_length(sim.party)) {
            sim_log_tag(sim, "MERCHANT_SKIP",
                "🧳 Merchant: party ignores " + offer.name + " (" + string(cost) + "g) [no valid recipient]."
            );
            return; // NOTE: sim_run_step will process exits after this beat
        }

        // Threshold: below this, upgrades feel like noise
        var THRESH = 2.5;
        if (delta < THRESH) {
            sim_log_tag(sim, "MERCHANT_SKIP",
                "🧳 Merchant: party passes on " + offer.name + " (" + string(cost) + "g) [no upgrades]."
            );
            return;
        }
    }

    // Can't afford
    if (sim.gold_total < cost) {
        sim_log_tag(sim, "MERCHANT_SKIP",
            "🧳 Merchant: party browses, can't afford " + offer.name + " (" + string(cost) + "g)."
        );
        return;
    }

    // Buy it
    var buyer = sim.party[buyer_idx];
    var gold_before = sim.gold_total;

    sim.gold_total -= cost;
    sim.stats.merchants_seen += 1;

    sim_log_tag(sim, "MERCHANT_BUY",
        "🧳 Merchant: " + buyer.name + " buys " + offer.name +
        " for " + string(cost) + " gold (" +
        string(gold_before) + "→" + string(sim.gold_total) + ")."
    );

    // --- Gear: equip immediately and log deltas ---
    if (slot != "") {
        var p = sim.party[buyer_idx];

        // If the selected recipient is somehow dead/retired, don't crash; just skip equip.
        if ((variable_struct_exists(p, "dead") && p.dead) || (variable_struct_exists(p, "retired") && p.retired)) {
            sim_log_tag(sim, "MERCHANT_SKIP",
                "🧳 Merchant: the intended buyer is unavailable. The party moves on."
            );
            return;
        }

        // Ensure equip/base fields exist before touching gear
        sim_recalc_derived(p);

        var before_atk    = p.atk;
        var before_def    = p.def;
        var before_max_hp = p.max_hp;
        var before_max_mp = p.max_mp;

        sim_set_equipped_item(p, slot, offer);
        sim_recalc_derived(p);

        sim_log_tag(sim, "EQUIP",
            "📦 EQUIP → " + p.name + " equips (" + slot + "): " + offer.name +
            " [Δ" + string_format(delta, 1, 1) + "]."
        );

        if (p.atk != before_atk) {
            sim_log_tag(sim, "STAT_ATK", "🟩 ATK " + string(before_atk) + "→" + string(p.atk) + ".");
        }
        if (p.def != before_def) {
            sim_log_tag(sim, "STAT_DEF", "🟦 DEF " + string(before_def) + "→" + string(p.def) + ".");
        }
        if (p.max_hp != before_max_hp) {
            sim_log_tag(sim, "STAT_HP", "❤️ MAX HP " + string(before_max_hp) + "→" + string(p.max_hp) + ".");
        }
        if (p.max_mp != before_max_mp) {
            sim_log_tag(sim, "STAT_MP", "🔷 MAX MP " + string(before_max_mp) + "→" + string(p.max_mp) + ".");
        }

        return; // NOTE: sim_run_step will process exits after this beat
    }

    // --- Non-gear: use existing pipeline ---
    sim_give_item(sim, offer);

    // NOTE: no sim_party_process_exits() here; sim_run_step handles it once per beat
}
