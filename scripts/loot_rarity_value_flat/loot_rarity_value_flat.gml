function loot_rarity_value_flat(rarity) {
    // Flat kicker so rarity always "feels" expensive even when stats roll low.
    switch (rarity) {
        case "uncommon":  return 35;
        case "rare":      return 120;
        case "epic":      return 320;
        case "legendary": return 850;
        default:          return 0;
    }
}

