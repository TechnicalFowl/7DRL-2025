module dg;

import std::math;

enum SidebarTab
{
    INVENTORY,
    EQUIPMENT,
    SPELLBOOK,
    SKILLS,
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

    IVec2 spos = {map_width, log_height};
    IVec2 ssize = {sidebar_width, term_height - log_height};
    gui::begin_window("Inv", spos, ssize, border: false);

    ui_term.box_tile(...spos, ...ssize, false, colors::GREY, 10);

    gui::end_window();
}
