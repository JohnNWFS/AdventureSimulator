function loot_debug_dump(sim, count, context) {
    // context: {source, zone, tier_target}
    for (var i = 0; i < count; i++) {
        var item = loot_generate_item(sim, context);

        var s = item.stats;
        var u = item.use;

        // One compact line for scanning/tuning
        sim_log_tag(sim, "ITEM_GEN",
            "🎁 " + item.name +
            " | type=" + item.type +
            " tier=" + string(item.tier) +
            " rarity=" + item.rarity +
            " value=" + string(item.value) +
            " | ATK+" + string(s.atk) +
            " DEF+" + string(s.def) +
            " HP+" + string(s.hp) +
            " MP+" + string(s.mp) +
            " | use(heal=" + string(u.heal) +
            " mp=" + string(u.mp) +
            " wound=" + string(u.wound_heal) + ")" +
            (item.is_named ? " | NAMED!" : "")
        );
    }
}
