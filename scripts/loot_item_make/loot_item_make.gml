function loot_item_make(id, name, type, tier, rarity, value, stats, use, tags, fx, anim, is_named) {
    // Canonical item struct: procedural and named items share this exact format.
    return {
        id: id,
        name: name,
        type: type,           // "weapon"|"armor"|"trinket"|"consumable"|"treasure"
        tier: tier,           // int
        rarity: rarity,       // "common"|"uncommon"|"rare"|"epic"|"legendary"
        value: value,         // gold value; also your default "better-ness"

        stats: stats,         // {atk, def, hp, mp}
        use: use,             // {heal, mp, wound_heal} for consumables (0s otherwise)

        tags: tags,           // array of strings
        fx: fx,               // e.g., "spark_blue", "holy_glow"
        anim: anim,           // e.g., "equip_hand", "equip_body", "drink", "read"

        is_named: is_named    // bool (true when from named table jackpot)
    };
}
