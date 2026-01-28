function sim_make_party_member(role, name, max_hp, max_mp, atk, def) {
    return {
        role: role,
        name: name,

        hp: max_hp,
        max_hp: max_hp,

        mp: max_mp,
        max_mp: max_mp,

        atk: atk,
        base_def: def,
        def: def,

        weapon: "",
        armor: "",
        trinket: "",
        consumable: "",

        items: [],
        status: [],

        wounds: 0,
        near_death_flag: false,

        // NEW: prevents healing after lethal damage in same beat
        downed_this_beat: false
    };
}
