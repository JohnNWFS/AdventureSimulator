function sim_name_generate(sim, role) {
    // More variety than fixed pools, but still readable.
    var a = ["Br", "Kor", "Mal", "Tor", "Fen", "Har", "Rav", "Sel", "Qu", "Il", "Mor", "Val", "Jen", "Tal"];
    var b = ["ann", "da", "rek", "vek", "ris", "len", "eth", "yx", "en", "ira", "os", "ar", "iel", "um"];
    var c = ["", "", "", " the Scarred", " of Dockside", " the Unlucky", " of the West Road"];

    var first = a[sim_rand_range(sim, 0, array_length(a) - 1)] + b[sim_rand_range(sim, 0, array_length(b) - 1)];

    // Role nudges: occasionally prefer a known iconic from your old pools
    if (sim_chance(sim, 18)) {
        switch (role) {
            case "Tank":
                var tank_names = ["Brann", "Korda", "Hollis", "Marek"];
                first = tank_names[sim_rand_range(sim, 0, array_length(tank_names) - 1)];
                break;
            case "Mage":
                var mage_names = ["Veya", "Sorin", "Ilyra", "Quen"];
                first = mage_names[sim_rand_range(sim, 0, array_length(mage_names) - 1)];
                break;
            case "Thief":
                var thief_names = ["Pip", "Nyx", "Ravel", "Tams"];
                first = thief_names[sim_rand_range(sim, 0, array_length(thief_names) - 1)];
                break;
            case "Healer":
                var healer_names = ["Edda", "Mira", "Sel", "Jonel"];
                first = healer_names[sim_rand_range(sim, 0, array_length(healer_names) - 1)];
                break;
        }
    }

    var suffix = c[sim_rand_range(sim, 0, array_length(c) - 1)];
    return first + suffix;
}
