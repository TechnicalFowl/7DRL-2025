module dg;

import std::collections::list;
import std::collections::map;
import std::io;
import std::math;

import raylib5::rl;

struct VCellLayer
{
    char glyph;
    rl::Color fg;
    int fg_priority;
    Font* override;
}

struct VCell
{
    VCellLayer[2] layers;
    rl::Color bg;
    int bg_priority;
}

struct VirtualTerminal
{
    uint width;
    uint height;

    VCell* buffer;

    Font* font;
}

<*
@require w > 0, h > 0: "Width and height must be greater than zero"
*>
fn void VirtualTerminal.new_init(&self, int w, int h, Font* font)
{
    self.width = w;
    self.height = h;
    self.buffer = mem::new_array(VCell, (usz) w * h);

    self.font = font;

    self.clear();
}

fn void VirtualTerminal.free(&self)
{
    mem::free(self.buffer);
}

fn void VirtualTerminal.on_resize(&self, int new_term_width, int new_term_height) @dynamic
{
    mem::free(self.buffer);
    self.buffer = mem::new_array(VCell, (usz) new_term_width * new_term_height);
    self.width = new_term_width;
    self.height = new_term_height;
}

fn void VirtualTerminal.clear(&self, rl::Color bg=colors::BLACK)
{
    self.clear_to({ {}, bg, 0 });
}

fn void VirtualTerminal.clear_to(&self, VCell glyph)
{
    for (int i = 0; i < self.width * self.height; i++)
    {
        self.buffer[i] = glyph;
    }
}

<*
@require x >= 0 && x <= self.width
@require y >= 0 && y <= self.height
*>
fn void VirtualTerminal.set_background(&self, int x, int y, rl::Color bg, int priority=0)
{
    VCell* cell = &self.buffer[self.width * y + x];
    if (priority >= cell.bg_priority)
    {
        cell.bg = bg;
        cell.bg_priority = priority;
    }
    if (priority > cell.layers[1].fg_priority)
    {
        cell.layers = {};
    }
}

<*
@require x0 >= 0 && x0 + w <= self.width
@require y0 >= 0 && y0 + h <= self.height
@require w > 0
@require h > 0
*>
fn void VirtualTerminal.fill_background(&self, int x0, int y0, int w, int h, rl::Color bg, int priority=0)
{
    for (int y = y0; y < y0 + h; y++)
    {
        for (int x = x0; x < x0 + w; x++)
        {
            VCell* cell = &self.buffer[self.width * y + x];
            if (priority >= cell.bg_priority)
            {
                cell.bg = bg;
                cell.bg_priority = priority;
            }
            if (priority > cell.layers[1].fg_priority)
            {
                cell.layers = {};
            }
        }
    }
}

fn void VirtualTerminal.box_background(&self, int x0, int y0, int w, int h, rl::Color bg, int priority=0)
{
    int x_min = math::max(0, x0);
    int y_min = math::max(0, y0);
    int x_max = math::min(self.width - 1, x0 + w - 1);
    int y_max = math::min(self.height - 1, y0 + h - 1);

    for (int x = x_min; x <= x_max; x++)
    {
        self.set_background(x, y_min, bg, priority);
        self.set_background(x, y_max, bg, priority);
    }

    for (int y = y_min + 1; y < y_max; y++)
    {
        self.set_background(x_min, y, bg, priority);
        self.set_background(x_max, y, bg, priority);
        self.set_background(x_min + 1, y, bg, priority);
        self.set_background(x_max - 1, y, bg, priority);
    }
}

fn void VirtualTerminal.set_tile(&self, int x, int y, char glyph, rl::Color fg=colors::WHITE, int priority=0, Font* override_font=null)
{
    if (x < 0 || x >= self.width || y < 0 || y >= self.height) return;
    VCell* cell = &self.buffer[self.width * y + x];
    if (priority >= cell.bg_priority)
    {
        VCellLayer* l = &cell.layers[1];
        if (priority > l.fg_priority)
        {
            cell.layers[0] = cell.layers[1];
            l.glyph = glyph;
            l.fg = fg;
            l.fg_priority = priority;
            l.override = override_font;
        }
        else if (priority == l.fg_priority)
        {
            l.glyph = glyph;
            l.fg = fg;
            l.fg_priority = priority;
            l.override = override_font;
        }
        else if (priority >= cell.layers[0].fg_priority)
        {
            l = &cell.layers[0];
            l.glyph = glyph;
            l.fg = fg;
            l.fg_priority = priority;
            l.override = override_font;
        }
    }
}

<*
@require x0 >= 0 && x0 + w <= self.width
@require y0 >= 0 && y0 + h <= self.height
@require w > 0
@require h > 0
*>
fn void VirtualTerminal.fill_tile(&self, int x0, int y0, int w, int h, char glyph, rl::Color fg=colors::WHITE, int priority=0, Font* override_font=null)
{
    for (int y = y0; y < y0 + h; y++)
    {
        for (int x = x0; x < x0 + w; x++)
        {
            self.set_tile(x, y, glyph, fg, priority, override_font);
        }
    }
}

<*
@require x0 >= 0 && x0 + w <= self.width
@require y0 >= 0 && y0 + h <= self.height
@require w > 0
@require h > 0
*>
fn void VirtualTerminal.box_tile(&self, int x0, int y0, int w, int h, bool double_lines=false, rl::Color fg=colors::WHITE, int priority=0, Font* override_font=null)
{
    int x_min = math::max(0, x0);
    int y_min = math::max(0, y0);
    int x_max = math::min(self.width - 1, x0 + w - 1);
    int y_max = math::min(self.height - 1, y0 + h - 1);

    for (int x = x_min + 1; x < x_max; x++)
    {
        if (!double_lines)
        {
            self.set_tile(x, y_min, 196, fg, priority, override_font);
            self.set_tile(x, y_max, 196, fg, priority, override_font);
        }
        else
        {
            self.set_tile(x, y_min, 205, fg, priority, override_font);
            self.set_tile(x, y_max, 205, fg, priority, override_font);
        }
    }

    for (int y = y_min + 1; y < y_max; y++)
    {
        if (!double_lines)
        {
            self.set_tile(x_min, y, 179, fg, priority, override_font);
            self.set_tile(x_max, y, 179, fg, priority, override_font);
        }
        else
        {
            self.set_tile(x_min, y, 186, fg, priority, override_font);
            self.set_tile(x_max, y, 186, fg, priority, override_font);
        }
    }

    if (!double_lines)
    {
        self.set_tile(x_min, y_min, 218, fg, priority, override_font);
        self.set_tile(x_max, y_min, 191, fg, priority, override_font);
        self.set_tile(x_min, y_max, 192, fg, priority, override_font);
        self.set_tile(x_max, y_max, 217, fg, priority, override_font);
    }
    else
    {
        self.set_tile(x_min, y_min, 201, fg, priority, override_font);
        self.set_tile(x_max, y_min, 187, fg, priority, override_font);
        self.set_tile(x_min, y_max, 200, fg, priority, override_font);
        self.set_tile(x_max, y_max, 188, fg, priority, override_font);
    }
}

<*
@require x >= 0 && x <= self.width * 2
@require y >= 0 && y <= self.height
*>
fn void VirtualTerminal.write(&self, int x, int y, String text, rl::Color fg=colors::WHITE, int priority=0, Font* override_font=null)
{
    foreach (c: text)
    {
        self.set_tile(x++, y, c, fg, priority, override_font);
    }
}

fn void VirtualTerminal.write_centered(&self, int x, int y, String text, rl::Color fg=colors::WHITE, int priority=0, Font* override_font=null)
{
    x -= text.len / 2;
    foreach (c: text)
    {
        self.set_tile(x++, y, c, fg, priority, override_font);
    }
}

fn void VirtualTerminal.drawTile(&self, Vec2f p, Vec2f offs, char c, rl::Color col, float zoom, Font* font) @private
{
    rl::Rectangle src = {
        (float) (c % 16) * font.width, (float) (c / 16) * font.height,
        font.width, font.height
    };
    rl::Rectangle dest = {
        p.x * self.font.width * zoom + offs.x, p.y * self.font.height * zoom + offs.y,
        font.width * zoom, font.height * zoom
    };

    rl::drawTexturePro(font.texture, src, dest, { 0, 0 }, 0, col);
}

fn void VirtualTerminal.render(&self, float zoom, Vec2f offset={0, 0})
{
    rl::beginBlendMode(0);
    for (int y = 0; y < self.height; y++)
    {
        for (int x = 0; x < self.width; x++)
        {
            VCell* cell = &self.buffer[self.width * y + x];
            rl::Rectangle dest = {
                (float) x * self.font.width * zoom + offset.x, (float) y * self.font.height * zoom + offset.y,
                self.font.width * zoom, self.font.height * zoom
            };
            if (cell.bg.a > 0) rl::drawRectangleRec(dest, cell.bg);
        }
    }
    rl::beginBlendMode(0);
    for (int y = 0; y < self.height; y++)
    {
        for (int x = 0; x < self.width; x++)
        {
            VCell* cell = &self.buffer[self.width * y + x];
            rl::Rectangle dest = {
                (float) x * self.font.width * zoom + offset.x, (float) y * self.font.height * zoom + offset.y,
                self.font.width * zoom, self.font.height * zoom
            };
            for (int i = 0; i < 2; i++)
            {
                VCellLayer* layer = &cell.layers[i];
                if (layer.fg.a == 0) continue;
                self.drawTile({x, y}, offset, layer.glyph, layer.fg, zoom, layer.override ? layer.override : self.font);
            }
        }
    }
    rl::endBlendMode();
}