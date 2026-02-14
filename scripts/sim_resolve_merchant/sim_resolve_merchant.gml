function sim_resolve_merchant(sim) {
    if (!is_struct(sim.stats)) sim.stats = {};
    if (!variable_struct_exists(sim.stats, "merchants_seen")) sim.stats.merchants_seen = 0;
    if (!variable_struct_exists(sim.stats, "merchants_bought")) sim.stats.merchants_bought = 0;

    sim.stats.merchants_seen += 1;
    sim.director.merchant_cd = 3;
    sim.director.merchants_this_zone += 1;

    var tier_target = clamp(2 + floor(sim.difficulty / 2), 1, 10);
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
            sim_log_tag(sim, "MERCHANT_SKIP",
                "🧳 Merchant packs up " + offer.name + " (" + string(cost) + "g): no valid recipient."
            );
            return;
        }

        var THRESH = 2.0;
        if (delta < THRESH) {
            sim_log_tag(sim, "MERCHANT_OFFER",
                "🧳 Offer: " + offer.name + " for " + string(cost) + "g [minor upgrade]."
            );
            sim_log_tag(sim, "MERCHANT_SKIP", "🧳 The party saves coin for a better find.");
            return;
        }
    }

    sim_log_tag(sim, "MERCHANT_OFFER",
        "🧳 Offer: " + offer.name + " (" + string(list_price) + "g, asking " + string(cost) + "g)."
    );

    if (sim.gold_total < cost) {
        sim_log_tag(sim, "MERCHANT_SKIP",
            "🧳 The party can't afford it and moves on."
        );
        return;
    }

    var buyer = sim.party[buyer_idx];
    var gold_before = sim.gold_total;

    sim.gold_total -= cost;
    sim.stats.merchants_bought += 1;

    sim_log_tag(sim, "MERCHANT_BUY",
        "🧳 " + buyer.name + " buys " + offer.name +
        " for " + string(cost) + "g (" + string(gold_before) + "→" + string(sim.gold_total) + ")."
    );

    if (slot != "") {
        var p = sim.party[buyer_idx];
        if ((variable_struct_exists(p, "dead") && p.dead) || (variable_struct_exists(p, "retired") && p.retired)) {
            sim_log_tag(sim, "MERCHANT_SKIP", "🧳 The intended buyer is unavailable.");
            return;
        }

        sim_recalc_derived(p);

        sim_set_equipped_item(p, slot, offer);
        sim_recalc_derived(p);

        sim_log_tag(sim, "EQUIP_CHANGE",
            "📦 " + p.name + " equips " + offer.name + " (" + slot + ")."
        );

        return;
    }

    sim_give_item(sim, offer);
}
