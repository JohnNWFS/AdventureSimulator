function sim_name_pick(sim, role) {
    // Lightweight name pools; later you can replace with a name generator
    var list;
    switch (role) {
        case "tank":   list = ["Brann", "Korda", "Hollis", "Marek"]; break;
        case "mage":   list = ["Veya", "Sorin", "Ilyra", "Quen"]; break;
        case "thief":  list = ["Pip", "Nyx", "Ravel", "Tams"]; break;
        case "healer": list = ["Edda", "Mira", "Sel", "Jonel"]; break;
        default:       list = ["Ash", "Rowan", "Vale", "Skye"]; break;
    }
    return list[sim_rand_range(sim, 0, array_length(list) - 1)];
}
