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
        case "uncommon":
            var uncommon_prefixes = ["Fine", "Sturdy", "Keen"];
            rarity_prefix = uncommon_prefixes[sim_rand_range(sim, 0, array_length(uncommon_prefixes) - 1)];
            break;
        case "rare":
            var rare_prefixes = ["Runed", "Blessed", "Shadow"];
            rarity_prefix = rare_prefixes[sim_rand_range(sim, 0, array_length(rare_prefixes) - 1)];
            var rare_fx = ["spark_blue", "holy_glow", "shadow_glow"];
            fx = rare_fx[sim_rand_range(sim, 0, array_length(rare_fx) - 1)];
            break;
        case "epic":
            var epic_prefixes = ["Warden's", "Ancient", "Sovereign"];
            rarity_prefix = epic_prefixes[sim_rand_range(sim, 0, array_length(epic_prefixes) - 1)];
            var epic_fx = ["steel_spark", "ember_glow", "holy_glow"];
            fx = epic_fx[sim_rand_range(sim, 0, array_length(epic_fx) - 1)];
            break;
        case "legendary":
            var legendary_prefixes = ["Mythic", "Unbroken", "Crowned"];
            rarity_prefix = legendary_prefixes[sim_rand_range(sim, 0, array_length(legendary_prefixes) - 1)];
            var legendary_fx = ["holy_glow", "shadow_glow"];
            fx = legendary_fx[sim_rand_range(sim, 0, array_length(legendary_fx) - 1)];
            break;
        default:          rarity_prefix = ""; break;
    }

    switch (item_type) {

        case "weapon":
            prefix = rarity_prefix;
            switch (zone) {
                case "Dungeon":
                    var weapon_dungeon = ["Iron", "Bone", "Slate"];
                    material = weapon_dungeon[sim_rand_range(sim, 0, array_length(weapon_dungeon) - 1)];
                    break;
                case "Wilderness":
                    var weapon_wild = ["Bone", "Oak", "Flint"];
                    material = weapon_wild[sim_rand_range(sim, 0, array_length(weapon_wild) - 1)];
                    break;
                case "Town":
                    var weapon_town = ["Steel", "Brass", "Iron"];
                    material = weapon_town[sim_rand_range(sim, 0, array_length(weapon_town) - 1)];
                    break;
                case "Castle":
                    var weapon_castle = ["Silver", "Iron", "Steel"];
                    material = weapon_castle[sim_rand_range(sim, 0, array_length(weapon_castle) - 1)];
                    break;
                default:
                    var weapon_default = ["Iron", "Steel"];
                    material = weapon_default[sim_rand_range(sim, 0, array_length(weapon_default) - 1)];
                    break;
            }
            anim = "equip_hand";
            break;

        case "armor":
            prefix = rarity_prefix;
            switch (zone) {
                case "Dungeon":
                    var armor_dungeon = ["Iron", "Hide", "Bone"];
                    material = armor_dungeon[sim_rand_range(sim, 0, array_length(armor_dungeon) - 1)];
                    break;
                case "Wilderness":
                    var armor_wild = ["Hide", "Leather", "Bone"];
                    material = armor_wild[sim_rand_range(sim, 0, array_length(armor_wild) - 1)];
                    break;
                case "Town":
                    var armor_town = ["Steel", "Leather", "Iron"];
                    material = armor_town[sim_rand_range(sim, 0, array_length(armor_town) - 1)];
                    break;
                case "Castle":
                    var armor_castle = ["Iron", "Steel", "Silver"];
                    material = armor_castle[sim_rand_range(sim, 0, array_length(armor_castle) - 1)];
                    break;
                default:
                    var armor_default = ["Leather", "Iron"];
                    material = armor_default[sim_rand_range(sim, 0, array_length(armor_default) - 1)];
                    break;
            }
            anim = "equip_body";
            break;

        case "trinket":
            prefix = rarity_prefix;
            switch (zone) {
                case "Dungeon":
                    var trinket_dungeon = ["Obsidian", "Slate", "Onyx"];
                    material = trinket_dungeon[sim_rand_range(sim, 0, array_length(trinket_dungeon) - 1)];
                    break;
                case "Wilderness":
                    var trinket_wild = ["Jade", "Bone", "Amber"];
                    material = trinket_wild[sim_rand_range(sim, 0, array_length(trinket_wild) - 1)];
                    break;
                case "Town":
                    var trinket_town = ["Silver", "Brass", "Steel"];
                    material = trinket_town[sim_rand_range(sim, 0, array_length(trinket_town) - 1)];
                    break;
                case "Castle":
                    var trinket_castle = ["Silver", "Gold", "Marble"];
                    material = trinket_castle[sim_rand_range(sim, 0, array_length(trinket_castle) - 1)];
                    break;
                default:
                    var trinket_default = ["Silver", "Brass"];
                    material = trinket_default[sim_rand_range(sim, 0, array_length(trinket_default) - 1)];
                    break;
            }
            anim = "equip_trinket";
            break;

        case "consumable":
            // Always use flavor adjectives (ignore rarity_prefix)
			material = "";
			var consumable_prefixes = ["Soothing", "Bitter", "Ember", "Clear", "Holy", "Shadow", "Fortifying"];
			prefix = consumable_prefixes[sim_rand_range(sim, 0, array_length(consumable_prefixes) - 1)];

            anim = "drink";

            // Optional fx for higher rarities (keeps "rare" feel without "Keen Vial")
            if (rarity == "rare" || rarity == "epic" || rarity == "legendary") {
                var consumable_fx = ["spark_blue", "holy_glow", "ember_glow", "shadow_glow"];
                fx = consumable_fx[sim_rand_range(sim, 0, array_length(consumable_fx) - 1)];
            }
            break;

        case "treasure":
            // Treasure reads like a descriptor (ignore rarity_prefix)
            material = "";
            var treasure_prefixes = ["Gilded", "Ancient", "Engraved", "Jeweled", "Forgotten", "Royal", "Sealed"];
            prefix = treasure_prefixes[sim_rand_range(sim, 0, array_length(treasure_prefixes) - 1)];
            anim = "pickup";

            if (rarity == "rare" || rarity == "epic" || rarity == "legendary") {
                var treasure_fx = ["spark_blue", "ember_glow", "holy_glow"];
                fx = treasure_fx[sim_rand_range(sim, 0, array_length(treasure_fx) - 1)];
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
