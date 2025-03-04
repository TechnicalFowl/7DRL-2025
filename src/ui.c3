module dg;

import std::collections::list;
import std::math;
import raylib5::rl;

enum SidebarTab
{
    INVENTORY,
    EQUIPMENT,
    SPELLBOOK,
    SKILLS,
}

SidebarTab sidebar_tab;
int sidebar_width;

int inv_minimenu_target;
int minimenu_height;


enum InvAction
{
    NO_ACTION,
    ACT_QUAFF,
    ACT_EQUIP,
    ACT_DROP,
    ACT_USE,
    ACT_EXAMINE,
    ACT_USE_ON,
    ACT_AIM,
}
InvAction inv_action;
int inv_action_source;
IVec2 inv_action_target;
ulong inv_action_changed;

List(<ItemStack>) storage_contents;

fn bool ui_wants_keys()
{
    return gui::want_key_input() || inv_action != NO_ACTION;
}

fn void init_ui()
{
    sidebar_tab = INVENTORY;
    sidebar_width = 54;
    inv_action = NO_ACTION;
    storage_contents.new_init();
}

fn void draw_ui()
{
    Player* pl = (Player*) g_zone.player;
    int term_width = ui_term.width;
    int term_height = ui_term.height;
    int map_width = ui_term.width - sidebar_width;

    gui::push_topbar("The Depths of Daemonheim - 7DRL 2025");
    bool debug_info_bar = false;
    if (debug_info_bar)
    {
        gui::push_bottombar(string::tformat("K:%s M:%s", gui::want_key_input() ? "true" : "false", gui::want_mouse_input() ? "true" : "false"));
    }
    else if (inv_action != NO_ACTION)
    {
        switch (inv_action)
        {
        case ACT_QUAFF:
            gui::push_bottombar(string::tformat("Quaff which item? (Select in inventory, %s to cancel)", getKeyName(get_bind(CANCEL)[0])));
        case ACT_EQUIP:
            gui::push_bottombar(string::tformat("Equip which item? (Select in inventory, %s to cancel)", getKeyName(get_bind(CANCEL)[0])));
        case ACT_DROP:
            gui::push_bottombar(string::tformat("Drop which item? (Select in inventory, %s to cancel)", getKeyName(get_bind(CANCEL)[0])));
        case ACT_USE:
            gui::push_bottombar(string::tformat("Use which item? (Select in inventory, %s to cancel)", getKeyName(get_bind(CANCEL)[0])));
        case ACT_USE_ON:
            ItemStack stack = pl.inventory[inv_action_source];
            ItemInfo* info = &g_items.items[stack.item];
            gui::push_bottombar(string::tformat("Use %s on? (Select in inventory or bump into target, %s to cancel)", info.name, getKeyName(get_bind(CANCEL)[0])));
        case ACT_EXAMINE:
            gui::push_bottombar(string::tformat("Examine which item? (Select in inventory, %s to cancel)", getKeyName(get_bind(CANCEL)[0])));
        case ACT_AIM:
            gui::push_bottombar(string::tformat("Choose ranged target (%s to cancel)", getKeyName(get_bind(CANCEL)[0])));
        case NO_ACTION:
            unreachable();
        }
    }
    else
    {
        gui::push_bottombar(string::tformat("%-16s", g_zone.name));
        gui::push_bottombar(string::tformat("T:%.0f", elapsed_time));
    }
    
    DString healthbar;
    healthbar.temp_init();
    float health_pct = (float) pl.health / pl.level[Skill.HITPOINTS];
    int health_len = math::min((int) (health_pct * 20), 20);
    for (int i = 0; i < health_len; ++i)
    {
        healthbar.append_char('#');
    }
    for (int i = health_len; i < 20; ++i)
    {
        healthbar.append_char(' ');
    }
    ui_term.write(map_width, 0, string::tformat("Health: %2d/%2d [", pl.health, pl.level[Skill.HITPOINTS]), { 220, 220, 220, 255 }, 10);
    ui_term.write(map_width+15, 0, string::tformat("%s", healthbar), colors::RED, 10);
    ui_term.write(map_width+15+20, 0, "]", { 220, 220, 220, 255 }, 10);

    int inv_height = 34;
    int log_height = term_height - inv_height - 1;
    gui::begin_window("Log", {map_width, 1}, {sidebar_width, log_height});
    
    long start = math::max(log_messages.len() - log_height + 2, 0l);
    for (long i = start; i < log_messages.len(); ++i)
    {
        LogMessage msg = log_messages[i];
        gui::text(msg.message, msg.color);
    }

    gui::end_window();

    int prio = 10;
    IVec2 spos = {map_width, log_height};
    IVec2 ssize = {sidebar_width, term_height - log_height};
    GuiWindow* sidebar_window = gui::begin_window("Inv", spos, ssize, border: false);
    sidebar_window.cursor += {1, 1};
    sidebar_window.newline_start++;

    ui_term.box_tile(...spos, ...ssize, false, colors::GREY, prio);
    ui_term.fill_tile(spos.x + 5, spos.y, 9, 1, ' ', colors::WHITE, prio);
    ui_term.set_tile(spos.x + 4, spos.y, 180, colors::GREY, prio);
    ui_term.set_tile(spos.x + 14, spos.y, 195, colors::GREY, prio);
    ui_term.write(spos.x + 6, spos.y, string::tformat("%c:Equip", getKeyIcon(get_bind(EQUIPMENT_TAB)[0])), sidebar_tab == EQUIPMENT ? { 220, 220, 220, 255 } : colors::GREY, prio);

    bool can_get_input = gui::gui_data.can_receive_input(sidebar_window);

    if (can_get_input && (inv_action != NO_ACTION) && is_key_pressed(CANCEL, false))
    {
        inv_action = NO_ACTION;
    }

    if (can_get_input && is_key_pressed(ZAP, false) && inv_action == NO_ACTION)
    {
        Item item = pl.equipment[EquipmentSlot.WEAPON].item;
        if (item == NO_ITEM)
        {
            log("You don't have anything to throw.");
        }
        else if (getStyle(item) == MELEE)
        {
            log("It probably wouldn't be a good idea to throw your weapon.");
        }
        else
        {
            inv_action = ACT_AIM;
            if (!gui::want_mouse_input())
            {
                inv_action_target = pl.get_zone().get_mouse_position();
            }
            else
            {
                inv_action_target = pl.get_position();
            }
        }
    }

    if (can_get_input && inv_action == ACT_AIM)
    {
        bool is_shift = is_key_down(DIAGONAL_UP);
        bool is_ctrl = is_key_down(DIAGONAL_DOWN);
        if (is_key_pressed(MOVE_UP))
        {
            inv_action_target += {0, -1};
        }
        if (is_key_pressed(MOVE_DOWN))
        {
            inv_action_target += {0, 1};
        }
        if (is_key_pressed(MOVE_LEFT))
        {
            if (is_shift)
            {
                inv_action_target += {-1, -1};
            }
            else if (is_ctrl)
            {
                inv_action_target += {-1, 1};
            }
            else
            {
                inv_action_target += {-1, 0};
            }
        }
        if (is_key_pressed(MOVE_RIGHT))
        {
            if (is_shift)
            {
                inv_action_target += {1, -1};
            }
            else if (is_ctrl)
            {
                inv_action_target += {1, 1};
            }
            else
            {
                inv_action_target += {1, 0};
            }
        }
        if (is_key_pressed(MOVE_UP_RIGHT))
        {
            inv_action_target += {1, -1};
        }
        if (is_key_pressed(MOVE_DOWN_RIGHT))
        {
            inv_action_target += {1, 1};
        }
        if (is_key_pressed(MOVE_DOWN_LEFT))
        {
            inv_action_target += {-1, 1};
        }
        if (is_key_pressed(MOVE_UP_LEFT))
        {
            inv_action_target += {-1, -1};
        }
    }

    if (can_get_input && is_key_pressed(EQUIPMENT_TAB, false))
    {
        sidebar_tab = EQUIPMENT;
        if (inv_action != ACT_AIM)
        {
            inv_action = NO_ACTION;
        }
    }

    if (sidebar_tab == EQUIPMENT)
    {
        if (can_get_input && inv_action == NO_ACTION)
        {
            if (is_key_pressed(EQUIP, allow_repeat: false, consume_press: true))
            {
                inv_action = ACT_EQUIP;
            }
            else if (is_key_pressed(DROP, allow_repeat: false, consume_press: true))
            {
                inv_action = ACT_DROP;
            }
            else if (is_key_pressed(EXAMINE, allow_repeat: false, consume_press: true))
            {
                inv_action = ACT_EXAMINE;
            }
            inv_action_changed = gui::gui_data.frame_index;
        }

        gui::text("");
        bool valid_inv_action = (inv_action != NO_ACTION && gui::gui_data.frame_index - 1 > inv_action_changed);
        for (int i = 0; i < pl.equipment.len; ++i)
        {
            ItemStack stack = pl.equipment[i];
            gui::text(string::tformat("%-10s: ", EquipmentSlot.names[i]));
            if (stack.item != NO_ITEM)
            {
                gui::same_line();
                ItemInfo* info = &g_items.items[stack.item];
                String count = stack.count > 1 ? string::tformat(" x%d", stack.count) : "";
                if (gui::button(string::tformat("%s%s", info.name, count), (KeyboardKey)(valid_inv_action ? (int) rl::KEY_A + i : 0)))
                {
                    if (inv_action != NO_ACTION && inv_action != ACT_AIM)
                    {
                        switch (inv_action)
                        {
                        case ACT_EQUIP:
                            pl.equipment[i] = { NO_ITEM, 0, 0 };
                            if (pl.is_inventory_full(stack))
                            {
                                log(string::new_format("You drop the %s on the ground.", info.name));
                                g_zone.drop_item(...pl.get_position(), stack);
                            }
                            else
                            {
                                pl.add_item(stack);
                            }
                        case ACT_DROP:
                            g_zone.drop_item(...pl.get_position(), stack);
                            pl.inventory[i] = { NO_ITEM, 0, 0 };
                        case ACT_EXAMINE:
                            break;
                        case ACT_QUAFF:
                        case ACT_USE:
                        case ACT_USE_ON:
                        case ACT_AIM:
                        case NO_ACTION:
                            unreachable();
                        }
                        inv_action = NO_ACTION;
                    }
                    else
                    {
                        inv_minimenu_target = i;
                        minimenu_height = sidebar_window.cursor.y;
                        gui::open_popup("Equipped Menu");
                    }
                }
            }
        }
        
        gui::vertical_separator(7);
        gui::text("         Accuracy     Damage      Defence");
        int[3] melee_stats = pl.get_style_stats(MELEE);
        gui::text(string::tformat("Melee        %4d       %4d         %4d", ...melee_stats));
        int[3] ranged_stats = pl.get_style_stats(RANGED);
        gui::text(string::tformat("Ranged       %4d       %4d         %4d", ...ranged_stats));
        int[3] magic_stats = pl.get_style_stats(MAGIC);
        gui::text(string::tformat("Magic        %4d       %4d         %4d", ...magic_stats));
        gui::vertical_separator(8);
        gui::text(string::tformat("%5s: Unequip Item         %5s: Drop Item", getKeyName(get_bind(EQUIP)[0]), getKeyName(get_bind(DROP)[0])));
        gui::text(string::tformat("                            %5s: Examine Item", getKeyName(get_bind(EXAMINE)[0])));
    }

    if (gui::begin_popup("Equipped Menu", {spos.x - 33, math::min(term_height - 10, minimenu_height)}, {32, 8}))
    {
        GuiWindow* pwindow = gui::gui_data.window_stack.last()!!;
        ItemStack stack = pl.equipment[inv_minimenu_target];
        if (stack.item == NO_ITEM)
        {
            gui::close_current_popup();
            return;
        }
        ItemInfo* info = &g_items.items[stack.item];
        String count = stack.count > 1 ? string::tformat("x%d", stack.count) : "";
        gui::text(string::tformat("%s%s", info.name, count));
        if (gui::button("Unequip", get_bind(EQUIP)[0]))
        {
            pl.equipment[inv_minimenu_target] = { NO_ITEM, 0, 0 };
            if (pl.is_inventory_full(stack))
            {
                log(string::new_format("You drop the %s on the ground.", info.name));
                g_zone.drop_item(...pl.get_position(), stack);
            }
            else
            {
                pl.add_item(stack);
            }
            gui::close_current_popup();
        }
        if (gui::button("Drop", get_bind(DROP)[0]))
        {
            g_zone.drop_item(...pl.get_position(), {stack.item, stack.count, stack.metadata});
            pl.equipment[inv_minimenu_target] = { NO_ITEM, 0, 0 };
            gui::close_current_popup();
        }
        if (gui::button("Examine", get_bind(EXAMINE)[0]))
        {
            gui::close_current_popup();
        }
        if (gui::button("Cancel", get_bind(CANCEL)[0]))
        {
            gui::close_current_popup();
        }
        gui::end_popup();
    }

    ui_term.fill_tile(spos.x + 17, spos.y, 9, 1, ' ', colors::WHITE, prio);
    ui_term.set_tile(spos.x + 16, spos.y, 180, colors::GREY, prio);
    ui_term.set_tile(spos.x + 26, spos.y, 195, colors::GREY, prio);
    ui_term.write(spos.x + 18, spos.y, string::tformat("%c:Inven", getKeyIcon(get_bind(INVENTORY_TAB)[0])), sidebar_tab == INVENTORY ? { 220, 220, 220, 255 } : colors::GREY, prio);

    if (can_get_input && is_key_pressed(INVENTORY_TAB, false))
    {
        sidebar_tab = INVENTORY;
        if (inv_action != ACT_AIM)
        {
            inv_action = NO_ACTION;
        }
    }

    if (sidebar_tab == INVENTORY)
    {
        if (can_get_input && inv_action == NO_ACTION)
        {
            if (is_key_pressed(EQUIP, allow_repeat: false, consume_press: true))
            {
                inv_action = ACT_EQUIP;
            }
            else if (is_key_pressed(DROP, allow_repeat: false, consume_press: true))
            {
                inv_action = ACT_DROP;
            }
            else if (is_key_pressed(USE, allow_repeat: false, consume_press: true))
            {
                inv_action = ACT_USE;
            }
            else if (is_key_pressed(EXAMINE, allow_repeat: false, consume_press: true))
            {
                inv_action = ACT_EXAMINE;
            }
            else if (is_key_pressed(QUAFF, allow_repeat: false, consume_press: true))
            {
                inv_action = ACT_QUAFF;
            }
            inv_action_changed = gui::gui_data.frame_index;
        }

        gui::text("");
        bool valid_inv_action = inv_action != NO_ACTION && gui::gui_data.frame_index - 1 > inv_action_changed;
        for (int i = 0; i < pl.inventory.len; ++i)
        {
            ItemStack stack = pl.inventory[i];
            if (stack.item != NO_ITEM)
            {
                ItemInfo* info = &g_items.items[stack.item];
                String count = stack.count > 1 ? string::tformat(" x%d", stack.count) : "";
                if (gui::button(string::tformat("%s%s", info.name, count), (KeyboardKey)(valid_inv_action ? (int) rl::KEY_A + i : 0), disabled: (inv_action == ACT_USE_ON && inv_action_source == i) || (inv_action == ACT_EQUIP && info.stats == null) || (inv_action == ACT_QUAFF && !is_consumable(stack.item))))
                {
                    if (inv_action != NO_ACTION && inv_action != ACT_AIM)
                    {
                        InvAction this_action = inv_action;
                        inv_action = NO_ACTION;
                        switch (this_action)
                        {
                        case ACT_QUAFF:
                            pl.quaff(stack);
                            pl.inventory[i].count--;
                            if (pl.inventory[i].count == 0)
                            {
                                pl.inventory[i] = { NO_ITEM, 0, 0 };
                            }
                        case ACT_EQUIP:
                            ItemStack replaced = pl.equip(stack);
                            pl.inventory[i] = { NO_ITEM, 0, 0 };
                            if (replaced.item != NO_ITEM)
                            {
                                pl.add_item(replaced);
                            }
                        case ACT_DROP:
                            g_zone.drop_item(...pl.get_position(), stack);
                            pl.inventory[i] = { NO_ITEM, 0, 0 };
                        case ACT_USE:
                            inv_action_source = i;
                            inv_action = ACT_USE_ON;
                        case ACT_USE_ON:
                            pl.use_item_pair(inv_action_source, i);
                            inv_action_source = -1;
                        case ACT_EXAMINE:
                            break;
                        case ACT_AIM:
                        case NO_ACTION:
                            unreachable();
                        }
                    }
                    else
                    {
                        inv_minimenu_target = i;
                        minimenu_height = sidebar_window.cursor.y;
                        gui::open_popup("Item Menu");
                    }
                }
            }
            else
            {
                gui::text("");
            }
        }
        
        gui::vertical_separator(1);
        gui::text(string::tformat("%5s: Equip Item           %5s: Drop Item", getKeyName(get_bind(EQUIP)[0]), getKeyName(get_bind(DROP)[0])));
        gui::text(string::tformat("%5s: Use Item             %5s: Examine Item", getKeyName(get_bind(USE)[0]), getKeyName(get_bind(EXAMINE)[0])));
        gui::text(string::tformat("%5s: Quaff Item           ", getKeyName(get_bind(QUAFF)[0])));
    }

    if (gui::begin_popup("Item Menu", {spos.x - 33, math::min(term_height - 10, minimenu_height)}, {32, 8}))
    {
        GuiWindow* pwindow = gui::gui_data.window_stack.last()!!;
        ItemStack stack = pl.inventory[inv_minimenu_target];
        if (stack.item == NO_ITEM)
        {
            gui::close_current_popup();
            return;
        }
        ItemInfo* info = &g_items.items[stack.item];
        String count = stack.count > 1 ? string::tformat("x%d", stack.count) : "";
        gui::text(string::tformat("%s%s", info.name, count));
        if (info.stats && gui::button("Equip", get_bind(EQUIP)[0]))
        {
            ItemStack old_stack = pl.equip(stack);
            pl.inventory[inv_minimenu_target] = old_stack;
            gui::close_current_popup();
        }
        if (gui::button("Drop", get_bind(DROP)[0]))
        {
            g_zone.drop_item(...pl.get_position(), stack);
            pl.inventory[inv_minimenu_target] = { NO_ITEM, 0, 0 };
            gui::close_current_popup();
        }
        if (gui::button("Use", get_bind(USE)[0]))
        {
            inv_action_source = inv_minimenu_target;
            inv_action = ACT_USE_ON;
            gui::close_current_popup();
        }
        if (gui::button("Examine", get_bind(EXAMINE)[0]))
        {
            gui::close_current_popup();
        }
        if (gui::button("Cancel", get_bind(CANCEL)[0]))
        {
            gui::close_current_popup();
        }
        gui::end_popup();
    }

    ui_term.fill_tile(spos.x + 29, spos.y, 9, 1, ' ', colors::WHITE, prio);
    ui_term.set_tile(spos.x + 28, spos.y, 180, colors::GREY, prio);
    ui_term.set_tile(spos.x + 38, spos.y, 195, colors::GREY, prio);
    ui_term.write(spos.x + 30, spos.y, string::tformat("%c:Spell", getKeyIcon(get_bind(SPELLBOOK_TAB)[0])), sidebar_tab == SPELLBOOK ? { 220, 220, 220, 255 } : colors::GREY, prio);

    if (can_get_input && is_key_pressed(SPELLBOOK_TAB, false))
    {
        sidebar_tab = SPELLBOOK;
    }

    if (sidebar_tab == SPELLBOOK)
    {

    }

    ui_term.fill_tile(spos.x + 41, spos.y, 9, 1, ' ', colors::WHITE, prio);
    ui_term.set_tile(spos.x + 40, spos.y, 180, colors::GREY, prio);
    ui_term.set_tile(spos.x + 50, spos.y, 195, colors::GREY, prio);
    ui_term.write(spos.x + 42, spos.y, string::tformat("%c:Skill", getKeyIcon(get_bind(SKILLS_TAB)[0])), sidebar_tab == SKILLS ? { 220, 220, 220, 255 } : colors::GREY, prio);

    if (can_get_input && is_key_pressed(SKILLS_TAB, false))
    {
        sidebar_tab = SKILLS;
    }

    if (sidebar_tab == SKILLS)
    {
        gui::vertical_separator(2);
        for (int i = 0; i < Skill.elements; ++i)
        {
            gui::text(string::tformat("%-12s %d", Skill.names[i], pl.level[i]));
        }
    }

    gui::end_window();

    if (can_get_input)
    {
        if (is_key_pressed(SPAWN_ITEM, false))
        {
            inv_action = NO_ACTION;
            gui::open_popup("Spawn Item");
        }
    }

    IVec2 popup_size = {60, 5 + Item.elements / 2};
    if (gui::begin_popup("Spawn Item", {term_width / 3 - popup_size.x / 2, term_height / 2 - popup_size.y / 2}, popup_size))
    {
        gui::text("Spawn Item");
        gui::same_line(5);
        if (gui::button("Close", get_bind(CANCEL)[0]))
        {
            gui::close_current_popup();
        }
        gui::text("");
        for (int i = 1; i < Item.elements; ++i)
        {
            ItemInfo* info = &g_items.items[i];
            int last_len = info.name.len + 2;
            if (gui::button(info.name))
            {
                Item item = Item.from_ordinal(i);

                bool added = false;
                int empty_slot = -1;
                for (int j = 0; j < pl.inventory.len; ++j)
                {
                    if (pl.inventory[j].item == item && pl.inventory[j].count < info.stack_size)
                    {
                        pl.inventory[j].count = info.stack_size;
                        added = true;
                        break;
                    }
                    else if (pl.inventory[j].item == NO_ITEM && empty_slot == -1)
                    {
                        empty_slot = j;
                    }
                }

                if (!added && empty_slot != -1)
                {
                    pl.inventory[empty_slot] = { item, info.stack_size, 0 };
                }
            }
            if (i % 2 != 0)
            {
                gui::same_line(math::max(1, 30 - last_len));
            }
        }
        gui::end_popup();
    }

    if (inv_action_target.x >= 0 && inv_action_target.x < g_zone.width && inv_action_target.y >= 0 && inv_action_target.y < g_zone.height)
    {
        ZoneCell* cell = g_zone.get_cell(...inv_action_target);
        popup_size = {60, 5 + (int) cell.dropped_items.len()};
        if (gui::begin_popup("Grab Item", {term_width / 3 - popup_size.x / 2, term_height / 2 - popup_size.y / 2}, popup_size))
        {
            gui::same_line(20);
            if (gui::button("Close", get_bind(CANCEL)[0]))
            {
                gui::close_current_popup();
            }
            gui::text("");
            if (cell.dropped_items.is_empty())
            {
                gui::close_current_popup();
            }
            for (int i = 0; i < cell.dropped_items.len(); ++i)
            {
                ItemStack stack = cell.dropped_items[i];
                ItemInfo* info = &g_items.items[stack.item];
                int last_len = info.name.len + 2;
                if (gui::button(info.name, (KeyboardKey) ((int) rl::KEY_A + i)))
                {
                    if (pl.is_inventory_full(stack))
                    {
                        log("Inventory is full!");
                        gui::close_current_popup();
                    }
                    else
                    {
                        pl.add_item(stack);
                        cell.dropped_items.remove_at(i);
                        gui::close_current_popup();
                    }
                }
            }
            gui::end_popup();
        }
    }

    popup_size = {100, 15};
    if (gui::begin_popup("Smith Item", {term_width / 3 - popup_size.x / 2, term_height / 3 - popup_size.y / 2}, popup_size))
    {
        gui::same_line(20);
        if (gui::button("Close", get_bind(CANCEL)[0]))
        {
            gui::close_current_popup();
        }
        gui::text("");
        if (gui::button("Novite Sword (3x Novite Ingot)", rl::KEY_A, disabled: !pl.has_item(INGOT1, 3)))
        {
            if (do_smith({ SWORD1, 1, 0 }, { INGOT1, 3, 0 })) gui::close_current_popup();
        }
        if (gui::button("Novite Staff (1x Novite Ingot, 1x Logs, 10x Air Runes)", rl::KEY_B, disabled: !pl.has_item(INGOT1) || !pl.has_item(LOGS) || !pl.has_item(AIR_RUNE, 10)))
        {
            if (do_smith({ STAFF1, 1, 0 }, { INGOT1, 1, 0 }, { LOGS, 1, 0 }, { AIR_RUNE, 10, 0 })) gui::close_current_popup();
        }
        if (gui::button("Novite Bow (2x Novite Ingot, 1x Logs)", rl::KEY_C, disabled: !pl.has_item(INGOT1, 2) || !pl.has_item(LOGS)))
        {
            if (do_smith({ BOW1, 1, 0 }, { INGOT1, 2, 0 }, { LOGS, 1, 0 })) gui::close_current_popup();
        }
        if (gui::button("Fractite Sword (3x Fractite Ingot)", rl::KEY_D, disabled: !pl.has_item(INGOT2, 3)))
        {
            if (do_smith({ SWORD2, 1, 0 }, { INGOT2, 3, 0 })) gui::close_current_popup();
        }
        if (gui::button("Fractite Staff (1x Fractite Ingot, 1x Logs, 50x Water Runes)", rl::KEY_E, disabled: !pl.has_item(INGOT2) || !pl.has_item(LOGS) || !pl.has_item(WATER_RUNE, 50)))
        {
            if (do_smith({ STAFF2, 1, 0 }, { INGOT2, 1, 0 }, { LOGS, 1, 0 }, { WATER_RUNE, 50, 0 })) gui::close_current_popup();
        }
        if (gui::button("Fractite Bow (2x Fractite Ingot, 1x Logs)", rl::KEY_F, disabled: !pl.has_item(INGOT2, 2) || !pl.has_item(LOGS)))
        {
            if (do_smith({ BOW2, 1, 0 }, { INGOT2, 2, 0 }, { LOGS, 1, 0 })) gui::close_current_popup();
        }
        if (gui::button("Promethium Sword (3x Promethium Ingot)", rl::KEY_G, disabled: !pl.has_item(INGOT3, 3)))
        {
            if (do_smith({ SWORD3, 1, 0 }, { INGOT3, 3, 0 })) gui::close_current_popup();
        }
        if (gui::button("Promethium Staff (1x Promethium Ingot, 1x Logs, 100x Fire Runes)", rl::KEY_H, disabled: !pl.has_item(INGOT3) || !pl.has_item(LOGS) || !pl.has_item(FIRE_RUNE, 100)))
        {
            if (do_smith({ STAFF3, 1, 0 }, { INGOT3, 1, 0 }, { LOGS, 1, 0 }, { FIRE_RUNE, 100, 0 })) gui::close_current_popup();
        }
        if (gui::button("Promethium Bow (2x Promethium Ingot, 1x Logs)", rl::KEY_I, disabled: !pl.has_item(INGOT3, 2) || !pl.has_item(LOGS)))
        {
            if (do_smith({ BOW3, 1, 0 }, { INGOT3, 2, 0 }, { LOGS, 1, 0 })) gui::close_current_popup();
        }
        gui::end_popup();
    }
    
    popup_size = {100, 15};
    if (gui::begin_popup("Search Crate", {term_width / 3 - popup_size.x / 2, term_height / 2 - popup_size.y / 2}, popup_size))
    {
        if (storage_contents.is_empty())
        {
            gui::close_current_popup();
        }
        gui::same_line(20);
        if (gui::button("Close", get_bind(CANCEL)[0]))
        {
            foreach (i: storage_contents)
            {
                g_zone.drop_item(...pl.get_position(), i);
            }
            storage_contents.clear();
            gui::close_current_popup();
        }
        gui::text("");
        int i = 0;
        foreach (stack: storage_contents)
        {
            ItemInfo* info = &g_items.items[stack.item];
            int last_len = info.name.len + 2;
            if (gui::button(info.name, (KeyboardKey) ((int) rl::KEY_A + i)))
            {
                if (pl.is_inventory_full(stack))
                {
                    log("Your inventory is full!");
                }
                else
                {
                    pl.add_item(stack);
                    storage_contents.remove_at(i);
                    break;
                }
            }
            i++;
        }
        gui::end_popup();
    }
}

fn bool do_smith(ItemStack result, ItemStack... ingredients)
{
    Player* pl = (Player*) g_zone.player;
    for (int i = 0; i < ingredients.len; ++i)
    {
        if (!pl.has_item(ingredients[i].item, ingredients[i].count))
        {
            return false;
        }
    }
    for (int i = 0; i < ingredients.len; ++i)
    {
        bool removed = pl.remove_item(ingredients[i]);
        assert(removed);
    }
    ItemStack remaining = pl.add_item(result);
    if (remaining.item != NO_ITEM)
    {
        for (int i = 0; i < ingredients.len; ++i)
        {
            pl.add_item(ingredients[i]);
        }
        return false;
    }
    log(string::new_format("You smith a %s!", g_items.items[result.item].name));
    return true;
}