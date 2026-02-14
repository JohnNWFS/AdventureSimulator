/// @function rng_seed_init(seed)
/// @desc Canonical RNG seeding for deterministic episodes.
/// @param seed {real|string}

function rng_seed_init(seed)
{
    // Normalize seed to an int
    var s = seed;

    if (is_string(s)) {
        // Simple string->int hash (stable)
        var h = 0;
        for (var i = 1; i <= string_length(s); i++) {
            h = (h * 31 + ord(string_char_at(s, i))) & 2147483647;
        }
        s = h;
    }

    s = irandom_range(0, 2147483647) + 0; // ensure numeric
    // If numeric, keep it stable
    if (!is_string(seed)) s = floor(seed);

    // Seed GameMaker RNG
    random_set_seed(s);

    // Store for debug visibility
    global.debug_seed = s;
}