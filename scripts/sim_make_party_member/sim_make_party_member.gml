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

        // Base stat anchors (so sim_recalc_derived never has to guess)
        base_max_hp: max_hp,
        base_max_mp: max_mp,
        base_atk: atk,

        // Legacy string-ish fields (HUD compatibility)
        weapon: "",
        armor: "",
        trinket: "",
        consumable: "",

        // NEW canonical equip struct (always exists)
        equip: { weapon: undefined, armor: undefined, trinket: undefined },

        items: [],
        status: [],

        wounds: 0,
        near_death_count: 0,
        near_death_flag: false,
        near_death_logged_once: false,
        near_death_triggered_this_beat: false,
        downed_this_beat: false,
        recent_downed_beats: [],

        // NEW death/retire system
        dead: false,
        retired: false,
        inactive: false,

        // Legacy-ish state string (kept in sync)
        status_state: "alive",
        pending_honor: false,

        // Resolve system
        resolve: 100,
        retire_notice: false,
        cracking_flag: false,

        exit_flagged: false,
        exit_mode: "none",

        injury_flag: false,
        injury_lingering: false,
        injury_stat: "",
        injury_penalty_pct: 0,
        dropped_below_30: false,
        city_underperform_flag: false,
        city_pressure_marks: 0
    };
}
