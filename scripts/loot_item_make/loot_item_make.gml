function loot_item_make(id, name, item_type, tier, rarity, value, stats, use, tags, note, anim, is_named) {

    // Pricing split (anchored on value)
    var buy_price  = max(1, floor(value * 1.15));
    var sell_value = max(1, floor(value * 0.45));

    return {
        id: id,
        name: name,
        type: item_type,
        tier: tier,
        rarity: rarity,

        // Canonical anchor + buy/sell split
        value: value,
        buy_price: buy_price,
        sell_value: sell_value,

        stats: stats,
        use: use,

        tags: tags,
        note: note,
        anim: anim,
        is_named: is_named
    };
}
