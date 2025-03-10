module dg;

import std::collections::list;
import std::collections::map;
import std::collections::priorityqueue;
import std::io;
import std::math;
import raylib5::rl;

struct TerrainInfo
{
    String name;
    bool passable;
    Appearance look;
    rl::Color bg;
    String description;
}

enum TerrainType : inline int (TerrainInfo info)
{
    EMPTY_VOID = { "Empty", false, EMPTY_LOOK, colors::BLACK, "an empty void" },

    TERR_WALL_NORTH = { "Wall", false, WALL_NORTH, colors::BLACK, "a solid wall" },
    TERR_WALL_EAST = { "Wall", false, WALL_EAST, colors::BLACK, "a solid wall" },
    TERR_WALL_SOUTH = { "Wall", false, WALL_SOUTH, colors::BLACK, "a solid wall" },
    TERR_WALL_WEST = { "Wall", false, WALL_WEST, colors::BLACK, "a solid wall" },
    TERR_WALL_NE = { "Wall", false, WALL_NE, colors::BLACK, "a solid wall" },
    TERR_WALL_NW = { "Wall", false, WALL_NW, colors::BLACK, "a solid wall" },
    TERR_WALL_SE = { "Wall", false, WALL_SE, colors::BLACK, "a solid wall" },
    TERR_WALL_SW = { "Wall", false, WALL_SW, colors::BLACK, "a solid wall" },
    TERR_PILLAR = { "Pillar", false, PILLAR, colors::BLACK, "a solid wall" },

    TERR_GRASS = { "Grass", true, FLOOR_GRASS, colors::BLACK, "some tufts of grass" },
    TERR_DIRT = { "Dirt", true, FLOOR_DIRT, colors::BLACK, "some dirt" },
    TERR_STONE = { "Stone", true, FLOOR_STONE, colors::BLACK, "some stones" },
    TERR_BRICKS = { "Bricks", true, FLOOR_SLABS, colors::BLACK, "a stone floor" },
    TERR_ROUGH_STONE = { "Rough Stone", true, FLOOR_ROUGH_STONE, colors::BLACK, "some dirty stone" },
    TERR_CLEAN_STONE = { "Clean Stone", true, FLOOR_CLEAN_STONE, colors::BLACK, "some bare stone" },

    TERR_DOOR_NORTH_L = { "Door", false, DOOR_NORTH_L, colors::BLACK, "a sturdy door" },
    TERR_DOOR_NORTH_R = { "Door", false, DOOR_NORTH_R, colors::BLACK, "a sturdy door" },
    TERR_DOOR_EAST_U = { "Door", false, DOOR_EAST_U, colors::BLACK, "a sturdy door" },
    TERR_DOOR_EAST_L = { "Door", false, DOOR_EAST_L, colors::BLACK, "a sturdy door" },
    TERR_DOOR_SOUTH_L = { "Door", false, DOOR_SOUTH_L, colors::BLACK, "a sturdy door" },
    TERR_DOOR_SOUTH_R = { "Door", false, DOOR_SOUTH_R, colors::BLACK, "a sturdy door" },
    TERR_DOOR_WEST_U = { "Door", false, DOOR_WEST_U, colors::BLACK, "a sturdy door" },
    TERR_DOOR_WEST_L = { "Door", false, DOOR_WEST_L, colors::BLACK, "a sturdy door" },

    TERR_ODOOR_NORTH_L = { "Open Door", false, DOOR_OPEN_NORTH_L, colors::BLACK, "a sturdy door, you remember going through it before" },
    TERR_ODOOR_NORTH_R = { "Open Door", false, DOOR_OPEN_NORTH_R, colors::BLACK, "a sturdy door, you remember going through it before" },
    TERR_ODOOR_EAST_U = { "Open Door", false, DOOR_OPEN_EAST_U, colors::BLACK, "a sturdy door, you remember going through it before" },
    TERR_ODOOR_EAST_L = { "Open Door", false, DOOR_OPEN_EAST_L, colors::BLACK, "a sturdy door, you remember going through it before" },
    TERR_ODOOR_SOUTH_L = { "Open Door", false, DOOR_OPEN_SOUTH_L, colors::BLACK, "a sturdy door, you remember going through it before" },
    TERR_ODOOR_SOUTH_R = { "Open Door", false, DOOR_OPEN_SOUTH_R, colors::BLACK, "a sturdy door, you remember going through it before" },
    TERR_ODOOR_WEST_U = { "Open Door", false, DOOR_OPEN_WEST_U, colors::BLACK, "a sturdy door, you remember going through it before" },
    TERR_ODOOR_WEST_L = { "Open Door", false, DOOR_OPEN_WEST_L, colors::BLACK, "a sturdy door, you remember going through it before" },

    TERR_LDOOR_NORTH_L = { "Locked Door", false, DOOR_LOCKED_NORTH_L, colors::BLACK, "a sturdy door with a big lock on it" },
    TERR_LDOOR_NORTH_R = { "Locked Door", false, DOOR_LOCKED_NORTH_R, colors::BLACK, "a sturdy door with a big lock on it" },
    TERR_LDOOR_EAST_U = { "Locked Door", false, DOOR_LOCKED_EAST_U, colors::BLACK, "a sturdy door with a big lock on it" },
    TERR_LDOOR_EAST_L = { "Locked Door", false, DOOR_LOCKED_EAST_L, colors::BLACK, "a sturdy door with a big lock on it" },
    TERR_LDOOR_SOUTH_L = { "Locked Door", false, DOOR_LOCKED_SOUTH_L, colors::BLACK, "a sturdy door with a big lock on it" },
    TERR_LDOOR_SOUTH_R = { "Locked Door", false, DOOR_LOCKED_SOUTH_R, colors::BLACK, "a sturdy door with a big lock on it" },
    TERR_LDOOR_WEST_U = { "Locked Door", false, DOOR_LOCKED_WEST_U, colors::BLACK, "a sturdy door with a big lock on it" },
    TERR_LDOOR_WEST_L = { "Locked Door", false, DOOR_LOCKED_WEST_L, colors::BLACK, "a sturdy door with a big lock on it" },

    TERR_BDOOR_NORTH_L = { "Boss Door", false, DOOR_BOSS_NORTH_L, colors::BLACK, "a sturdy door, you sense some danger lurks beyond it" },
    TERR_BDOOR_NORTH_R = { "Boss Door", false, DOOR_BOSS_NORTH_R, colors::BLACK, "a sturdy door, you sense some danger lurks beyond it" },
    TERR_BDOOR_EAST_U = { "Boss Door", false, DOOR_BOSS_EAST_U, colors::BLACK, "a sturdy door, you sense some danger lurks beyond it" },
    TERR_BDOOR_EAST_L = { "Boss Door", false, DOOR_BOSS_EAST_L, colors::BLACK, "a sturdy door, you sense some danger lurks beyond it" },
    TERR_BDOOR_SOUTH_L = { "Boss Door", false, DOOR_BOSS_SOUTH_L, colors::BLACK, "a sturdy door, you sense some danger lurks beyond it" },
    TERR_BDOOR_SOUTH_R = { "Boss Door", false, DOOR_BOSS_SOUTH_R, colors::BLACK, "a sturdy door, you sense some danger lurks beyond it" },
    TERR_BDOOR_WEST_U = { "Boss Door", false, DOOR_BOSS_WEST_U, colors::BLACK, "a sturdy door, you sense some danger lurks beyond it" },
    TERR_BDOOR_WEST_L = { "Boss Door", false, DOOR_BOSS_WEST_L, colors::BLACK, "a sturdy door, you sense some danger lurks beyond it" },

    TERR_EXIT_WALL_L = { "Wall", false, EXIT_WALL_L, colors::BLACK, "a wall marked with a downward arrow" },
    TERR_EXIT_WALL_R = { "Wall", false, EXIT_WALL_R, colors::BLACK, "a wall marked with a downward arrow" },
    TERR_EXIT_HOLE_L = { "Exit", false, EXIT_HOLE_L, colors::BLACK, "a dark pit leading deeper into the dungeon" },
    TERR_EXIT_HOLE_R = { "Exit", false, EXIT_HOLE_R, colors::BLACK, "a dark pit leading deeper into the dungeon" },

    TERR_RUNIC_CIRCLE_NW = { "Runic Circle", true, RUNIC_CIRCLE_NW, colors::BLACK, "a runic circle" },
    TERR_RUNIC_CIRCLE_NE = { "Runic Circle", true, RUNIC_CIRCLE_NE, colors::BLACK, "a runic circle" },
    TERR_RUNIC_CIRCLE_SW = { "Runic Circle", true, RUNIC_CIRCLE_SW, colors::BLACK, "a runic circle" },
    TERR_RUNIC_CIRCLE_SE = { "Runic Circle", true, RUNIC_CIRCLE_SE, colors::BLACK, "a runic circle" },
}

fn bool is_wall_terrain(TerrainType t) => t >= TERR_WALL_NORTH && t <= TERR_PILLAR;
fn bool is_door_terrain(TerrainType t) => t >= TERR_DOOR_NORTH_L && t <= TERR_BDOOR_WEST_L;
fn bool is_locked_door_terrain(TerrainType t) => t >= TERR_LDOOR_NORTH_L && t <= TERR_LDOOR_WEST_L;
fn bool is_exit_terrain(TerrainType t) => t >= TERR_EXIT_WALL_L && t <= TERR_EXIT_HOLE_R;

struct ObjectInfo
{
    String name;
    bool passable;
    Appearance look;
    String description;
}

enum ObjectType : inline int (ObjectInfo info)
{
    OBJ_EMPTY = { "Empty", true, EMPTY_LOOK, "" },
    OBJ_SMALL_ROCKS = { "Small Rocks", false, SMALL_ROCKS, "a small scattering of rocks" },
    OBJ_ROCKS = { "Rocks", false, ROCKS, "a large boulder" },
    OBJ_TREE = { "Tree", false, TREE, "a short tree" },
    OBJ_STUMP = { "Stump", false, STUMP, "an old stump" },
    OBJ_CRATE = { "Crate", false, CRATE, "a supply crate" },
    OBJ_OPEN_CRATE = { "Open Crate", false, OPEN_CRATE, "an empty supply crate" },
    OBJ_SMALL_BOXES = { "Small Boxes", false, SMALL_BOXES, "some small empty boxes" },
    OBJ_ANVIL = { "Anvil", false, ANVIL, "an anvil" },
    OBJ_FURNACE = { "Furnace", false, FURNACE, "a hot furnace" },
    OBJ_CAMPFIRE = { "Campfire", false, CAMPFIRE, "a small campfire" },
    OBJ_FIRE_PIT = { "Fire Pit", false, FIRE_PIT, "the remnants of a fire" },
    OBJ_TORCH = { "Torch", false, TORCH, "a lit torch" },
    OBJ_GRAVE = { "Grave", false, GRAVE, "a gravestone" },
    OBJ_GRAVE2 = { "Grave", false, GRAVE2, "a gravestone" },
    OBJ_ORE_ROCK1 = { "Ore Rock", false, ORE_ROCK1, "a small boulder containing some novite ore" },
    OBJ_ORE_ROCK2 = { "Ore Rock", false, ORE_ROCK2, "a small boulder containing some fractite ore" },
    OBJ_ORE_ROCK3 = { "Ore Rock", false, ORE_ROCK3, "a small boulder containing some promethium ore"},
    OBJ_TRADER = { "Trader", false, TRADER, "a trader with some wares available" },
    OBJ_RUNE_ALTAR_L = { "Rune Altar", false, RUNE_ALTAR_L, "a rune altar" },
    OBJ_RUNE_ALTAR_R = { "Rune Altar", false, RUNE_ALTAR_R, "a rune altar" },
    OBJ_RUNE_ALTAR_PLINTH = { "Rune Altar", false, RUNE_ALTAR_PLINTH, "a decorative plinth" },
    OBJ_CHEST = { "Gilded Chest", false, CHEST, "a gilded chest" },
    OBJ_OPEN_CHEST = { "Gilded Chest", false, OPEN_CHEST, "an empty gilded chest" },
}

fault ZoneFault
{
    OUT_OF_BOUNDS,
}

struct ZoneCell
{
    TerrainType terrain;
    ObjectType object;
    List(<ItemStack>) dropped_items;
    List(<Entity>) entities;
}

fn bool ZoneCell.isPassable(&self) => self.terrain.info.passable && self.object.info.passable && self.entities.is_empty();
fn bool ZoneCell.isTerrainPassable(&self) => self.terrain.info.passable;

struct Zone
{
    String name;
    int width;
    int height;
    ZoneCell* cells;

    Entity player;
    List(<Entity>) all_entities;

    IVec2 last_render_min;

    IVec2 last_mouse_pos;
    double mouse_hover_time;
}

fn void Zone.new_init(&self, ZoneDescription desc)
{
    self.name = desc.name;
    self.width = desc.width;
    self.height = desc.height;
    self.cells = mem::new_array(ZoneCell, (usz) self.width * self.height);

    for (int i = 0; i < self.width * self.height; ++i)
    {
        ZoneCell* cell = &self.cells[i];
        cell.terrain = EMPTY_VOID;
        cell.object = OBJ_EMPTY;
        cell.dropped_items.new_init();
        cell.entities.new_init();
    }

    @pool()
    {
        desc.generator(desc.generator_data, self);
    };

    assert(self.player != null, "No player provided");

    @call_event(PostLoadEvent, on_post_load, self.player);
    foreach (ent: self.all_entities)
    {
        @call_event(PostLoadEvent, on_post_load, ent);
    }
}

fn void Zone.free(&self)
{
    for (int i = 0; i < self.width * self.height; ++i)
    {
        self.cells[i].dropped_items.free();
        self.cells[i].entities.free();
    }
    mem::free(self.cells);

    foreach (ent: self.all_entities)
    {
        ent.free();
    }
    self.all_entities.free();
}

struct EntityAction
{
    Entity entity;
    Action next_action;
    double duration;
    double remaining_time;
}
fn bool EntityAction.less(EntityAction* a, EntityAction* b) => a.duration < b.duration;

fn EntityAction* make_entity_action(Entity e, Action act, double duration, double remaining)
{
    EntityAction* ea = mem::temp_alloc(EntityAction);
    ea.entity = e;
    ea.next_action = act;
    ea.duration = duration;
    ea.remaining_time = remaining;
    return ea;
}

fn double Zone.update(&self)
{
    @pool()
    {
        Action player_action = self.player.next_action(100000);
        if (player_action == null) return 0.0;

        double max_time = player_action.duration();
        PriorityQueue(<EntityAction*>) actions;
        actions.new_init(math::max(self.all_entities.len() + 1u64, 16u64), allocator::temp());
        actions.push(make_entity_action(self.player, player_action, max_time, 0));

        foreach (ent: self.all_entities)
        {
            Action a = ent.next_action(max_time + ent.get_idle_time());
            if (a == null) continue;
            double ad = a.duration();
            actions.push(make_entity_action(ent, a, ad, max_time - ad));
        }

        while (!actions.is_empty())
        {
            EntityAction* next = actions.pop()!!;
            if (next.entity.is_dead()) continue;
            next.next_action.apply(next.entity);
            if (next.remaining_time > 0)
            {
                Action continuation = next.entity.next_action(next.remaining_time);
                if (continuation == null) continue;
                double cont_duraction = continuation.duration();
                actions.push(make_entity_action(next.entity, continuation, next.duration + cont_duraction, next.remaining_time - cont_duraction));
            }
        }

        if (self.player.is_dead())
        {
            log("Oh dear you are dead.");
            return max_time;
        }

        bool stat_tick = ((int) elapsed_time / 10) != ((int) (elapsed_time + max_time) / 10);
        if (stat_tick)
        {
            ((Player*) self.player).updateBoostedStats();
        }
        self.player.onUpdate(max_time);

        for (int i = (int) self.all_entities.len() - 1; i >= 0; --i)
        {
            Entity e = self.all_entities[i];
            if (e.is_dead())
            {

                int count = random::next_in_range(&g_rng, 1, 4);
                DropTable* table = &crate_loot[current_floor.depth];

                for (int j = 0; j < count; ++j)
                {
                    ItemStack item = table.roll(&g_rng);
                    self.drop_item(...e.get_position(), item);
                }

                ZoneCell* cell = self.get_cell(...e.get_position())!!;
                cell.entities.remove_item(e);
                self.all_entities.remove_at(i);
                e.free();
                mem::free(e);
            }
            else
            {
                if (stat_tick && e.type == Monster.typeid)
                {
                    ((Monster*) e).updateBoostedStats();
                }
                e.onUpdate(max_time);
            }
        }

        return max_time;
    };
}

fn ZoneCell*! Zone.get_cell(&self, int x, int y)
{
    if (x < 0 || x >= self.width || y < 0 || y >= self.height) return ZoneFault.OUT_OF_BOUNDS?;
    return &self.cells[y * self.width + x];
}

fn void Zone.set_terrain(&self, int x, int y, TerrainType terr)
{
    ZoneCell* cell = self.get_cell(x, y)!!;
    cell.terrain = terr;
}

fn void Zone.fill_terrain(&self, IVec2 pos, IVec2 size, TerrainType terr)
{
    for (int y = pos[1]; y < pos[1] + size[1]; ++y)
    {
        for (int x = pos[0]; x < pos[0] + size[0]; ++x)
        {
            self.set_terrain(x, y, terr);
        }
    }
}

fn void Zone.set_object(&self, int x, int y, ObjectType obj)
{
    ZoneCell* cell = self.get_cell(x, y)!!;
    cell.object = obj;
}

fn void Zone.drop_item(&self, int x, int y, ItemStack item)
{
    assert(item.item != NO_ITEM);
    ZoneCell* cell = self.get_cell(x, y)!!;
    ItemInfo* info = &g_items.items[item.item];
    foreach (&i: cell.dropped_items)
    {
        if (i.item == item.item)
        {
            i.count += item.count;
            if (i.count > info.stack_size)
            {
                item.count = i.count - info.stack_size;
                i.count = info.stack_size;
            }
            else
            {
                return;
            }
        }
    }
    assert(item.count > 0);
    cell.dropped_items.push(item);
}

fn void Zone.add_player(&self, Entity e)
{
    self.player = e;
    ZoneCell* cell = self.get_cell(...e.get_position())!!;
    cell.entities.push(e);
}

fn void Zone.add_entity(&self, Entity e)
{
    self.all_entities.push(e);
    ZoneCell* cell = self.get_cell(...e.get_position())!!;
    cell.entities.push(e);
}

fn IVec2 Zone.get_player_position(&self)
{
    assert(self.player != null, "No player in zone");
    return self.player.get_position();
}

fn IVec2 Zone.get_mouse_position(&self)
{
    int x = self.last_render_min[0] + rl::getMouseX() / (font_size * map_zoom);
    int y = self.last_render_min[1] + (rl::getMouseY() - 16) / (font_size * map_zoom);
    return {x, y};
}

fn IVec2 Zone.find_nearest_empty(&self, IVec2 pos)
{
    int x = 0;
    int y = 0;
    int dx = 0;
    int dy = -1;
    const int RANGE = 10;
    for (int i = 0; i < RANGE * RANGE * 4; ++i)
    {
        ZoneCell*! cell = self.get_cell(pos[0] + x, pos[1] + y);
        if (try cell && cell.isPassable()) return pos;
        if  (x == y || ((x < 0) && (x == -y)) || ((x > 0) && (x == 1 - y)))
        {
            int t = dx;
            dx = -dy;
            dy = t;
        }
        x += dx;
        y += dy;
    }
    return pos;
}

struct ZoneVisCB
{
    Zone* zone;
    bool visible;
}

fn bool ZoneVisCB.line_cb(&self, IVec2 pos) @private
{
    ZoneCell*! cell = self.zone.get_cell(...pos);
    if (!cell.isPassable() ?? true)
    {
        self.visible = false;
        return false;
    }
    return true;
}

fn bool Zone.can_see(&self, IVec2 from, IVec2 to)
{
    ZoneVisCB cb_data = { self, true };
    line(from, to, (LineCallback) &ZoneVisCB.line_cb, &cb_data);
    return cb_data.visible;
}

struct ZoneRenderSettings
{
    IVec2 offset;
}

fn void Zone.render(&self, VirtualTerminal* terminal, VirtualTerminal* ui, ZoneRenderSettings settings)
{
    IVec2 hsize = {terminal.width / 2, terminal.height / 2};
    IVec2 focus = hsize;
    if (self.player) focus = self.get_player_position();
    focus += settings.offset;

    IVec2 min = focus - hsize;
    IVec2 max = focus + hsize;

    self.last_render_min = min;

    if (textmode)
    {
        terminal.font = textmode_font;
    }
    else
    {
        terminal.font = sprite_font;
    }

    VisibilityTracker* vis = null;
    EntityVisibility ev = (EntityVisibility) self.player;
    if (&ev.get_visibility)
    {
        vis = ev.get_visibility();
    }

    for (int y = min[1]; y < max[1]; ++y)
    {
        if (y < 0 || y >= self.height) continue;
        int term_y = y - min.y;
        for (int x = min.x; x < max.x; ++x)
        {
            if (x < 0 || x >= self.width) continue;
            if (vis != null && !vis.is_explored({x, y})) continue;
            int term_x = x - min.x;
            ZoneCell* cell = &self.cells[x + y * self.width];
            bool is_visible = true;// vis == null || vis.is_visible({x, y});
            //terminal.set_background(term_x, term_y, is_visible ? terr.bg : terr.bg.grayscale().darken(0.4f));
            if (cell.terrain != EMPTY_VOID)
            {
                TerrainInfo terr = cell.terrain.info;
                Appearance look = terr.look;
                bool is_textmode = textmode || look.sprite_index < 0;
                char gl = is_textmode ? look.glyph : (char) look.sprite_index;
                rl::Color color = is_textmode ? look.color : colors::WHITE;
                if (!is_visible)
                {
                    color = color.grayscale().darken(0.4f);
                }
                terminal.set_tile(term_x, term_y, gl, color, 0, is_textmode ? textmode_font : null);
            }
            if (cell.object != OBJ_EMPTY)
            {
                ObjectInfo obj = cell.object.info;
                Appearance look = obj.look;
                bool is_textmode = textmode || look.sprite_index < 0;
                char gl = is_textmode ? look.glyph : (char) look.sprite_index;
                rl::Color color = is_textmode ? look.color : colors::WHITE;
                if (!is_visible)
                {
                    color = color.grayscale().darken(0.4f);
                }
                terminal.set_tile(term_x, term_y, gl, color, textmode ? 0 : 1, is_textmode ? textmode_font : null);
            }
            else if (is_visible && !cell.entities.is_empty())
            {
                Entity first = cell.entities.first()!!;
                if (!first.is_dead())
                {
                    Appearance look = first.get_look();
                    bool is_textmode = textmode || look.sprite_index < 0;
                    char gl = is_textmode ? look.glyph : (char) look.sprite_index;
                    rl::Color color = is_textmode ? look.color : colors::WHITE;
                    terminal.set_tile(term_x, term_y, gl, color, textmode ? 0 : 1, is_textmode ? textmode_font : null);
                    
                    if (first.type == Monster.typeid)
                    {
                        Monster* mob = (Monster*) first;
                        if (mob.type >= MonsterType.GOBLIN_MAGE_BOSS)
                        {
                            if (!is_textmode)
                            {
                                terminal.set_tile(term_x, term_y - 1, CROWN.sprite_index, colors::WHITE, 2, null);
                            }
                        }

                        Attunement a = mob.attunement;
                        if (a != NONE)
                        {
                            Item rune = (Item) (a.ordinal + Item.BLANK_RUNE);
                            Appearance alook = g_items.items[rune].look;
                            bool ais_textmode = textmode || alook.sprite_index < 0;
                            IVec2 ui_pos = IVec2 { term_x * 2 * map_zoom + map_zoom * 2 - 1, term_y * map_zoom + 1};
                            char agl = is_textmode ? alook.glyph : (char) alook.sprite_index;
                            rl::Color acolor = is_textmode ? alook.color : colors::WHITE;
                            ui.set_tile(...ui_pos, agl, acolor, 0, is_textmode ? textmode_font : sprite_font);
                        }
                    }
                }
            }
            else if (is_visible && !cell.dropped_items.is_empty())
            {
                ItemStack first = cell.dropped_items.first()!!;
                ItemInfo* info = &g_items.items[first.item];
                Appearance look = info.look;
                bool is_textmode = textmode || look.sprite_index < 0;
                char gl = is_textmode ? look.glyph : (char) look.sprite_index;
                rl::Color color = is_textmode ? look.color : colors::WHITE;
                terminal.set_tile(term_x, term_y, gl, color, textmode ? 0 : 1, is_textmode ? textmode_font : null);
                
                if (cell.dropped_items.len() > 1)
                {
                    IVec2 ui_pos = IVec2 { term_x * 2 * map_zoom + map_zoom * 2 - 1, term_y * map_zoom + 1};
                    ui.set_tile(...ui_pos, '+', colors::WHITE, 0);
                }
            }
        }
    }

    if (current_floor.depth == 9)
    {
        Room* boss_room = current_floor.boss_room;
        IVec2 boss_pos = boss_room.position + {7, 7};

        
    }

    {
        IVec2 mpos = self.get_mouse_position();
        if (mpos == self.last_mouse_pos)
        {
            if (!gui::want_mouse_input())
            {
                self.mouse_hover_time += rl::getFrameTime();

                if (g_settings.hover_tooltip_delay > 0 && self.mouse_hover_time > g_settings.hover_tooltip_delay)
                {
                    ZoneCell*! cell = self.get_cell(...mpos);
                    if (try cell)
                    {
                        int height = cell.object == OBJ_EMPTY ? 1 : 2;
                        height += (int) cell.entities.len();
                        if (height < 2) height = 2;
                        double time_in_hover = self.mouse_hover_time - g_settings.hover_tooltip_delay;
                        int animation_step = (int) (time_in_hover / 0.02);
                        bool left_justify = rl::getMouseX() < (ui.width - sidebar_width - 16) * 8;
                        if (left_justify)
                        {
                            IVec2 tt_pos = (mpos - min) * map_zoom;
                            tt_pos += {map_zoom + 1, 1};
                            tt_pos.x *= 2;
                            if (tt_pos.y + height > ui.height) tt_pos.y -= height;
                            // @Todo: maybe tooltips later lol
                        }
                        else
                        {

                        }
                    }
                }
            }
        }
        else
        {
            self.mouse_hover_time = 0;
            self.last_mouse_pos = self.get_mouse_position();
            if (inv_action == ACT_AIM && !gui::want_mouse_input())
            {
                inv_action_target = self.last_mouse_pos;
            }
        }
        IVec2 ui_pos = ((inv_action == ACT_AIM ? inv_action_target : mpos) - min) * map_zoom;
        ui_pos.y += 1;
        ui_pos.x *= 2;
        if (ui_pos.x >= 0 && ui_pos.y >= 0 && ui_pos.x + map_zoom * 2 < ui.width && ui_pos.y + map_zoom < ui.height)
        {
            double now = rl::getTime() / 2;
            double frac = now - (int) now;
            float t = (float) math::abs(frac - 0.5) * 0.2;
            rl::Color bg = lerp(colors::BLANK, inv_action == ACT_AIM ? colors::RED : colors::BLANK, t + 0.3);
            ui.fill_background(ui_pos.x, ui_pos.y, map_zoom * 2, map_zoom, bg);
        }
    }
}

fn double get_diag_heuristic(IVec2 a, IVec2 b)
{
    IVec2 dv = math::abs(a - b);
    return dv.sum() + (-0.58578643762) * dv.min_element();
}

fn double get_heuristic(IVec2 a, IVec2 b)
{
    return math::abs(a - b).sum();
}

struct AStarStep
{
    IVec2 pos;
    IVec2 last;
    double cost;
    double h_cost;
}

fn bool AStarStep.less(AStarStep* a, AStarStep b) => a.h_cost < b.h_cost;

const IVec2[4] DIRECT_NEIGHBORS = { {0, -1}, {0, 1}, {-1, 0}, {1, 0} };
const IVec2[4] DIAGONAL_NEIGHBORS = { {-1, -1}, {1, -1}, {-1, 1}, {1, 1} };

<*
@param [&in] results
@require from[0] >= 0, from[0] < self.width: "From x out of bounds"
@require from[1] >= 0, from[1] < self.height: "From y out of bounds"
@require to[0] >= 0, to[0] < self.width: "To x out of bounds"
@require to[1] >= 0, to[1] < self.height: "To y out of bounds"
*>
fn bool Zone.path(&self, IVec2 from, IVec2 to, List(<IVec2>)* results, bool diagonal_moves=true, bool reverse=false)
{
    PriorityQueue(<AStarStep>) frontier;
    frontier.temp_init(16);
    HashMap(<IVec2, AStarStep>) came_from;
    came_from.temp_init(16);

    frontier.push({from, from, 0, 0});
    came_from.set(from, {from, from, 0, 0});

    const DEBUG_PATHFINDING = false;

    if (DEBUG_PATHFINDING) io::printfn("Pathfinding from [%d %d] to [%d %d]", ...from, ...to);

    while (!frontier.is_empty())
    {
        AStarStep current = frontier.pop()!!;
        if (DEBUG_PATHFINDING) io::printfn("Popped [%d %d] with cost %.1f", ...current.pos, current.cost);
        if (current.pos == to) break;
        
        foreach (n: DIRECT_NEIGHBORS)
        {
            AStarStep save_current = current;
            IVec2 next = current.pos + n;
            if (DEBUG_PATHFINDING) io::printfn("  Checking [%d %d] -> [%d %d]", ...current.pos, ...next);
            if (next[0] < 0 || next[0] >= self.width || next[1] < 0 || next[1] >= self.height) continue;
            ZoneCell*! cell = self.get_cell(...next);
            if (catch cell)
            {
                if (DEBUG_PATHFINDING) io::printfn("    Skipped [%d %d] because it's out of bounds", ...next);
                current = save_current;
                continue;
            }
            if (is_door_terrain(cell.terrain) && next != to)
            {
                double new_cost = current.cost + 1;
                double h_cost = new_cost + (diagonal_moves ? get_diag_heuristic(next, to) : get_heuristic(next, to));
                AStarStep! existing = came_from.get(next);
                if (try existing && existing.cost <= new_cost)
                {
                    if (DEBUG_PATHFINDING) io::printfn("    Skipped door [%d %d] because it's already pathed with cost %.1f (new_cost was %.1f)", ...next, existing.cost, new_cost);
                    current = save_current;
                    continue;
                }
                else
                {
                    AStarStep next_step = {next, current.pos, new_cost, h_cost};
                    if (DEBUG_PATHFINDING) if (DEBUG_PATHFINDING) io::printfn("    Adding [%d %d] to door pathed from [%d %d] with cost %.1f", ...next, ...current.pos, next_step.cost);
                    //frontier.push(next_step);
                    came_from.set(next, next_step);
                    current = next_step;
                }

                Direction dir = get_door_direction(next);
                next = next + dir.dir * 3;
                ZoneCell*! tcell = self.get_cell(...next);
                if (catch tcell)
                {
                    current = save_current;
                    continue;
                }
                cell = tcell;

            }
            if (!cell.isPassable() && next != to)
            {
                if (DEBUG_PATHFINDING) io::printfn("    Skipped [%d %d] because it's impassable", ...next);
                current = save_current;
                continue;
            }
            
            double new_cost = current.cost + 1;
            double h_cost = new_cost + (diagonal_moves ? get_diag_heuristic(next, to) : get_heuristic(next, to));
            AStarStep! existing = came_from.get(next);
            if (try existing && existing.cost <= new_cost)
            {
                if (DEBUG_PATHFINDING) io::printfn("    Skipped [%d %d] because it's already pathed with cost %.1f (new_cost was %.1f)", ...next, existing.cost, new_cost);
                current = save_current;
                continue;
            }
            AStarStep next_step = {next, current.pos, new_cost, h_cost};
            if (DEBUG_PATHFINDING) io::printfn("    Adding [%d %d] to frontier pathed from [%d %d] with cost %.1f", ...next, ...current.pos, next_step.cost);
            frontier.push(next_step);
            came_from.set(next, next_step);
            current = save_current;
        }
        if (diagonal_moves)
        {
            foreach (n: DIAGONAL_NEIGHBORS)
            {
                AStarStep save_current = current;
                IVec2 next = current.pos + n;
                if (DEBUG_PATHFINDING) io::printfn("  Checking [%d %d] -> [%d %d]", ...current.pos, ...next);
                if (next[0] < 0 || next[0] >= self.width || next[1] < 0 || next[1] >= self.height) continue;
                ZoneCell*! cell = self.get_cell(...next);
                if (catch cell)
                {
                    if (DEBUG_PATHFINDING) io::printfn("    Skipped [%d %d] because it's out of bounds", ...next);
                    current = save_current;
                    continue;
                }
                if (is_door_terrain(cell.terrain) && next != to)
                {
                    double new_cost = current.cost + 1.414;
                    double h_cost = new_cost + get_diag_heuristic(next, to);
                    AStarStep! existing = came_from.get(next);
                    if (try existing && existing.cost <= new_cost)
                    {
                        if (DEBUG_PATHFINDING) io::printfn("    Skipped door [%d %d] because it's already pathed with cost %.1f (new_cost was %.1f)", ...next, existing.cost, new_cost);
                        current = save_current;
                        continue;
                    }
                    else
                    {
                        AStarStep next_step = {next, current.pos, new_cost, h_cost};
                        if (DEBUG_PATHFINDING) io::printfn("    Adding [%d %d] to door pathed from [%d %d] with cost %.1f", ...next, ...current.pos, next_step.cost);
                        //frontier.push(next_step);
                        came_from.set(next, next_step);
                        current = next_step;
                    }

                    Direction dir = get_door_direction(next);
                    next = next + dir.dir * 3;
                    ZoneCell*! tcell = self.get_cell(...next);
                    if (catch tcell)
                    {
                        current = save_current;
                        continue;
                    }
                    cell = tcell;
                }
                if (!cell.isPassable() && next != to)
                {
                    if (DEBUG_PATHFINDING) io::printfn("    Skipped [%d %d] because it's impassable", ...next);
                    current = save_current;
                    continue;
                }
                
                double new_cost = current.cost + 1.414;
                double h_cost = new_cost + get_diag_heuristic(next, to);
                AStarStep! existing = came_from.get(next);
                if (try existing && existing.cost <= new_cost)
                {
                    if (DEBUG_PATHFINDING) io::printfn("    Skipped [%d %d] because it's already pathed with cost %.1f (new_cost was %.1f)", ...next, existing.cost, new_cost);
                    current = save_current;
                    continue;
                }
                AStarStep next_step = {next, current.pos, new_cost, h_cost};
                if (DEBUG_PATHFINDING) io::printfn("    Adding [%d %d] to frontier pathed from [%d %d] with cost %.1f", ...next, ...current.pos, next_step.cost);
                frontier.push(next_step);
                came_from.set(next, next_step);
                current = save_current;
            }
        }
    }

    if (!came_from.has_key(to)) return false;

    IVec2 step_back = to;
    if (DEBUG_PATHFINDING) io::printfn("Final path from [%d %d] to [%d %d]", ...from, ...to);
    results.clear();
    while (step_back != from)
    {
        results.push(step_back);
        AStarStep! step = came_from.get(step_back);
        if (catch step) unreachable("Pathfinding error");
        if (DEBUG_PATHFINDING) io::printfn("    [%d %d] from [%d %d]", ...step_back, ...step.last);
        step_back = step.last;
    }
    if (!reverse) results.reverse();

    if (DEBUG_PATHFINDING) io::printfn("Done pathfinding, found %d steps", results.len());
    if (DEBUG_PATHFINDING) io::printn(results);
    return true;
}

def ZoneGenerator = fn void(void* data, Zone* zone);
struct ZoneDescription
{
    String name;
    int width;
    int height;

    ZoneGenerator generator;
    void* generator_data;
}

<*
@require width > 0: "Zone width must be greater than 0"
@require height > 0: "Zone height must be greater than 0"
*>
fn void ZoneDescription.new_init(&self, String name, int width, int height)
{
    self.name = name;
    self.width = width;
    self.height = height;
}

def LineCallback = fn bool(void* data, IVec2 next);
fn void line(IVec2 start, IVec2 end, LineCallback callback, void* data=null)
{
    if (start == end) return;

    IVec2 delta = math::abs(end - start);
    IVec2 step = (end - start).sign();

    int err = delta[0] - delta[1];

    do
    {
        if (2 * err > -delta[1])
        {
            err -= delta[1];
            start[0] += step[0];
        }
        else if (2 * err < delta[0])
        {
            err += delta[0];
            start[1] += step[1];
        }
    } while (callback(data, start) && start != end);
}

fn void spiral(IVec2 start, int range, LineCallback cb, void* cb_data=null)
{
    int x = 0;
    int y = 0;
    int dx = 0;
    int dy = -1;
    for (int i = 0; i < range * range * 4; ++i)
    {
        if (!cb(cb_data, start + {x, y})) break;
        if  (x == y || ((x < 0) && (x == -y)) || ((x > 0) && (x == 1 - y)))
        {
            int t = dx;
            dx = -dy;
            dy = t;
        }
        x += dx;
        y += dy;
    }
}
