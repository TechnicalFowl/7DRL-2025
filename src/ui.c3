module dg;

import std::math;

enum SidebarTab
{
    INVENTORY,
    EQUIPMENT,
    SPELLBOOK,
    SKILLS,
}

SidebarTab sidebar_tab;

fn void init_ui()
{
    sidebar_tab = INVENTORY;
}

fn void draw_ui()
{
    Player* pl = (Player*) g_zone.player;
    int sidebar_width = 54;
    int term_width = ui_term.width;
    int term_height = ui_term.height;
    int map_width = ui_term.width - sidebar_width;

    gui::push_topbar("The Depths of Daemonheim - 7DRL 2025");
    gui::push_bottombar(string::tformat("%-16s", g_zone.name));
    gui::push_bottombar(string::tformat("T:%.0f", elapsed_time));
    //gui::push_bottombar(string::tformat("Player @ %d %d", ...pl.get_position()));
    //gui::push_bottombar(string::tformat("Mouse @ %d %d", ...pl.zone.get_mouse_position()));
    //gui::push_bottombar(string::tformat("FPS: %d", rl::getFPS()));

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
    gui::begin_window("Inv", spos, ssize, border: false);

    ui_term.box_tile(...spos, ...ssize, false, colors::GREY, prio);
    ui_term.fill_tile(spos.x + 5, spos.y, 9, 1, ' ', colors::WHITE, prio);
    ui_term.set_tile(spos.x + 4, spos.y, 180, colors::GREY, prio);
    ui_term.set_tile(spos.x + 14, spos.y, 195, colors::GREY, prio);
    ui_term.write(spos.x + 6, spos.y, string::tformat("%c:Equip", getKeyIcon(get_bind(EQUIPMENT_TAB)[0])), sidebar_tab == EQUIPMENT ? { 220, 220, 220, 255 } : colors::GREY, prio);

    if (is_key_pressed(EQUIPMENT_TAB, false))
    {
        sidebar_tab = EQUIPMENT;
    }

    if (sidebar_tab == EQUIPMENT)
    {

    }

    ui_term.fill_tile(spos.x + 17, spos.y, 9, 1, ' ', colors::WHITE, prio);
    ui_term.set_tile(spos.x + 16, spos.y, 180, colors::GREY, prio);
    ui_term.set_tile(spos.x + 26, spos.y, 195, colors::GREY, prio);
    ui_term.write(spos.x + 18, spos.y, string::tformat("%c:Inven", getKeyIcon(get_bind(INVENTORY_TAB)[0])), sidebar_tab == INVENTORY ? { 220, 220, 220, 255 } : colors::GREY, prio);

    if (is_key_pressed(INVENTORY_TAB, false))
    {
        sidebar_tab = INVENTORY;
    }

    if (sidebar_tab == INVENTORY)
    {

    }

    ui_term.fill_tile(spos.x + 29, spos.y, 9, 1, ' ', colors::WHITE, prio);
    ui_term.set_tile(spos.x + 28, spos.y, 180, colors::GREY, prio);
    ui_term.set_tile(spos.x + 38, spos.y, 195, colors::GREY, prio);
    ui_term.write(spos.x + 30, spos.y, string::tformat("%c:Spell", getKeyIcon(get_bind(SPELLBOOK_TAB)[0])), sidebar_tab == SPELLBOOK ? { 220, 220, 220, 255 } : colors::GREY, prio);

    if (is_key_pressed(SPELLBOOK_TAB, false))
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

    if (is_key_pressed(SKILLS_TAB, false))
    {
        sidebar_tab = SKILLS;
    }

    if (sidebar_tab == SKILLS)
    {

    }

    gui::end_window();
}
