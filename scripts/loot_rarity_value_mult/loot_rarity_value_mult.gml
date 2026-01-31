function loot_rarity_value_mult(rarity) {
    switch (rarity) {
        case "uncommon":  return 1.25;
        case "rare":      return 1.70;
        case "epic":      return 2.50;
        case "legendary": return 3.80;
        default:          return 1.00;
    }
}

