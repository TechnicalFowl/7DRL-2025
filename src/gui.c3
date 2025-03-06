module dg::gui;

import std::collections::list;
import std::collections::map;
import std::io;

import raylib5::rl;

import dg::colors;

enum GuiSetting
{
    PRIORITY,
}
fn uint GuiSetting.hash(self) => self.ordinal;

enum GuiColor
{
    TOP_BAR_BG,
    TOP_BAR_TEXT,
    BOTTOM_BAR_BG,
    BOTTOM_BAR_TEXT,
    WINDOW_BG,
    WINDOW_TEXT,
    HOVERED_TEXT,
    WINDOW_BORDER,
}
fn uint GuiColor.hash(self) => self.ordinal;

fn void set_setting(GuiSetting setting, int value)
{
    gui_data.settings.set(setting, value);
}

fn int get_setting(GuiSetting setting)
{
    if (try int value = gui_data.settings.get(setting))
    {
        return value;
    }
    return 0;
}

fn void push_setting(GuiSetting setting, int value)
{
    gui_data.setting_stack.push({ setting, get_setting(setting) });
    set_setting(setting, value);
}

fn void pop_setting(int count=1)
{
    while (count-- > 0)
    {
        if (gui_data.setting_stack.is_empty()) break;
        GuiSettingStore store = gui_data.setting_stack.pop()!!;
        set_setting(store.setting, store.value);
    }
}

fn void set_color(GuiColor color, rl::Color value)
{
    gui_data.colors.set(color, value);
}

fn rl::Color get_color(GuiColor color)
{
    if (try rl::Color value = gui_data.colors.get(color))
    {
        return value;
    }
    return colors::MAGENTA;
}

fn void push_color(GuiColor color, rl::Color value)
{
    gui_data.color_stack.push({ color, get_color(color) });
    set_color(color, value);
}

fn void pop_color(int count=1)
{
    while (count-- > 0)
    {
        if (gui_data.color_stack.is_empty()) break;
        GuiColorStore store = gui_data.color_stack.pop()!!;
        set_color(store.setting, store.color);
    }
}

fn void push_topbar(String text)
{
    if (gui_data.topbar.len == 0)
    {
        gui_data.topbar = text.tcopy();
    }
    else
    {
        gui_data.topbar = string::join_new({gui_data.topbar, text}, " ", allocator::temp());
    }
}

fn void push_bottombar(String text)
{
    if (gui_data.statusbar.len == 0)
    {
        gui_data.statusbar = text.tcopy();
    }
    else
    {
        gui_data.statusbar = string::join_new({gui_data.statusbar, text}, " ", allocator::temp());
    }
}

fn GuiWindow* begin_window(String title, IVec2 pos, IVec2 size, bool border=true, int priority=0)
{
    GuiWindow* window;
    if (try GuiWindow* w = gui_data.windows.get(title))
    {
        window = w;
    }
    else
    {
        window = mem::new(GuiWindow);
        gui_data.windows.set(title, window);
    }
    window.title = title;
    window.pos = pos;
    window.size = size;
    window.flags = 0;
    if (border) window.flags |= WINDOW_FLAG_BORDER;
    window.last_frame = gui_data.frame_index;
    if (window.open_frame == 0) window.open_frame = gui_data.frame_index;
    window.cursor = {pos[0], pos[1] };
    window.last_end = window.cursor;
    window.newline_start = window.cursor[0];
    window.priority = priority;

    int prio = get_setting(GuiSetting.PRIORITY) + window.priority;
    dg::ui_term.fill_background(...pos, ...size, get_color(GuiColor.WINDOW_BG), prio);
    if (border)
    {
        dg::ui_term.box_tile(...pos, ...size, double_lines: false, fg: get_color(GuiColor.WINDOW_BORDER), priority: prio);
        dg::ui_term.fill_tile(pos.x + 5, pos.y, (int) title.len + 2, 1, ' ', colors::WHITE, prio);
        dg::ui_term.set_tile(pos.x + 4, pos.y, 180, get_color(GuiColor.WINDOW_BORDER), prio);
        dg::ui_term.write(pos.x + 6, pos.y, title, get_color(GuiColor.WINDOW_TEXT), prio);
        dg::ui_term.set_tile(pos.x + 7 + (int) title.len, pos[1], 195, get_color(GuiColor.WINDOW_BORDER), prio);
        window.cursor = window.cursor + {1, 1};
        window.newline_start++;
    }

    gui_data.window_stack.push(window);
    return window;
}

fn void same_line(int x = 1)
{
    if (gui_data.window_stack.is_empty()) unreachable("No window to write to");
    GuiWindow* window = gui_data.window_stack.last()!!;
    window.cursor = window.last_end + {x, 0};
}

fn void vertical_separator(int y)
{
    if (gui_data.window_stack.is_empty()) unreachable("No window to write to");
    GuiWindow* window = gui_data.window_stack.last()!!;
    window.cursor = { window.newline_start, window.cursor.y + y };
}

fn void icon(Appearance look)
{
    if (gui_data.window_stack.is_empty()) unreachable("No window to write to");
    GuiWindow* window = gui_data.window_stack.last()!!;
    int prio = get_setting(GuiSetting.PRIORITY) + window.priority;
    bool is_textmode = dg::textmode || look.sprite_index < 0;
    char gl = is_textmode ? look.glyph : (char) look.sprite_index;
    rl::Color color = is_textmode ? look.color : colors::WHITE;
    dg::ui_term.set_tile(...window.cursor, gl, color, prio + 1, is_textmode ? dg::textmode_font : dg::sprite_font);
    window.cursor.x += 2;
}

fn void text(String text, rl::Color color=colors::BLANK)
{
    if (color == colors::BLANK) color = get_color(GuiColor.WINDOW_TEXT);
    if (gui_data.window_stack.is_empty()) unreachable("No window to write to");
    GuiWindow* window = gui_data.window_stack.last()!!;
    IVec2 clip_size = window.get_text_clip_size();
    if (clip_size[0] <= 0 || clip_size[1] <= 0) return;
    int prio = get_setting(GuiSetting.PRIORITY) + window.priority;
    String clip_text = text.len > clip_size[0] ? text[..clip_size[0]] : text;
    dg::ui_term.write(...window.cursor, clip_text, color, prio);
    window.last_start = window.cursor;
    window.last_end = window.cursor + {clip_text.len, 0};
    window.cursor = { window.newline_start, window.cursor[1] + 1 };
}

fn bool[2] buttonBehavior(IVec2 pos, int length, rl::KeyboardKey shortcut=0, bool disabled=false)
{
    if (gui_data.window_stack.is_empty()) unreachable("No window to write to");
    GuiWindow* window = gui_data.window_stack.last()!!;
    int x = rl::getMouseX() / (dg::font_size / 2);
    int y = rl::getMouseY() / dg::font_size;
    bool hovered = x >= pos.x && x < pos.x + length && y == pos.y && !disabled;
    bool can_receive_input = !disabled && gui_data.can_receive_input(window) && window.open_frame < gui_data.frame_index - 1;
    bool pressed = hovered && can_receive_input && rl::isMouseButtonPressed(rl::MouseButton.LEFT);
    if (can_receive_input && shortcut != 0 && rl::isKeyPressed(shortcut)) pressed = true;
    return {hovered, pressed};
}

fn bool button(String next, rl::KeyboardKey shortcut=0, rl::Color color=colors::BLANK, bool disabled=false)
{
    if (color == colors::BLANK) color = get_color(GuiColor.WINDOW_TEXT);
    if (gui_data.window_stack.is_empty()) unreachable("No window to write to");
    String shortcut_name = shortcut != 0 ? string::tformat("%3s: ", dg::getKeyName(shortcut)) : "";
    String text = string::tformat("%s%s", shortcut_name, next);
    GuiWindow* window = gui_data.window_stack.last()!!;
    IVec2 clip_size = window.get_text_clip_size();
    if (clip_size[0] <= 0 || clip_size[1] <= 0) return false;
    String clip_text = text.len > clip_size[0] ? text[..clip_size[0]] : text;
    int btn_w = clip_text.len;

    int x = rl::getMouseX() / (dg::font_size / 2);
    int y = rl::getMouseY() / dg::font_size;
    bool hovered = x >= window.cursor.x && x < window.cursor.x + btn_w && y == window.cursor.y && !disabled;
    if (hovered) color = get_color(GuiColor.HOVERED_TEXT);
    if (disabled) color = colors::DARK_GREY;
    bool can_receive_input = !disabled && gui_data.can_receive_input(window) && window.open_frame < gui_data.frame_index - 1;
    bool pressed = hovered && can_receive_input && rl::isMouseButtonPressed(rl::MouseButton.LEFT);
    if (can_receive_input && shortcut != 0 && rl::isKeyPressed(shortcut)) pressed = true;

    int prio = get_setting(GuiSetting.PRIORITY) + window.priority;
    dg::ui_term.write(...window.cursor, clip_text, color, prio);
    window.last_start = window.cursor;
    window.last_end = window.cursor + {clip_text.len, 0};
    window.cursor = { window.newline_start, window.cursor[1] + 1 };

    return pressed;
}

fn void end_window()
{
    if (catch gui_data.window_stack.pop()) unreachable("No window to end");
}

fn bool is_last_item_hovered()
{
    if (gui_data.window_stack.is_empty()) return false;
    GuiWindow* window = gui_data.window_stack.last()!!;
    int x = rl::getMouseX() / (dg::font_size / 2);
    int y = rl::getMouseY() / dg::font_size;
    return x >= window.last_start.x && x < window.last_end.x && y == window.last_start.y;
}

fn bool is_popup_open(String title)
{
    foreach (w: gui_data.popup_stack)
    {
        if (w == title)
        {
            return true;
        }
    }
    return false;
}

fn void open_popup(String title)
{
    foreach (w: gui_data.popup_stack)
    {
        if (w == title)
        {
            return;
        }
    }
    gui_data.popup_stack.push(title);
}

fn bool begin_popup(String title, IVec2 pos, IVec2 size, bool border=true)
{
    bool found = false;
    foreach (w: gui_data.popup_stack)
    {
        if (w == title)
        {
            found = true;
            break;
        }
    }
    if (!found)
    {
        return false;
    }
    int prio = (int) (gui_data.popup_stack.index_of(title) ?? 0) * 2 + 1;
    GuiWindow* w = begin_window(title, pos, size, border, prio);
    w.flags |= WINDOW_FLAG_POPUP;
    return true;
}

fn void close_current_popup()
{
    GuiWindow* window = gui_data.window_stack.last()!!;
    gui_data.popup_stack.remove_item(window.title);
}

fn void end_popup()
{
    end_window();
}

fn bool want_mouse_input()
{
    int x = rl::getMouseX() / (dg::font_size / 2);
    int y = rl::getMouseY() / dg::font_size;
    return is_in_window({x, y}) || !gui_data.popup_stack.is_empty();
}

fn bool want_key_input()
{
    return !gui_data.can_receive_input(null);
}

fn bool is_in_window(IVec2 pos)
{
    if (gui_data.had_topbar && pos[1] == 0) return true;
    if (gui_data.had_statusbar && pos[1] == dg::ui_term.height - 1) return true;
    gui_data.windows.@each(; String key, GuiWindow* window)
    {
        if (window.last_frame >= gui_data.frame_index - 1 &&
            pos[0] >= window.pos[0] && pos[0] < window.pos[0] + window.size[0] && pos[1] >= window.pos[1] && pos[1] < window.pos[1] + window.size[1])
        {
            return true;
        }
    };
    return false;
}

const WINDOW_FLAG_BORDER = 1 << 0;
const WINDOW_FLAG_POPUP = 1 << 1;

struct GuiWindow
{
    String title;
    IVec2 pos;
    IVec2 size;
    uint flags;

    ulong last_frame;
    ulong open_frame;

    IVec2 cursor;
    IVec2 last_start;
    IVec2 last_end;
    int newline_start;

    int priority;
}

fn bool GuiWindow.border(&self) => (self.flags & WINDOW_FLAG_BORDER) != 0;

fn IVec2 GuiWindow.get_clip_size(&self)
{
    return {
        self.size[0] - (self.cursor[0] - self.pos[0]),
        self.size[1] - (self.cursor[1] - self.pos[1]),
    };
}

fn IVec2 GuiWindow.get_text_clip_size(&self)
{
    return {
        self.size[0] - (self.border() ? 1 : 0) - (self.cursor[0] - self.pos[0]),
        self.size[1] - (self.cursor[1] - self.pos[1]),
    };
}

struct GuiSettingStore
{
    GuiSetting setting;
    int value;
}

struct GuiColorStore
{
    GuiColor setting;
    rl::Color color;
}

struct GuiData
{
    ulong frame_index;
    List(<GuiWindow*>) window_stack;
    HashMap(<String, GuiWindow*>) windows;
    List(<String>) popup_stack;

    String topbar;
    bool had_topbar;
    String statusbar;
    bool had_statusbar;

    HashMap(<GuiColor, rl::Color>) colors;
    List(<GuiColorStore>) color_stack;
    HashMap(<GuiSetting, int>) settings;
    List(<GuiSettingStore>) setting_stack;
}
GuiData gui_data;

fn void GuiData.new_init(&self)
{
    gui_data.window_stack.new_init();
    gui_data.windows.new_init();
    gui_data.popup_stack.new_init();

    gui_data.colors.new_init();
    gui_data.color_stack.new_init();
    gui_data.settings.new_init();
    gui_data.setting_stack.new_init();

    set_setting(GuiSetting.PRIORITY, 10);

    set_color(GuiColor.TOP_BAR_BG, colors::BLACK);
    set_color(GuiColor.TOP_BAR_TEXT, { 220, 220, 220, 255});
    set_color(GuiColor.BOTTOM_BAR_BG, colors::BLACK);
    set_color(GuiColor.BOTTOM_BAR_TEXT, { 220, 220, 220, 255});
    set_color(GuiColor.WINDOW_BG, colors::BLACK);
    set_color(GuiColor.WINDOW_TEXT, { 220, 220, 220, 255});
    set_color(GuiColor.HOVERED_TEXT, colors::WHITE);
    set_color(GuiColor.WINDOW_BORDER, colors::GREY);
}

fn bool GuiData.can_receive_input(&self, GuiWindow* window)
{
    if (window && window.flags & WINDOW_FLAG_POPUP)
    {
        if (gui_data.popup_stack.is_empty()) return false;
        return gui_data.popup_stack.last()!! == window.title;
    }
    return self.popup_stack.is_empty();
}

fn void GuiData.start_frame(&self)
{
    self.frame_index++;
    self.topbar = "";
    self.statusbar = "";
    self.window_stack.clear();
}

fn void GuiData.render(&self)
{
    assert(self.window_stack.is_empty(), "Unclosed windows");
    int prio = get_setting(GuiSetting.PRIORITY);
    int term_width = dg::ui_term.width;
    int term_height = dg::ui_term.height;

    if (self.topbar.len != 0)
    {
        dg::ui_term.fill_background(0, 0, term_width, 1, get_color(GuiColor.TOP_BAR_BG), prio);
        dg::ui_term.write(1, 0, self.topbar, get_color(GuiColor.TOP_BAR_TEXT), prio);
        gui_data.had_topbar = true;
    }
    else
    {
        gui_data.had_topbar = false;
    }
    if (self.statusbar.len != 0)
    {
        dg::ui_term.fill_background(0, term_height - 1, term_width, 1, get_color(GuiColor.BOTTOM_BAR_BG), prio);
        dg::ui_term.write(1, term_height - 1, self.statusbar, get_color(GuiColor.BOTTOM_BAR_TEXT), prio);
        gui_data.had_statusbar = true;
    }
    else
    {
        gui_data.had_statusbar = false;
    }

    self.windows.@each(; String name, GuiWindow* window)
    {
        if (window.last_frame < self.frame_index - 2)
        {
            window.open_frame = 0;
        }
    };
}