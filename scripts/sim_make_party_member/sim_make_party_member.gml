function sim_make_party_member(role, name, max_hp, max_mp, atk, def) {
    return {
        role: role,
        name: name,

        // Base stats (never directly modified by gear)
        base_max_hp: max_hp,
        base_max_mp: max_mp,
        base_atk: atk,
        base_def: def,

        // Current stats (derived from base + gear)
        hp: max_hp,
        max_hp: max_hp,

        mp: max_mp,
        max_mp: max_mp,

        atk: atk,
        def: def,

        // Equipped items (structs or undefined)
        equip: {
            weapon: undefined,
            armor: undefined,
            trinket: undefined
        },

        // Immediate-use consumable (kept here for now; struct or undefined)
        consumable: undefined,

        // Future inventory hooks (we'll expand later)
        items: [],
        status: [],

        wounds: 0,
        near_death_flag: false,

        // Prevents healing after lethal damage in same beat
        downed_this_beat: false
    };
}
