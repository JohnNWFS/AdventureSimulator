function sim_role_weighted_score(p, item) {
    // Role-aware scoring based on stats.
    // Roles: "Tank", "Mage", "Thief", "Healer"
    var s = item.stats;

    var w_atk = 0;
    var w_def = 0;
    var w_hp  = 0;
    var w_mp  = 0;

    switch (p.role) {
        case "Tank":
            w_atk = 5.0;  w_def = 12.0; w_hp = 1.2; w_mp = 0.4;
            break;

        case "Mage":
            w_atk = 9.0;  w_def = 3.0;  w_hp = 0.8; w_mp = 2.6;
            break;

        case "Healer":
            w_atk = 3.0;  w_def = 5.0;  w_hp = 1.2; w_mp = 2.4;
            break;

        case "Thief":
        default:
            w_atk = 10.0; w_def = 4.0;  w_hp = 0.9; w_mp = 1.0;
            break;
    }

    // Light type shaping
    var type_mult = 1.0;
    switch (item.type) {
        case "weapon":  type_mult = (p.role == "Tank") ? 0.95 : 1.15; break;
        case "armor":   type_mult = (p.role == "Mage") ? 0.95 : 1.10; break;
        case "trinket": type_mult = 1.00; break;
    }

    // NOTE: don't name this variable "score" (built-in in GameMaker)
    var sc =
        s.atk * w_atk +
        s.def * w_def +
        s.hp  * w_hp +
        s.mp  * w_mp;

    // Small tier baseline so higher tiers still matter a bit
    sc += item.tier * 1.5;

    return sc * type_mult;
}
