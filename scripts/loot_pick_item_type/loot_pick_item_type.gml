function loot_pick_item_type(sim, context) {
    // context: {source, zone, tier_target}
    // Weights tuned for "cinematic variety" not realism.

    var source = context.source;

    if (source == "chest") {
        return loot_pick_weighted(sim, [
            { w: 30, v: "treasure" },
            { w: 25, v: "trinket" },
            { w: 20, v: "consumable" },
            { w: 15, v: "armor" },
            { w: 10, v: "weapon" }
        ]);
    }

    if (source == "merchant") {
        return loot_pick_weighted(sim, [
            { w: 35, v: "consumable" },
            { w: 25, v: "armor" },
            { w: 25, v: "weapon" },
            { w: 15, v: "trinket" }
        ]);
    }

    if (source == "boss") {
        return loot_pick_weighted(sim, [
            { w: 45, v: "trinket" },
            { w: 30, v: "weapon" },
            { w: 25, v: "armor" }
        ]);
    }

    // combat default
    return loot_pick_weighted(sim, [
        { w: 40, v: "treasure" },
        { w: 25, v: "consumable" },
        { w: 15, v: "weapon" },
        { w: 15, v: "armor" },
        { w: 5,  v: "trinket" }
    ]);
}
