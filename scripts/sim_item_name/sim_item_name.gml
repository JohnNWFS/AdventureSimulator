function sim_item_name(item) {
    if (is_struct(item) && variable_struct_exists(item, "name")) return item.name;
    return "-";
}