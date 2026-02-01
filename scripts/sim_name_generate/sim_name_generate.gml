function sim_name_generate(sim, role) {
    // More variety than fixed pools, but still readable.
    var a = ["Br", "Kor", "Mal", "Tor", "Fen", "Har", "Rav", "Sel", "Qu", "Il", "Mor", "Val", "Jen", "Tal"];
    var b = ["ann", "da", "rek", "vek", "ris", "len", "eth", "yx", "en", "ira", "os", "ar", "iel", "um"];
    var c = ["", "", "", " the Scarred", " of Dockside", " the Unlucky", " of the West Road"];

    var first = a[sim_rand_range(sim, 0, array_length(a) - 1)] + b[sim_rand_range(sim, 0, array_length(b) - 1)];

    // Role nudges: occasionally prefer a known iconic from your old pools
    if (sim_chance(sim, 18)) {
        switch (role) {
            case "Tank":   first = choose("Brann", "Korda", "Hollis", "Marek"); break;
            case "Mage":   first = choose("Veya", "Sorin", "Ilyra", "Quen"); break;
            case "Thief":  first = choose("Pip", "Nyx", "Ravel", "Tams"); break;
            case "Healer": first = choose("Edda", "Mira", "Sel", "Jonel"); break;
        }
    }

    var suffix = c[sim_rand_range(sim, 0, array_length(c) - 1)];
    return first + suffix;
}
