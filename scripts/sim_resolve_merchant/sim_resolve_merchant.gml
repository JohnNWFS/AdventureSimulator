function sim_resolve_merchant(sim) {
    var outcome_emitted = false;

    if (!is_struct(sim.stats)) sim.stats = {};
    if (!variable_struct_exists(sim.stats, "merchants_seen")) sim.stats.merchants_seen = 0;
    if (!variable_struct_exists(sim.stats, "merchants_bought")) sim.stats.merchants_bought = 0;

    var recent_merchants = sim_director_recent_count(sim, "merchant", 3);
    if (recent_merchants > 0) {
        sim.director.repeat_prevented += 1;
        var alt = sim_rand_range(sim, 0, 2);
        if (alt == 0) {
            sim_log_tag(sim, "SCAVENGER", "🛞 A broken merchant cart is picked clean for scraps.");
            sim.gold_total += sim_rand_range(sim, 3, 8);
        } else if (alt == 1) {
            sim_log_tag(sim, "SCAVENGER", "🧿 A scavenger offers rumor and salvage instead of trade.");
            sim.tension = clamp(sim.tension - 4, 0, 100);
        } else {
            sim_log_tag(sim, "SCAVENGER", "📦 An abandoned stash replaces a repeat merchant stop.");
            sim_give_item(sim, loot_generate_item(sim, { source: "merchant", zone: sim.zone, tier_target: max(1, floor(sim.difficulty / 2)) }));
        }
        if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_DECLINE", "🤝 They pass for now (reason=repeat_stop_replaced)."); outcome_emitted = true; }
        return;
    }

    sim.stats.merchants_seen += 1;
    sim.director.merchant_cd = 3;
    sim.director.merchants_this_zone += 1;

    var gold_band = clamp(floor(sim.gold_total / 30), 0, 5);
    var tier_target = clamp(1 + floor(sim.difficulty / 2) + floor(gold_band / 2), 1, 10);
    var offer = loot_generate_item(sim, { source: "merchant", zone: sim.zone, tier_target: tier_target });

    if (is_struct(offer) && variable_struct_exists(offer, "type") && offer.type == "treasure") {
        offer = loot_generate_item(sim, { source: "merchant", zone: sim.zone, tier_target: tier_target });
    }

    var list_price = (is_struct(offer) && variable_struct_exists(offer, "buy_price"))
        ? offer.buy_price
        : max(10, floor(offer.value * 1.10));

    var cost = list_price;
    if (sim.stats.merchants_bought == 0 && sim.gold_total > 0) {
        cost = min(cost, max(8, floor(sim.gold_total * 0.75)));
    }

    var slot = sim_item_slot_from_type(offer.type);
    var buyer_idx = sim_rand_range(sim, 0, array_length(sim.party) - 1);
    var delta = 0;

    if (slot != "") {
        var pick = sim_find_best_recipient(sim, offer, slot);
        buyer_idx = pick.idx;
        delta = pick.delta;

        if (buyer_idx < 0 || buyer_idx >= array_length(sim.party)) {
            if (!outcome_emitted) {
                sim_log_tag(sim, "MERCHANT_DECLINE",
                    "🧳 Decline: not useful right now (no valid recipient for " + offer.name + ")."
                );
                outcome_emitted = true;
            }
            return;
        }

        var THRESH = 2.0;
        if (delta < THRESH) {
            sim_log_tag(sim, "MERCHANT_OFFER",
                "🧳 Offer: " + offer.name + " for " + string(cost) + "g [minor upgrade]."
            );
            if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_DECLINE", "🧳 Decline: not useful enough; saving gold for a better find."); outcome_emitted = true; }
            return;
        }
    }

    sim_log_tag(sim, "MERCHANT_OFFER",
        "🧳 Offer: " + offer.name + " (" + string(list_price) + "g, asking " + string(cost) + "g)."
    );

    if (sim.gold_total < cost) {
        var drip = max(4, floor(list_price * 0.35));
        if (sim.gold_total >= drip) {
            sim.gold_total -= drip;
            sim.stats.merchants_bought += 1;
            if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_BUY", "🧳 The party scrapes together " + string(drip) + "g and buys " + offer.name + "."); outcome_emitted = true; }
            if (slot != "") {
                sim_set_equipped_item(sim.party[buyer_idx], slot, offer);
                sim_recalc_derived(sim.party[buyer_idx]);
            } else {
                sim_give_item(sim, offer);
            }
            return;
        }

        var fallback = sim_rand_range(sim, 0, 2);
        switch (fallback) {
            case 0:
                if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_REPAIR", "🛠 Repair instead of sale: too expensive at " + string(cost) + "g."); outcome_emitted = true; }
                sim_party_heal(sim, sim_rand_range(sim, 4, 8));
                break;
            case 1:
                if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_RUMOR", "🗣 Rumor instead of sale: too expensive at " + string(cost) + "g."); outcome_emitted = true; }
                sim.tension = clamp(sim.tension - 6, 0, 100);
                break;
            default:
                if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_DECLINE", "🧳 Decline: too expensive (" + string(cost) + "g), saving gold."); outcome_emitted = true; }
                break;
        }
        return;
    }

    var buyer = sim.party[buyer_idx];
    if (slot != "" && ((variable_struct_exists(buyer, "dead") && buyer.dead) || (variable_struct_exists(buyer, "retired") && buyer.retired))) {
        if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_DECLINE", "🧳 Decline: not useful right now (intended buyer unavailable)."); outcome_emitted = true; }
        return;
    }

    var gold_before = sim.gold_total;

    sim.gold_total -= cost;
    sim.stats.merchants_bought += 1;

    if (slot != "") {
        var p = sim.party[buyer_idx];
        sim_recalc_derived(p);

        sim_set_equipped_item(p, slot, offer);
        sim_recalc_derived(p);

        sim_log_tag(sim, "EQUIP_CHANGE",
            "📦 " + p.name + " equips " + offer.name + " (" + slot + ")."
        );

        if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_BUY", "🧳 " + buyer.name + " buys " + offer.name + "."); outcome_emitted = true; }
        return;
    }

    sim_give_item(sim, offer);

    if (!outcome_emitted) { sim_log_tag(sim, "MERCHANT_BUY", "🧳 " + buyer.name + " buys " + offer.name + "."); outcome_emitted = true; }
}
