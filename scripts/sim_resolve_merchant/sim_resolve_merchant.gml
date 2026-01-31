function sim_resolve_merchant(sim) {
    // Count this as a merchant encounter (even if you can't afford anything)
    sim.stats.merchants_seen += 1;

    // Also enforce director gating (per-zone cap)
    sim.director.merchants_this_zone += 1;
    sim.director.merchant_cd = 8; // no merchant for next 8 beats

    // Generate a merchant item
    var tier_target = clamp(2 + floor(sim.difficulty / 2), 1, 10);
    var offer = loot_generate_item(sim, { source: "merchant", zone: sim.zone, tier_target: tier_target });

    // If merchant rolled treasure, reroll once
    if (offer.type == "treasure") {
        offer = loot_generate_item(sim, { source: "merchant", zone: sim.zone, tier_target: tier_target });
    }

    // Cost: simple scaling off value (tunable later)
    //var cost = offer.buy_price;  //optional for later use
	var cost = max(10, offer.buy_price);


    if (sim.gold_total < cost) {
        sim_log_tag(sim, "MERCHANT_SKIP",
            "🧿 Merchant: party browses, can't afford " + offer.name + " (" + string(cost) + "g)."
        );
        return;
    }

    var buyer_idx = sim_rand_range(sim, 0, array_length(sim.party) - 1);
    var buyer = sim.party[buyer_idx];

    var gold_before = sim.gold_total;
    sim.gold_total -= cost;

    sim_log_tag(sim, "MERCHANT_BUY",
	"🧿 Merchant: " + buyer.name + " buys " + offer.name +
	" for " + string(cost) + "g (value " + string(offer.value) + ", sells " + string(offer.sell_value) + "). " +
	"Gold " + string(gold_before) + "→" + string(sim.gold_total) + "."

    );

    // Buyer receives what they bought
    sim_give_item_to(sim, offer, buyer_idx);
}
