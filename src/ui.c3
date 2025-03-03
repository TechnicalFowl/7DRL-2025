module dg;

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

IVec2 grab_target;

fn void init_ui()
{
    sidebar_tab = INVENTORY;
    sidebar_width = 54;
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
    else
    {
        gui::push_bottombar(string::tformat("%-16s", g_zone.name));
        gui::push_bottombar(string::tformat("T:%.0f", elapsed_time));
    }

    int log_height = math::clamp((term_height - 2) / 5, 7, 15);
    gui::begin_window("Log", {map_width, 0}, {sidebar_width, log_height});
    
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

    if (can_get_input && is_key_pressed(EQUIPMENT_TAB, false))
    {
        sidebar_tab = EQUIPMENT;
    }

    if (sidebar_tab == EQUIPMENT)
    {
        gui::text("");
        for (int i = 0; i < pl.equipment.len; ++i)
        {
            ItemStack stack = pl.equipment[i];
            gui::text(string::tformat("%-10s: ", EquipmentSlot.names[i]));
            if (stack.item != NO_ITEM)
            {
                gui::same_line();
                ItemInfo* info = &g_items.items[stack.item];
                String count = stack.count > 1 ? string::tformat(" x%d", stack.count) : "";
                if (gui::button(string::tformat("%s%s", info.name, count)))
                {
                    inv_minimenu_target = i;
                    minimenu_height = sidebar_window.cursor.y;
                    gui::open_popup("Equipped Menu");
                }
            }
        }
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
    }

    if (sidebar_tab == INVENTORY)
    {
        gui::text("");
        for (int i = 0; i < pl.inventory.len; ++i)
        {
            ItemStack* stack = &pl.inventory[i];
            if (stack.item != NO_ITEM)
            {
                ItemInfo* info = &g_items.items[stack.item];
                String count = stack.count > 1 ? string::tformat(" x%d", stack.count) : "";
                if (gui::button(string::tformat("%s%s", info.name, count)))
                {
                    inv_minimenu_target = i;
                    minimenu_height = sidebar_window.cursor.y;
                    gui::open_popup("Item Menu");
                }
            }
            else
            {
                gui::text("");
            }
        }
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

    }

    gui::end_window();

    if (can_get_input)
    {
        if (is_key_pressed(SPAWN_ITEM, false))
        {
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


    ZoneCell* cell = g_zone.get_cell(...grab_target);
    popup_size = {60, 5 + (int) cell.dropped_items.len()};
    if (gui::begin_popup("Grab Item", {term_width / 3 - popup_size.x / 2, term_height / 2 - popup_size.y / 2}, popup_size))
    {
        gui::text("Grab Item");
        gui::same_line(5);
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
