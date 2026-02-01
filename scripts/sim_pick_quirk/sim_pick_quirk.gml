function sim_pick_quirk(sim, role) {
    // Small flavor hooks only (we log them; you can later make them mechanical)
    var list;

    switch (role) {
        case "Tank":
            list = ["Stubborn", "Scarred", "Oathbound", "Iron-Lunged"];
            break;
        case "Mage":
            list = ["Glass Cannon", "Rune-addled", "Superstitious", "Cold Focus"];
            break;
        case "Thief":
            list = ["Duelist", "Luckless", "Quickstep", "Smirking"];
            break;
        case "Healer":
            list = ["Field Medic", "Soft-Spoken", "Hard-Prayer", "Grim Calm"];
            break;
        default:
            list = ["Odd", "Wandering", "Quiet", "Unlucky"];
            break;
    }

    return list[sim_rand_range(sim, 0, array_length(list) - 1)];
}
