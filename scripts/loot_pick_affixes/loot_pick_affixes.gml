function loot_pick_affixes(sim, item_type, rarity, zone) {
    var prefix = "";
    var suffix = "";
    var material = "";
    var fx = "";
    var anim = "equip_trinket";
    var tags = [];

    // Zone tag
    switch (zone) {
        case "Dungeon": tags = ["dungeon"]; break;
        case "Wilderness": tags = ["wild"]; break;
        case "Town": tags = ["civil"]; break;
        case "Castle": tags = ["castle"]; break;
        default: tags = []; break;
    }

    // Rarity flavor + fx (ONLY for gear/trinkets; NOT for consumables/treasure)
    var rarity_prefix = "";
    switch (rarity) {
        case "uncommon":  rarity_prefix = choose("Fine", "Sturdy", "Keen"); break;
        case "rare":      rarity_prefix = choose("Runed", "Blessed", "Shadow"); fx = choose("spark_blue", "holy_glow", "shadow_glow"); break;
        case "epic":      rarity_prefix = choose("Warden's", "Ancient", "Sovereign"); fx = choose("steel_spark", "ember_glow", "holy_glow"); break;
        case "legendary": rarity_prefix = choose("Mythic", "Unbroken", "Crowned"); fx = choose("holy_glow", "shadow_glow"); break;
        default:          rarity_prefix = ""; break;
    }

    switch (item_type) {

        case "weapon":
            prefix = rarity_prefix;
            switch (zone) {
                case "Dungeon":    material = choose("Iron", "Bone", "Slate"); break;
                case "Wilderness": material = choose("Bone", "Oak", "Flint"); break;
                case "Town":       material = choose("Steel", "Brass", "Iron"); break;
                case "Castle":     material = choose("Silver", "Iron", "Steel"); break;
                default:           material = choose("Iron", "Steel"); break;
            }
            anim = "equip_hand";
            break;

        case "armor":
            prefix = rarity_prefix;
            switch (zone) {
                case "Dungeon":    material = choose("Iron", "Hide", "Bone"); break;
                case "Wilderness": material = choose("Hide", "Leather", "Bone"); break;
                case "Town":       material = choose("Steel", "Leather", "Iron"); break;
                case "Castle":     material = choose("Iron", "Steel", "Silver"); break;
                default:           material = choose("Leather", "Iron"); break;
            }
            anim = "equip_body";
            break;

        case "trinket":
            prefix = rarity_prefix;
            switch (zone) {
                case "Dungeon":    material = choose("Obsidian", "Slate", "Onyx"); break;
                case "Wilderness": material = choose("Jade", "Bone", "Amber"); break;
                case "Town":       material = choose("Silver", "Brass", "Steel"); break;
                case "Castle":     material = choose("Silver", "Gold", "Marble"); break;
                default:           material = choose("Silver", "Brass"); break;
            }
            anim = "equip_trinket";
            break;

        case "consumable":
            // Always use flavor adjectives (ignore rarity_prefix)
            material = "";
			prefix = choose("Soothing", "Bitter", "Ember", "Clear", "Holy", "Shadow", "Fortifying");

            anim = "drink";

            // Optional fx for higher rarities (keeps "rare" feel without "Keen Vial")
            if (rarity == "rare" || rarity == "epic" || rarity == "legendary") {
                fx = choose("spark_blue", "holy_glow", "ember_glow", "shadow_glow");
            }
            break;

        case "treasure":
            // Treasure reads like a descriptor (ignore rarity_prefix)
            material = "";
            prefix = choose("Gilded", "Ancient", "Engraved", "Jeweled", "Forgotten", "Royal", "Sealed");
            anim = "pickup";

            if (rarity == "rare" || rarity == "epic" || rarity == "legendary") {
                fx = choose("spark_blue", "ember_glow", "holy_glow");
            }
            break;

        default:
            material = "";
            prefix = "";
            anim = "pickup";
            break;
    }

    return {
        prefix: prefix,
        suffix: suffix,
        material: material,
        tags: tags,
        fx: fx,
        anim: anim
    };
}
